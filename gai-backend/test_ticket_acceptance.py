"""Tests for the ticket-acceptance trust boundary (Tier-1 #6a).

Drives TicketAcceptor.accept end-to-end with *real* signed tickets (minted via
OrchidAccount, the same path the client uses) against in-memory fakes for Redis
and the reveal source — no chain, no network, no new deps (unittest, to match the
existing suite). Covers the acceptance decision table:

  winner -> credit face | loser -> credit 0 (NOT an error) | forged/foreign-signer,
  stale/unknown commit, replay, missing funder, malformed -> rejected, no credit.

The negative cases are the point: before #6a the server credited the face value
of every ticket unconditionally.
"""

import asyncio
import secrets
import unittest

from eth_account import Account
from eth_account.messages import encode_defunct
from web3 import Web3

from account import OrchidAccount
from lottery import Lottery
from ticket_acceptance import (
    AcceptStatus, ChallengeBook, FundingCheck, TicketAcceptor, WEI, ZERO_TOKEN,
)

UINT64_MAX = (1 << 64) - 1

# Deterministic identities (throwaway keys; never touch a real wallet).
FUNDER_KEY = "0x" + "11" * 32          # self-funded: funder == signer
FUNDER = Account.from_key(FUNDER_KEY).address
RECIPIENT = Account.from_key("0x" + "33" * 32).address   # the server's wallet
STRANGER = Account.from_key("0x" + "44" * 32).address


class _FakeRedis:
    """Just the SET NX EX / GET the acceptor's double-credit ledger needs."""
    def __init__(self):
        self.kv = {}

    async def set(self, key, value, nx=False, ex=None):
        if nx and key in self.kv:
            return None
        self.kv[key] = value
        return True

    async def get(self, key):
        return self.kv.get(key)


class _FakePaymentHandler:
    """Feeds ChallengeBook deterministic (reveal, commit) pairs, mimicking the
    real handler: reveal is 0x-prefixed, commit is bare keccak hex (no 0x)."""
    def __init__(self, n=8, seed=0xA0):
        self.recipient_addr = RECIPIENT
        self._pairs = []
        for i in range(n):
            rb = bytes([(seed + i) & 0xFF]) * 32
            reveal = "0x" + rb.hex()
            commit = Web3.keccak(rb).hex()          # no 0x, like web3 7.x
            self._pairs.append((reveal, commit))
        self._i = 0

    def new_reveal(self):
        pair = self._pairs[self._i % len(self._pairs)]
        self._i += 1
        return pair


# Throwaway account that signs like the real client (no chain calls in mint).
_LOTTERY = Lottery(Web3(Web3.HTTPProvider("http://127.0.0.1:1")), chain_id=100)
_ACCT = OrchidAccount(_LOTTERY, FUNDER, FUNDER_KEY)


def _mint(*, amount, recipient, commitment, ratio, key=FUNDER_KEY):
    """Mint a signed ticket with a chosen win ratio (OrchidAccount.create_ticket
    hardcodes ratio=max, so we replicate its signing to forge winners AND losers).
    ratio=UINT64_MAX -> always wins; ratio=0 -> effectively never wins."""
    nonce = secrets.randbits(128)
    packed0 = amount | (nonce << 128)
    packed1 = (ratio << 161) | (0 << 160)
    digest = _ACCT._get_ticket_hash(ZERO_TOKEN, recipient, commitment, packed0, packed1)
    sig = _ACCT.web3.eth.account.sign_message(encode_defunct(digest), private_key=key)
    packed1 |= (sig.v - 27)
    return (hex(packed0)[2:].zfill(64) + hex(packed1)[2:].zfill(64)
            + hex(sig.r)[2:].zfill(64) + hex(sig.s)[2:].zfill(64))


def _verifier(result):
    """A fake funding_verifier: returns the given FundingCheck, or raises if given
    an exception (to exercise the acceptor's catch -> UNAVAILABLE path)."""
    async def v(funder, signer, token, face_wei):
        if isinstance(result, Exception):
            raise result
        return result
    return v


class TicketAcceptanceTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def _acceptor(self, funding_verifier=None, redis=None):
        return TicketAcceptor(recipient_addr=RECIPIENT, lottery_addr=_LOTTERY.contract_addr,
                              redis=redis or _FakeRedis(), funding_verifier=funding_verifier)

    def _book_with_challenge(self):
        book = ChallengeBook(_FakePaymentHandler())
        reveal, commit = book.issue()
        return book, reveal, commit

    # --- happy paths -------------------------------------------------------

    def test_high_ratio_ticket_credits_full_face_and_flags_winner(self):
        """ratio = max -> P(win) = 1, so EV == face and the ticket always wins.
        Credit is the EV (here == face); is_winner rides along for #6b claiming."""
        async def scenario():
            acc = self._acceptor()
            book, _, commit = self._book_with_challenge()
            amount = 10 ** 15  # 0.001 token in wei
            ts = _mint(amount=amount, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.CREDITED)
            self.assertFalse(r.is_error)
            self.assertTrue(r.is_winner)
            self.assertAlmostEqual(r.credit, amount / WEI)
            self.assertEqual(len(book), 0)  # challenge retired
        self._run(scenario())

    def test_fractional_ratio_credits_expected_value_not_face(self):
        """The crux of EV-crediting: a ticket with P(win) ~ 1/2 credits ~half its
        face — the value transferred at handoff — regardless of whether this
        particular draw wins. Winner-ness does not change the credit. (Before the
        true-up the server credited face-on-win / zero-on-loss; this asserts the
        EV semantics directly.)"""
        async def scenario():
            acc = self._acceptor()
            book, _, commit = self._book_with_challenge()
            face = 10 ** 18           # 1 token
            ratio = 1 << 63           # P(win) ~ 0.5
            ev_wei = (face * (ratio + 1)) >> 64
            ts = _mint(amount=face, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=ratio)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.CREDITED)
            self.assertFalse(r.is_error)
            self.assertAlmostEqual(r.credit, ev_wei / WEI)
            self.assertLess(r.credit, face / WEI)       # EV, not face
            self.assertGreater(r.credit, 0.0)           # and not zero
        self._run(scenario())

    # --- rejections --------------------------------------------------------

    def test_signed_by_stranger_is_rejected(self):
        """A ticket validly signed, but by a key other than the declared funder,
        must not credit (this is the forged-payment hole #6a closes)."""
        async def scenario():
            acc = self._acceptor()
            book, _, commit = self._book_with_challenge()
            # signed by the stranger's key, but the client claims funder=FUNDER
            ts = _mint(amount=10 ** 18, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX,
                       key="0x" + "44" * 32)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_SIGNATURE)
            self.assertTrue(r.is_error)
            self.assertEqual(r.credit, 0.0)
        self._run(scenario())

    def test_unknown_commit_is_rejected(self):
        """A ticket signed against a commit the server never issued (or already
        rotated past) finds no live challenge and is rejected."""
        async def scenario():
            acc = self._acceptor()
            book, _, _ = self._book_with_challenge()   # book holds commit A
            foreign_commit = "0x" + Web3.keccak(b"\xFE" * 32).hex()   # commit B
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=foreign_commit, ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_SIGNATURE)
            self.assertTrue(r.is_error)
        self._run(scenario())

    def test_empty_book_is_rejected(self):
        async def scenario():
            acc = self._acceptor()
            book = ChallengeBook(_FakePaymentHandler())   # nothing issued
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment="0x" + Web3.keccak(b"\x01" * 32).hex(),
                       ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_NO_CHALLENGE)
            self.assertTrue(r.is_error)
        self._run(scenario())

    def test_replayed_winner_is_rejected_by_ledger(self):
        """The same winning ticket presented twice credits at most once. We
        re-issue the identical challenge so commitment binding passes again on
        the replay, isolating the Redis double-credit ledger as the guard."""
        async def scenario():
            acc = self._acceptor()
            ph = _FakePaymentHandler(n=1)   # new_reveal always yields the same pair
            book = ChallengeBook(ph)
            _, commit = book.issue()
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)

            first = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(first.status, AcceptStatus.CREDITED)

            book.issue()  # same FakePH pair -> same commit re-enters the book
            second = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(second.status, AcceptStatus.REJECTED_REPLAY)
            self.assertTrue(second.is_error)
            self.assertEqual(second.credit, 0.0)
        self._run(scenario())

    def test_missing_funder_is_rejected(self):
        async def scenario():
            acc = self._acceptor()
            book, _, commit = self._book_with_challenge()
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=None)
            self.assertEqual(r.status, AcceptStatus.REJECTED_NO_FUNDER)
            self.assertTrue(r.is_error)
        self._run(scenario())

    def test_malformed_ticket_is_rejected(self):
        async def scenario():
            acc = self._acceptor()
            book, _, _ = self._book_with_challenge()
            r = await acc.accept("not-a-valid-ticket", book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_MALFORMED)
            self.assertTrue(r.is_error)
        self._run(scenario())

    def test_tampered_face_value_is_rejected(self):
        """Inflating the face value after signing breaks recovery -> rejected."""
        async def scenario():
            acc = self._acceptor()
            book, _, commit = self._book_with_challenge()
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
            # bump packed0 (first 64 hex chars) -> face/nonce changed, sig stale
            packed0 = (int(ts[:64], 16) + 10 ** 18) & ((1 << 256) - 1)
            tampered = hex(packed0)[2:].zfill(64) + ts[64:]
            r = await acc.accept(tampered, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_SIGNATURE)
            self.assertTrue(r.is_error)
        self._run(scenario())

    # --- funding seam (part 2: on-chain escrow check) ----------------------

    def test_funded_ticket_is_credited(self):
        async def scenario():
            acc = self._acceptor(_verifier(FundingCheck.FUNDED))
            book, _, commit = self._book_with_challenge()
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.CREDITED)
            self.assertTrue(r.is_credited)
        self._run(scenario())

    def test_underfunded_ticket_is_rejected_and_penalised(self):
        async def scenario():
            acc = self._acceptor(_verifier(FundingCheck.UNFUNDED))
            book, _, commit = self._book_with_challenge()
            ts = _mint(amount=10 ** 18, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
            r = await acc.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r.status, AcceptStatus.REJECTED_UNFUNDED)
            self.assertTrue(r.is_error)        # spending from an empty escrow = fault
            self.assertFalse(r.is_credited)
            self.assertEqual(r.credit, 0.0)
        self._run(scenario())

    def test_funding_unavailable_is_no_fault(self):
        """RPC trouble (verifier returns UNAVAILABLE or raises): not credited, but
        NOT charged as an error — the client did nothing wrong."""
        async def scenario():
            for result in (FundingCheck.UNAVAILABLE, RuntimeError("rpc down")):
                acc = self._acceptor(_verifier(result))
                book, _, commit = self._book_with_challenge()
                ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                           commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)
                r = await acc.accept(ts, book=book, funder=FUNDER)
                self.assertEqual(r.status, AcceptStatus.REJECTED_FUNDING_UNAVAILABLE)
                self.assertFalse(r.is_credited)
                self.assertFalse(r.is_error)    # the crux: no penalty
        self._run(scenario())

    def test_unfunded_does_not_burn_ledger_so_funded_retry_credits(self):
        """Funding is checked before the replay ledger, so an unfunded reject must
        not consume the ledger slot — a later funded retry of the same ticket can
        still credit. (Shares one Redis ledger across two acceptors.)"""
        async def scenario():
            redis = _FakeRedis()
            ph = _FakePaymentHandler(n=1)          # re-issue yields the same commit
            book = ChallengeBook(ph)
            _, commit = book.issue()
            ts = _mint(amount=10 ** 15, recipient=RECIPIENT,
                       commitment=ChallengeBook.canon(commit), ratio=UINT64_MAX)

            unfunded = self._acceptor(_verifier(FundingCheck.UNFUNDED), redis=redis)
            r1 = await unfunded.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r1.status, AcceptStatus.REJECTED_UNFUNDED)

            book.issue()                            # re-arm the same challenge
            funded = self._acceptor(_verifier(FundingCheck.FUNDED), redis=redis)
            r2 = await funded.accept(ts, book=book, funder=FUNDER)
            self.assertEqual(r2.status, AcceptStatus.CREDITED)  # ledger wasn't burned
        self._run(scenario())


if __name__ == "__main__":
    unittest.main()
