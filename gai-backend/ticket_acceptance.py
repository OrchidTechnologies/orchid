"""Ticket acceptance — the single chokepoint that decides what an incoming
nanopayment ticket is worth.

This is the billing-server trust boundary (Tier-1 #6a). A ticket arriving over
the websocket may be forged, replayed, or signed against a stale/foreign
challenge. ``TicketAcceptor.accept`` turns a raw ticket string into one explicit,
auditable verdict:

  * CREDITED   — authentic, claimable, non-replayed ticket → credit its EV
                 (face x P(win)). The is_winner flag rides along for the
                 collection/claim path (#6b) but does NOT affect the credit.
  * REJECTED_* — misbehaviour → no credit, surfaced to the caller as error

The unit of account is **the expected value, fixed at handoff**. When the client
hands over a ticket it has transferred ``face x P(win)`` of value — symmetrically,
before anyone consults a reveal. Whether that ticket later resolves to a winner
is a fact about *collection*, not about how much was paid: the server books the
EV now and, separately, claims the winners on-chain afterward as housekeeping.
Over many tickets ``sum(claimed face) -> sum(EV credited)``, so the treasury
reconciles to the books — and the lottery variance lives in on-chain collection,
amortised across all clients and time, instead of jittering any client's
moment-to-moment service balance. (Crediting face-on-win would put the variance
in exactly the wrong place; this module deliberately does not.)

What this establishes chain-free:

  1. signature authenticity — the funder is read from the *signed* ticket
     (packed1[1,161)), not the client's declared orchid_account, and the
     signature must recover to that funder (the self-funded commit-1 model;
     delegated signers are a future extension). The client can no longer name a
     funder it does not control;
  2. commitment binding — the ticket answers a live, server-issued challenge, so
     the winners *within the credited stream* are actually claimable on-chain
     (commitment == keccak(reveal)) — which is what makes collection -> EV hold;
  3. claimable lifetime — issued + expire_delta must exceed now by a safe
     margin (MIN_REMAINING_LIFETIME_SECONDS), not merely be in the future: the
     claim worker batches winners for up to an hour before broadcasting, and a
     ticket that expires in the meantime pays nothing on-chain;
  4. EV crediting — every accepted ticket books its expected value, once;
  5. double-credit ledger — an atomic Redis guard so each ticket is booked at
     most once, even across the in-flight challenge race. Keyed on the
     contract's own replay key keccak(digest, signer) (Ticket.track_key), so a
     re-signed/malleated copy of the same payment collides with the original.

The remaining trust assumption — that the funder's escrow actually backs the
face value a winner would claim — is the ``funding_verifier`` seam (escrow.py).
Crucially it is keyed on the ticket's own (token, funder, signer), the SAME
account an on-chain claim debits, because both read the funder from the same
signed bytes — so the funding check verifies exactly what collection will hit.
Without a verifier wired, accept() runs with funding unverified and says so.
"""

import logging
import time
from collections import OrderedDict
from dataclasses import dataclass
from enum import Enum
from typing import Awaitable, Callable, Optional

from ticket import Ticket, TicketError

ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

logger = logging.getLogger(__name__)

WEI = 10 ** 18
ZERO_TOKEN = "0x0000000000000000000000000000000000000000"

# The double-credit ledger entry must outlive the ticket's own claim window — a
# ticket is worthless once expire = issued + expire_delta passes, and the default
# expire_delta is a week (account.DEFAULT_EXPIRE_SECONDS), so 90 days leaves a
# wide margin even for unusually long-lived tickets. The on-chain contract
# independently prevents double-*claim*; this TTL only bounds Redis growth for the
# server-side double-*credit* guard.
LEDGER_TTL_SECONDS = 90 * 24 * 3600

# A ticket must still be claimable when the claim worker finally broadcasts it.
# The worker holds winners for up to ClaimWorker.max_wait_seconds (default 1h)
# plus a poll interval, and a restart can add more; six hours covers that with
# margin. A ticket with less remaining life is rejected as the client's fault —
# it minted a payment we could never collect on. The client's default lifetime
# is a week (account.DEFAULT_EXPIRE_SECONDS), so honest clients clear this
# easily. Keep this > the worker's window if either is ever tuned.
MIN_REMAINING_LIFETIME_SECONDS = 6 * 3600


