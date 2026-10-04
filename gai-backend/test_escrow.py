"""Tests for EscrowVerifier — the on-chain funding check (Tier-1 #6b, part 2).

Exercises the verifier's logic (threshold, caching, fail-closed) against a fake
``lottery.check_balance`` so no chain/network is touched. The real read path was
validated separately against live Gnosis (funder 0x1E2094D7… -> 4.998 balance).

The funding predicate has two parts: the COLLATERAL bound ``2*face <= escrow``
(the funder's at-risk bond, upper-128 of escrow_amount_ — DESIGN-DECISIONS D10)
and the LIQUIDITY check ``face <= balance`` (a winner is paid from the spendable
balance, and claim_() slashes the whole escrow if it falls short). unittest, no
new deps.
"""

import asyncio
import unittest

from escrow import EscrowVerifier
from ticket_acceptance import FundingCheck, ZERO_TOKEN

LOTTERY = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"
FUNDER = "0x1111111111111111111111111111111111111111"
SIGNER = "0x2222222222222222222222222222222222222222"
TOKEN = ZERO_TOKEN
FACE = 10 ** 18


def _make(escrow=None, *, balance=None, raises=None, sleep=None, ttl=30.0,
          timeout=5.0):
    """Build a verifier whose on-chain read is a controllable fake. Returns the
    verifier and a call-counter dict so tests can assert RPC frequency (caching).
    ``balance`` defaults to ``escrow`` so the collateral-bound tests are not
    confounded by liquidity (balance >= 2*face >= face whenever escrow passes)."""
    if balance is None:
        balance = escrow
    v = EscrowVerifier(lottery_address=LOTTERY, cache_ttl_seconds=ttl,
                       rpc_timeout_seconds=timeout)
    calls = {"n": 0}

    async def fake_check_balance(token, funder, signer):
        calls["n"] += 1
        if sleep:
            await asyncio.sleep(sleep)
        if raises:
            raise raises
        return (balance, escrow)  # (balance_wei, escrow_wei)
    v.lottery.check_balance = fake_check_balance
    return v, calls


class EscrowVerifierTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_escrow_covering_double_face_is_funded(self):
        async def s():
            v, _ = _make(escrow=5 * FACE)        # 5x face >> 2x face
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.FUNDED)
        self._run(s())

    def test_escrow_below_double_face_is_unfunded(self):
        async def s():
            v, _ = _make(escrow=FACE)            # 1x face < 2x face required
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.UNFUNDED)
        self._run(s())

    def test_exactly_double_face_is_funded(self):
        """escrow == 2*face is the boundary and must pass (<=)."""
        async def s():
            v, _ = _make(escrow=2 * FACE)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.FUNDED)
        self._run(s())

    def test_one_wei_below_double_face_is_unfunded(self):
        """escrow == 2*face - 1 must fail — the collateral no longer covers 2x."""
        async def s():
            v, _ = _make(escrow=2 * FACE - 1)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.UNFUNDED)
        self._run(s())

    def test_balance_below_face_is_unfunded_despite_ample_escrow(self):
        """Liquidity check: ample collateral does not rescue a thin payout pool —
        claim_() would pay only the balance and zero the funder's whole escrow."""
        async def s():
            v, _ = _make(escrow=10 * FACE, balance=FACE - 1)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.UNFUNDED)
        self._run(s())

    def test_balance_exactly_face_is_funded(self):
        """balance == face is the liquidity boundary and must pass (<=)."""
        async def s():
            v, _ = _make(escrow=2 * FACE, balance=FACE)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.FUNDED)
        self._run(s())

    def test_cache_hit_avoids_second_rpc(self):
        async def s():
            v, calls = _make(escrow=5 * FACE, ttl=60.0)
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            self.assertEqual(calls["n"], 1)        # one read served both checks
        self._run(s())

    def test_invalidate_forces_reread(self):
        async def s():
            v, calls = _make(escrow=5 * FACE, ttl=60.0)
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            v.invalidate(FUNDER, SIGNER, TOKEN)
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            self.assertEqual(calls["n"], 2)
        self._run(s())

    def test_rpc_error_is_unavailable(self):
        async def s():
            v, _ = _make(raises=RuntimeError("rpc down"))
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.UNAVAILABLE)
        self._run(s())

    def test_timeout_is_unavailable(self):
        async def s():
            v, _ = _make(escrow=5 * FACE, sleep=1.0, timeout=0.05)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, FACE),
                             FundingCheck.UNAVAILABLE)
        self._run(s())

    def test_failures_are_not_cached(self):
        """A failed read must not poison the cache — the next check re-reads."""
        async def s():
            v, calls = _make(raises=RuntimeError("flap"))
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            await v.check(FUNDER, SIGNER, TOKEN, FACE)
            self.assertEqual(calls["n"], 2)
        self._run(s())


if __name__ == "__main__":
    unittest.main()
