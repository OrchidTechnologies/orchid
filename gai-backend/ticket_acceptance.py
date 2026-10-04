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

  1. signature authenticity — the ticket is signed by the funder the client
     claims to be paying from (commit-1 self-funded model; #6b generalises to
     escrow-funded delegated signers via the funding_verifier seam);
  2. commitment binding — the ticket answers a live, server-issued challenge, so
     the winners *within the credited stream* are actually claimable on-chain
     (commitment == keccak(reveal)) — which is what makes collection -> EV hold;
  3. EV crediting — every accepted ticket books its expected value, once;
  4. double-credit ledger — an atomic Redis guard so each ticket is booked at
     most once, even across the in-flight challenge race.

The remaining trust assumption — that the funder's escrow actually backs the
face value a winner would claim — is the ``funding_verifier`` seam, wired live in
commit 2 (#6b). Until then accept() runs with funding unverified and says so.
"""

import logging
from collections import OrderedDict
from dataclasses import dataclass
from enum import Enum
from typing import Awaitable, Callable, Optional

from ticket import Ticket, TicketError

logger = logging.getLogger(__name__)

WEI = 10 ** 18
ZERO_TOKEN = "0x0000000000000000000000000000000000000000"

# A winning ticket retains on-chain value indefinitely (no expiry in the v1
# packing), so the double-credit ledger entry must outlive any realistic claim
# window. The on-chain contract independently prevents double-*claim*; this TTL
# only bounds Redis growth for the server-side double-*credit* guard.
LEDGER_TTL_SECONDS = 90 * 24 * 3600


class AcceptStatus(str, Enum):
    CREDITED = "credited"
    REJECTED_NO_FUNDER = "rejected_no_funder"
    REJECTED_MALFORMED = "rejected_malformed"
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
                 ledger_ttl_seconds: int = LEDGER_TTL_SECONDS):
        self.recipient_addr = recipient_addr
        self.lottery_addr = lottery_addr
        self.token_addr = token_addr
        self.redis = redis
        self.funding_verifier = funding_verifier
        self.ledger_ttl = ledger_ttl_seconds

    def _ledger_key(self, ticket_id: str) -> str:
        return f"billing:ticket:seen:{ticket_id}"

    async def accept(self, ticket_str: str, *, book: ChallengeBook,
                     funder: Optional[str]) -> AcceptResult:
        # 0. We must know who is paying. The funder is the escrow owner the
        #    client declared in request_token; without it we cannot tie the
        #    signature to anything that backs value.
        if not funder:
            return AcceptResult(AcceptStatus.REJECTED_NO_FUNDER, 0.0, 0.0, False,
                                None, None, "no funder declared (orchid_account)")

        # 1. Parse the immutable payload. ticket_id is independent of the
        #    server-supplied commitment/reveal, so compute it once up front.
        try:
            ticket = Ticket.deserialize(
                ticket_str,
                recipient=self.recipient_addr,
                lottery_addr=self.lottery_addr,
                token_addr=self.token_addr,
            )
            ticket_id = ticket.ticket_id()
        except TicketError as e:
            return AcceptResult(AcceptStatus.REJECTED_MALFORMED, 0.0, 0.0, False,
                                None, None, f"malformed ticket: {e}")

        face = ticket.face_value() / WEI
        ev = ticket.expected_value() / WEI       # the value transferred at handoff

        # 2. Commitment binding + signature authenticity, fused: find the
        #    outstanding challenge whose commitment makes the signature recover
        #    to the declared funder. The commitment is not in the ticket bytes,
        #    so we try each live challenge; the one that verifies identifies both
        #    the reveal to use and proves the funder signed *this* recipient,
        #    face, and ratio. No live challenge matching -> the ticket answers a
        #    commit we never issued (stale/foreign) or was signed by someone else.
        if len(book) == 0:
            return AcceptResult(AcceptStatus.REJECTED_NO_CHALLENGE, 0.0, face, False,
                                None, ticket_id, "no outstanding challenge")

        matched_commit = None
        for commit, reveal in book.outstanding():
            ticket.commitment = commit
            try:
                if ticket.verify_signature(funder):
                    ticket.reveal = reveal
                    matched_commit = commit
                    break
            except TicketError:
                continue
        if matched_commit is None:
            return AcceptResult(AcceptStatus.REJECTED_SIGNATURE, 0.0, face, False,
                                None, ticket_id,
                                "signature does not match funder for any live challenge")

        # 3. Funding check (commit 2 seam). The escrow must back the FACE value,
        #    because that is what a winner in this stream will claim on-chain; if
        #    it can't, a credited EV could never be realised. Gates EVERY ticket
        #    (any one could be the winner), not just the ones that happen to win.
        if self.funding_verifier is None:
            logger.warning(
                "Crediting ticket %s (EV %s, face %s) with funding UNVERIFIED "
                "(no escrow verifier wired)", ticket_id[:12], ev, face)
        else:
            try:
                check = await self.funding_verifier(
                    funder, ticket.recover_signer(), self.token_addr,
                    ticket.face_value())
            except Exception as e:
                logger.error("Funding verifier raised for %s: %s", ticket_id[:12], e)
                check = FundingCheck.UNAVAILABLE
            if check == FundingCheck.UNFUNDED:
                # Verified insufficient: the client is spending from an escrow that
                # can't back the face a winner would claim — reject and penalise.
                book.retire(matched_commit)
                return AcceptResult(AcceptStatus.REJECTED_UNFUNDED, 0.0, face, False,
                                    funder, ticket_id, "funder escrow does not back face value")
            if check == FundingCheck.UNAVAILABLE:
                # We couldn't reach the chain — not the client's fault. Don't
                # credit (funding unproven) and don't penalise; the client retries
                # on the next invoice, by which point the RPC may have recovered.
                book.retire(matched_commit)
                return AcceptResult(AcceptStatus.REJECTED_FUNDING_UNAVAILABLE, 0.0, face,
                                    False, funder, ticket_id,
                                    "escrow status unavailable (RPC) — not credited, not penalised")

        # 4. Double-credit ledger. EV is booked once per ticket (every ticket
        #    carries value now, not just winners), so the atomic SET NX guard
        #    covers all of them. Done before the credit so a replay never books.
        first = await self.redis.set(self._ledger_key(ticket_id), "1",
                                     nx=True, ex=self.ledger_ttl)
        if not first:
            book.retire(matched_commit)
            return AcceptResult(AcceptStatus.REJECTED_REPLAY, 0.0, face, False,
                                funder, ticket_id, "ticket already credited")

        # 5. Winner status is a COLLECTION fact, incidental to the books: it does
        #    not change the EV credited, only whether #6b queues this ticket for
        #    an on-chain claim. The server holds the reveal, so it can decide now.
        try:
            winner = ticket.is_winner()
        except TicketError:
            winner = False
        if winner:
            logger.info("Winning ticket %s (face %s) — to be queued for claim (#6b)",
                        ticket_id[:12], face)

        book.retire(matched_commit)
        return AcceptResult(AcceptStatus.CREDITED, ev, face, winner, funder,
                            ticket_id, "winner" if winner else "miss")