class AcceptStatus(str, Enum):
    CREDITED = "credited"
    REJECTED_NO_FUNDER = "rejected_no_funder"
    REJECTED_MALFORMED = "rejected_malformed"
    REJECTED_EXPIRED = "rejected_expired"
    REJECTED_SHORT_LIFETIME = "rejected_short_lifetime"
    REJECTED_NO_CHALLENGE = "rejected_no_challenge"
    REJECTED_SIGNATURE = "rejected_signature"
    REJECTED_UNFUNDED = "rejected_unfunded"
    REJECTED_FUNDING_UNAVAILABLE = "rejected_funding_unavailable"
    REJECTED_REPLAY = "rejected_replay"


class FundingCheck(str, Enum):
    """Result of an escrow-funding check (the funding_verifier contract)."""
    FUNDED = "funded"            # escrow backs the face value -> may credit
    UNFUNDED = "unfunded"        # escrow verified insufficient -> reject (client fault)
    UNAVAILABLE = "unavailable"  # couldn't verify (RPC error/timeout) -> no credit, no penalty


# Statuses that must NOT penalise the client: a booked credit, or a no-fault
# transient where we simply couldn't reach the chain to verify funding.
_NON_PENALTY_STATUSES = frozenset({
    AcceptStatus.CREDITED, AcceptStatus.REJECTED_FUNDING_UNAVAILABLE,
})


@dataclass
class AcceptResult:
    status: AcceptStatus
    credit: float                      # EV credited, in tokens (0 on rejection)
    face_value: float                  # the ticket's face value in tokens
    is_winner: bool                    # collection flag — does NOT affect credit
    signer: Optional[str]              # asserted signer (the funder), when known
    ticket_id: Optional[str]
    detail: str

    @property
    def is_credited(self) -> bool:
        return self.status == AcceptStatus.CREDITED

    @property
    def is_error(self) -> bool:
        """True only for outcomes the client is at fault for (caller should debit
        an error fee + send an error frame). A booked credit is never an error,
        winner or not; nor is a no-fault transient (funding-unavailable), which
        the caller should neither credit nor penalise."""
        return self.status not in _NON_PENALTY_STATUSES


# A funding verifier answers: does ``funder``'s escrow back a ``face_wei`` ticket
# signed by ``signer`` for ``token``? (face, not EV — a winner claims the face.)
# Returns a FundingCheck. Wired live in #6b (escrow.EscrowVerifier.check); None
# means funding is not yet verified and tickets credit on authenticity alone.
FundingVerifier = Callable[[str, str, str, int], Awaitable[FundingCheck]]


class ChallengeBook:
    """Per-session set of outstanding ``commit -> reveal`` challenges.

    The reveal is the server's secret: the client receives only the commit and
    cannot tell whether a ticket wins until the server checks is_winner() with
    the matching reveal. We keep a small ring of recent challenges (not just the
    latest) so an invoice sent by the balance monitor and one sent by the main
    loop can be in flight simultaneously without a legitimate ticket being
    rejected for answering the 'wrong' commit. A matched challenge is retired so
    its reveal is used at most once (and never reused after its reveal could
    become public via an on-chain claim).
    """

    def __init__(self, payment_handler, max_outstanding: int = 8):
        self._ph = payment_handler
        self._max = max_outstanding
        self._book: "OrderedDict[str, str]" = OrderedDict()

    @staticmethod
    def canon(commit: str) -> str:
        """Canonical commit form: 0x-prefixed, lowercase — matches what the
        client signs (the invoice carries '0x' + commit)."""
        c = commit.lower()
        return c if c.startswith("0x") else "0x" + c

    def issue(self):
        """Mint a fresh (reveal, commit), record it, return both. The caller
        sends ``commit`` in the invoice; the reveal stays server-side."""
        reveal, commit = self._ph.new_reveal()
        self._book[self.canon(commit)] = reveal
        while len(self._book) > self._max:
            self._book.popitem(last=False)      # evict oldest
        return reveal, commit

    def outstanding(self):
        """Outstanding (commit, reveal) pairs, newest first (a ticket most
        likely answers the most recent invoice)."""
        return list(reversed(self._book.items()))

    def retire(self, commit: str):
        self._book.pop(self.canon(commit), None)

    def __len__(self):
        return len(self._book)


