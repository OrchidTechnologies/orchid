"""On-chain escrow verification for ticket funding (Tier-1 #6b, part 2).

The acceptance chokepoint (ticket_acceptance.TicketAcceptor) proves a ticket is
authentic, claimable, and non-replayed, and books its EV. The remaining trust
assumption is economic: does the funder's escrow actually hold enough to pay the
*face value* a winner in that stream would claim on-chain? Without this, a client
could sign perfectly valid tickets against an empty escrow and get credited for
EV the server can never realise.

``EscrowVerifier.check`` is the live funding_verifier wired into the acceptor. It
reads the Orchid lottery account via ``lottery.check_balance(token, funder, signer)``
-> ``(balance, escrow)`` and returns a tri-state FundingCheck. Two independent
predicates must BOTH hold for FUNDED:

  * ``2*face <= escrow`` — the COLLATERAL bound (DESIGN-DECISIONS D10). escrow is
    the funder's bonded, slow-to-withdraw collateral (upper-128 of
    escrow_amount_). Capping honored face at half of it guarantees the collateral
    a funder forfeits on a double-spend always exceeds 2x any single face, so
    cheating is unprofitable. This is the trust anchor.
  * ``face <= balance`` — the LIQUIDITY check. A winner is *paid* from the
    spendable balance (lower-128), and lottery1.sol claim_() is unforgiving when
    it falls short: it pays out only what balance remains and then zeroes the
    whole escrow_amount_ word — the funder loses its entire escrow and the
    recipient is still short. So a balance below a single face is not a benign
    dip of the payout pool; it is the state in which the next winner slashes an
    honest funder and leaves our credited EV uncollectable. The contracts are
    fixed; the service has to refuse to accept tickets in that state.

  * FUNDED      — both hold                 (-> credit allowed)
  * UNFUNDED    — either verified failing   (-> reject, client fault)
  * UNAVAILABLE — RPC error/timeout         (-> no credit, no penalty)

The client mirrors both when sizing a face: face = min(escrow//2, balance).

Two design points the billing hot path demands:

  1. **Caching.** The escrow read is an on-chain RPC; doing one per ticket would
     put Gnosis latency on every invoice round-trip. We cache the (balance,
     escrow) pair per (funder, signer, token) for a short TTL, so a session does
     ~one read per TTL
     rather than one per ticket. The escrow only drops as the funder withdraws
     collateral (rare, behind a warn+unlock delay); the balance drops as winners
     are claimed, which is why the claim worker calls invalidate() after each
     claim. Brief staleness between those events is acceptable — the on-chain
     contract is the ultimate authority.

  2. **Fail-closed, but no-fault.** On RPC error or timeout we return UNAVAILABLE,
     never FUNDED — we never credit funding we couldn't prove. But UNAVAILABLE is
     distinct from UNFUNDED: the acceptor neither credits nor penalises the client
     for our inability to reach the chain.

Uses AsyncWeb3 (the existing Lottery.read is async; it was simply never handed an
async provider before). The verifier is constructed once and shared across all
sessions so the cache is process-wide.
"""

import asyncio
import logging
import time

from web3 import AsyncWeb3, AsyncHTTPProvider

from lottery import Lottery
from ticket_acceptance import FundingCheck, ZERO_TOKEN

logger = logging.getLogger(__name__)

DEFAULT_RPC_URL = "https://rpc.gnosischain.com/"


class EscrowVerifier:
    def __init__(self, *, lottery_address: str, rpc_url: str = DEFAULT_RPC_URL,
                 chain_id: int = 100, cache_ttl_seconds: float = 30.0,
                 rpc_timeout_seconds: float = 5.0):
        self.async_w3 = AsyncWeb3(AsyncHTTPProvider(rpc_url))
        self.lottery = Lottery(self.async_w3, chain_id=chain_id, addr=lottery_address)
        self.cache_ttl = cache_ttl_seconds
        self.rpc_timeout = rpc_timeout_seconds
        # (funder, signer, token) -> ((balance_wei, escrow_wei), expiry_monotonic)
        self._cache = {}

    async def check(self, funder: str, signer: str, token: str,
                    face_wei: int) -> FundingCheck:
        key = (funder.lower(), signer.lower(), token.lower())
        now = time.monotonic()

        cached = self._cache.get(key)
        if cached is not None and cached[1] > now:
            balance, escrow = cached[0]
        else:
            try:
                balance, escrow = await asyncio.wait_for(
                    self.lottery.check_balance(token, funder, signer),
                    timeout=self.rpc_timeout,
                )
            except Exception as e:
                # Any failure to read the chain -> unverifiable. Fail closed
                # (never FUNDED) but flag it as no-fault so the client isn't
                # penalised for our RPC trouble.
                logger.error("escrow read failed (funder=%s signer=%s): %s: %s",
                             funder, signer, type(e).__name__, e)
                return FundingCheck.UNAVAILABLE
            self._cache[key] = ((balance, escrow), now + self.cache_ttl)

        # Honor a ticket only if (a) the funder's at-risk COLLATERAL covers 2x its
        # face — the bond forfeited on a double-spend then always exceeds any
        # single face, so cheating is unprofitable (DESIGN-DECISIONS D10) — AND
        # (b) the spendable BALANCE covers the face itself, because claim_() pays
        # a winner from balance and, if that falls short, zeroes the funder's
        # whole escrow while paying us only the remainder (module docstring).
        if 2 * face_wei > escrow:
            logger.info("unfunded: 2*face %d > escrow %d (funder=%s)",
                        face_wei, escrow, funder)
            return FundingCheck.UNFUNDED
        if face_wei > balance:
            logger.info("unfunded: face %d > spendable balance %d (funder=%s)",
                        face_wei, balance, funder)
            return FundingCheck.UNFUNDED
        return FundingCheck.FUNDED

    def invalidate(self, funder: str, signer: str,
                   token: str = ZERO_TOKEN) -> None:
        """Drop a cached escrow balance — e.g. after this server claims a winning
        ticket against (funder, signer), so the next check re-reads the reduced
        balance instead of trusting a now-stale cache (used by #6b claim wiring)."""
        self._cache.pop((funder.lower(), signer.lower(), token.lower()), None)

    async def aclose(self) -> None:
        try:
            provider = self.async_w3.provider
            if hasattr(provider, "disconnect"):
                await provider.disconnect()
        except Exception:
            pass
