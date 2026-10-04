"""Tests for EscrowVerifier — the on-chain funding check (Tier-1 #6b, part 2).

Exercises the verifier's logic (threshold, caching, fail-closed) against a fake
``lottery.check_balance`` so no chain/network is touched. The real read path was
validated separately against live Gnosis (funder 0x1E2094D7… -> 4.998 balance).
unittest, no new deps.
"""

import asyncio
import unittest

from escrow import EscrowVerifier
from ticket_acceptance import FundingCheck, ZERO_TOKEN

LOTTERY = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"
FUNDER = "0x1111111111111111111111111111111111111111"
SIGNER = "0x2222222222222222222222222222222222222222"
TOKEN = ZERO_TOKEN


def _make(balance=None, *, raises=None, sleep=None, ttl=30.0, timeout=5.0):
    """Build a verifier whose on-chain read is a controllable fake. Returns the
    verifier and a call-counter dict so tests can assert RPC frequency (caching)."""
    v = EscrowVerifier(lottery_address=LOTTERY, cache_ttl_seconds=ttl,
                       rpc_timeout_seconds=timeout)
    calls = {"n": 0}

    async def fake_check_balance(token, funder, signer):
        calls["n"] += 1
        if sleep:
            await asyncio.sleep(sleep)
        if raises:
            raise raises
        return (balance, 0)        # (balance_wei, escrow_wei)

    v.lottery.check_balance = fake_check_balance
    return v, calls


class EscrowVerifierTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_sufficient_balance_is_funded(self):
        async def s():
            v, _ = _make(balance=5 * 10 ** 18)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18),
                             FundingCheck.FUNDED)
        self._run(s())

    def test_insufficient_balance_is_unfunded(self):
        async def s():
            v, _ = _make(balance=10 ** 17)   # 0.1 < 1.0 face
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18),
                             FundingCheck.UNFUNDED)
        self._run(s())

    def test_exact_balance_is_funded(self):
        """balance == face must pass: a winner claims exactly the face."""
        async def s():
            v, _ = _make(balance=10 ** 18)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18),
                             FundingCheck.FUNDED)
        self._run(s())

    def test_cache_hit_avoids_second_rpc(self):
        async def s():
            v, calls = _make(balance=5 * 10 ** 18, ttl=60.0)
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            self.assertEqual(calls["n"], 1)        # one read served both checks
        self._run(s())

    def test_invalidate_forces_reread(self):
        async def s():
            v, calls = _make(balance=5 * 10 ** 18, ttl=60.0)
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            v.invalidate(FUNDER, SIGNER, TOKEN)
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            self.assertEqual(calls["n"], 2)
        self._run(s())

    def test_rpc_error_is_unavailable(self):
        async def s():
            v, _ = _make(raises=RuntimeError("rpc down"))
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18),
                             FundingCheck.UNAVAILABLE)
        self._run(s())

    def test_timeout_is_unavailable(self):
        async def s():
            v, _ = _make(balance=5 * 10 ** 18, sleep=1.0, timeout=0.05)
            self.assertEqual(await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18),
                             FundingCheck.UNAVAILABLE)
        self._run(s())

    def test_failures_are_not_cached(self):
        """A failed read must not poison the cache — the next check re-reads."""
        async def s():
            v, calls = _make(raises=RuntimeError("flap"))
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            await v.check(FUNDER, SIGNER, TOKEN, 10 ** 18)
            self.assertEqual(calls["n"], 2)
        self._run(s())


if __name__ == "__main__":
    unittest.main()