class TicketAcceptor:
    def __init__(self, *, recipient_addr: str, lottery_addr: str, redis,
                 token_addr: str = ZERO_TOKEN,
                 funding_verifier: Optional[FundingVerifier] = None,
                 claim_queue=None,
                 ledger_ttl_seconds: int = LEDGER_TTL_SECONDS,
                 chain_id: int = 100,
                 min_remaining_lifetime_seconds: int = MIN_REMAINING_LIFETIME_SECONDS):
        self.recipient_addr = recipient_addr
        self.lottery_addr = lottery_addr
        self.token_addr = token_addr
        self.redis = redis
        self.funding_verifier = funding_verifier
        self.claim_queue = claim_queue
        self.ledger_ttl = ledger_ttl_seconds
        self.chain_id = chain_id
        self.min_remaining_lifetime = min_remaining_lifetime_seconds

    def _ledger_key(self, track_key: str) -> str:
        return f"billing:ticket:seen:{track_key}"

    async def accept(self, ticket_str: str, *, book: ChallengeBook,
                     funder: Optional[str] = None, now: Optional[int] = None) -> AcceptResult:
        # 1. Parse the immutable payload. ticket_id is independent of the
        #    server-supplied commitment/reveal, so compute it once up front.
        try:
            ticket = Ticket.deserialize(
                ticket_str,
                recipient=self.recipient_addr,
                lottery_addr=self.lottery_addr,
                token_addr=self.token_addr,
                chain_id=self.chain_id,
            )
            ticket_id = ticket.ticket_id()
        except TicketError as e:
            return AcceptResult(AcceptStatus.REJECTED_MALFORMED, 0.0, 0.0, False,
                                None, None, f"malformed ticket: {e}")

        # 1a. Who is paying is read from the SIGNED ticket (packed1[1,161)), never
        #     from the client's word. This is the funder whose escrow an on-chain
        #     claim will debit — keyed (token, funder, signer) — so reading it from
        #     the same signed bytes guarantees the funding check below verifies the
        #     exact account collection will hit. A zero funder names no payer.
        #     The `funder` argument (orchid_account) is now only an advisory
        #     cross-check; the ticket's signed funder is authoritative.
        ticket_funder = ticket.funder()
        if int(ticket_funder, 16) == 0:
            return AcceptResult(AcceptStatus.REJECTED_NO_FUNDER, 0.0, 0.0, False,
                                None, ticket_id, "ticket carries no funder (packed1 funder = 0)")
        if funder and funder.lower() != ticket_funder.lower():
            logger.debug("Declared funder %s != signed ticket funder %s; the signed "
                         "funder is authoritative", funder, ticket_funder)

        face = ticket.face_value() / WEI
        ev = ticket.expected_value() / WEI       # the value transferred at handoff

        # 1b. Expiry. The contract treats a ticket as worthless once
        #     expire = issued + delta <= now, so its winners are uncollectable —
        #     crediting EV against value we could never claim would not reconcile.
        now = int(time.time()) if now is None else int(now)
        if ticket.is_expired(now):
            return AcceptResult(AcceptStatus.REJECTED_EXPIRED, 0.0, face, False,
                                ticket_funder, ticket_id,
                                f"ticket expired (expire={ticket.expire()} <= now={now})")

        # 1c. Remaining lifetime. Alive now is not enough: the claim worker holds
        #     winners for up to its batching window before broadcasting, and a
        #     ticket that expires in between returns 0 at claim time — the client
        #     would have been credited full EV for a payment we can never collect.
        if ticket.expire() <= now + self.min_remaining_lifetime:
            return AcceptResult(AcceptStatus.REJECTED_SHORT_LIFETIME, 0.0, face, False,
                                ticket_funder, ticket_id,
                                f"ticket lifetime too short to claim (expire={ticket.expire()} "
                                f"<= now + {self.min_remaining_lifetime}s)")

        # 2. Commitment binding + signature authenticity, fused: find the
        #    outstanding challenge whose commitment makes the signature recover to
        #    the ticket's signed funder. The commitment is not in the ticket bytes,
        #    so we try each live challenge; the one that verifies identifies both
        #    the reveal to use and proves the funder signed *this* recipient, face,
        #    and ratio. (This is the self-funded binding signer == funder, the
        #    commit-1 model. Delegated signers — signer authorised by funder's
        #    escrow but != funder — would need the escrow's signer set to identify
        #    the commit chain-free; a future extension.) No match -> the ticket
        #    answers a commit we never issued (stale/foreign) or wasn't signed by
        #    its own funder.
        if len(book) == 0:
            return AcceptResult(AcceptStatus.REJECTED_NO_CHALLENGE, 0.0, face, False,
                                ticket_funder, ticket_id, "no outstanding challenge")

        matched_commit = None
        matched_signer = None
        for commit, reveal in book.outstanding():
            ticket.commitment = commit
            try:
                recovered = ticket.recover_signer()
            except TicketError:
                continue
            if recovered.lower() == ticket_funder.lower():
                ticket.reveal = reveal
                matched_commit = commit
                matched_signer = recovered      # == funder in the self-funded model
                break
        if matched_commit is None:
            return AcceptResult(AcceptStatus.REJECTED_SIGNATURE, 0.0, face, False,
                                ticket_funder, ticket_id,
                                "signature does not match the ticket's funder for any live challenge")

        # The ledger key is the contract's own replay key, keccak(digest, signer).
        # It needs the matched commitment (the digest covers it), so it can only
        # be computed now; ticket_id (over the raw bytes) stays for logging.
        ledger_id = ticket.track_key(matched_signer)

        # 3. Funding check (commit 2 seam). The escrow must back the FACE value,
        #    because that is what a winner in this stream will claim on-chain; if
        #    it can't, a credited EV could never be realised. Keyed on the ticket's
        #    own (funder, signer), the same pair the on-chain claim debits. Gates
        #    EVERY ticket (any one could be the winner), not just winners.
        if self.funding_verifier is None:
            logger.warning(
                "Crediting ticket %s (EV %s, face %s) with funding UNVERIFIED "
                "(no escrow verifier wired)", ticket_id[:12], ev, face)
        else:
            try:
                check = await self.funding_verifier(
                    ticket_funder, matched_signer, self.token_addr,
                    ticket.face_value())
            except Exception as e:
                logger.error("Funding verifier raised for %s: %s", ticket_id[:12], e)
                check = FundingCheck.UNAVAILABLE
            if check == FundingCheck.UNFUNDED:
                # Verified insufficient: the client is spending from an escrow that
                # can't back the face a winner would claim — reject and penalise.
                book.retire(matched_commit)
                return AcceptResult(AcceptStatus.REJECTED_UNFUNDED, 0.0, face, False,
                                    ticket_funder, ticket_id, "funder escrow does not back face value")
            if check == FundingCheck.UNAVAILABLE:
                # We couldn't reach the chain — not the client's fault. Don't
                # credit (funding unproven) and don't penalise; the client retries
                # on the next invoice, by which point the RPC may have recovered.
                book.retire(matched_commit)
                return AcceptResult(AcceptStatus.REJECTED_FUNDING_UNAVAILABLE, 0.0, face,
                                    False, ticket_funder, ticket_id,
                                    "escrow status unavailable (RPC) — not credited, not penalised")

        # 4. Double-credit ledger. EV is booked once per ticket (every ticket
        #    carries value now, not just winners), so the atomic SET NX guard
        #    covers all of them. Done before the credit so a replay never books.
        #    Keyed on keccak(digest, signer) — the key the contract dedupes claims
        #    on — not on the signature bytes: a malleated (r, s) is a different
        #    ticket_id but the same payment, and must be caught here.
        first = await self.redis.set(self._ledger_key(ledger_id), "1",
                                     nx=True, ex=self.ledger_ttl)
        if not first:
            book.retire(matched_commit)
            return AcceptResult(AcceptStatus.REJECTED_REPLAY, 0.0, face, False,
                                ticket_funder, ticket_id, "ticket already credited")

        # 5. Winner status is a COLLECTION fact, incidental to the books: it does
        #    not change the EV credited, only whether #6b queues this ticket for
        #    an on-chain claim. The server holds the reveal, so it can decide now.
        try:
            winner = ticket.is_winner()
        except TicketError:
            winner = False
        if winner and self.claim_queue is not None:
            try:
                await self.claim_queue.enqueue(ticket, ticket_funder, matched_signer)
            except Exception as e:
                # The EV credit already stands — a queue failure is lost
                # collection, never a client-facing error or an unwound credit.
                logger.error("Failed to queue winning ticket %s for claim: %s",
                             ticket_id[:12], e)
        elif winner:
            logger.info("Winning ticket %s (face %s) — no claim queue wired",
                        ticket_id[:12], face)

        book.retire(matched_commit)
        return AcceptResult(AcceptStatus.CREDITED, ev, face, winner, matched_signer,
                            ticket_id, "winner" if winner else "miss")
