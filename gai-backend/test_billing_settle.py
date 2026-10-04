"""Tests for StrictRedisBilling.settle — the Tier-0 hold->reconcile primitive.

Uses a minimal in-memory async fake for the subset of redis-py the billing
code touches (pipeline/watch/multi/set/publish/execute/get), so the real
adjust()/balance() arithmetic is exercised without a live Redis. No new deps;
unittest to match test_config_validator.py / test_config_manager.py.
"""

import asyncio
import unittest

from billing import StrictRedisBilling


class _FakePipeline:
    def __init__(self, store):
        self._store = store

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def watch(self, key):
        return True

    def multi(self):
        return None

    async def set(self, key, value):
        self._store[key] = value
        return True

    async def publish(self, channel, value):
        return 0

    async def execute(self):
        return []


class _FakeRedis:
    """Just enough of redis.asyncio.Redis for adjust()/balance()/settle()."""

    def __init__(self):
        self.store = {}

    async def ping(self):
        return True

    async def get(self, key):
        return self.store.get(key)

    def pipeline(self):
        return _FakePipeline(self.store)


class TestSettle(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_refund_overcharge(self):
        """Common case: held ceiling far exceeds actual -> difference refunded."""
        async def scenario():
            b = StrictRedisBilling(_FakeRedis())
            await b.credit("s", amount=5.0)   # fund
            await b.debit("s", amount=1.0)    # pre-debit the worst-case ceiling
            self.assertAlmostEqual(await b.balance("s"), 4.0)

            refunded = await b.settle("s", held=1.0, actual=0.2)

            self.assertAlmostEqual(refunded, 0.8)
            # client paid only the real 0.2, not the 1.0 ceiling
            self.assertAlmostEqual(await b.balance("s"), 4.8)
        self._run(scenario())

    def test_collect_undercharge(self):
        """Long tool loop: actual exceeds the single held ceiling -> shortfall collected."""
        async def scenario():
            b = StrictRedisBilling(_FakeRedis())
            await b.credit("s", amount=5.0)
            await b.debit("s", amount=1.0)    # held 1.0

            refunded = await b.settle("s", held=1.0, actual=1.5)

            self.assertAlmostEqual(refunded, -0.5)
            # 5.0 funded - 1.0 hold - 0.5 shortfall = 3.5
            self.assertAlmostEqual(await b.balance("s"), 3.5)
        self._run(scenario())

    def test_exact_is_noop(self):
        """held == actual -> no balance movement, zero returned."""
        async def scenario():
            b = StrictRedisBilling(_FakeRedis())
            await b.credit("s", amount=5.0)
            await b.debit("s", amount=1.0)

            refunded = await b.settle("s", held=1.0, actual=1.0)

            self.assertEqual(refunded, 0.0)
            self.assertAlmostEqual(await b.balance("s"), 4.0)
        self._run(scenario())

    def test_full_refund_when_actual_zero(self):
        """Degenerate (no usage) -> whole hold comes back."""
        async def scenario():
            b = StrictRedisBilling(_FakeRedis())
            await b.credit("s", amount=2.0)
            await b.debit("s", amount=0.75)

            refunded = await b.settle("s", held=0.75, actual=0.0)

            self.assertAlmostEqual(refunded, 0.75)
            self.assertAlmostEqual(await b.balance("s"), 2.0)
        self._run(scenario())


class TestFinalizeBilling(unittest.TestCase):
    """Drives InferenceAPI._finalize_billing — the glue that fixes the overcharge:
    a held char/4+max_tokens ceiling reconciled down to authoritative usage."""

    def _run(self, coro):
        return asyncio.run(coro)

    def _api(self, billing):
        # bypass __init__ (it wants real redis / config / tool registry); the
        # helper only touches self.billing + the pure pricing methods.
        from inference_core import InferenceAPI
        api = InferenceAPI.__new__(InferenceAPI)
        api.billing = billing
        return api

    def _completion(self, prompt_tokens, completion_tokens):
        from inference_models import ChatCompletion, ChatChoice, Message, Usage
        return ChatCompletion(
            id="x", model="m",
            choices=[ChatChoice(index=0, message=Message(role="assistant", content="hi"))],
            usage=Usage(prompt_tokens=prompt_tokens, completion_tokens=completion_tokens,
                        total_tokens=prompt_tokens + completion_tokens),
        )

    def test_overcharge_is_reconciled(self):
        """The bug this PR fixes: ceiling held up front, real usage much smaller,
        client ends up paying actual — not the ceiling — and can see the price."""
        async def scenario():
            billing = StrictRedisBilling(_FakeRedis())
            await billing.credit("s", amount=100.0)
            api = self._api(billing)
            pricing = {"type": "fixed", "input_price": 3.0, "output_price": 15.0}  # per 1M

            # pre-debit the worst-case ceiling (e.g. 1000 in + 4096 max output)
            held = api.calculate_cost(pricing, 1000, 4096)
            await billing.debit("s", amount=held)

            # provider actually used 1000 in / 200 out
            out = await api._finalize_billing("s", self._completion(1000, 200),
                                              {"pricing": pricing}, held)
            actual = api.calculate_cost(pricing, 1000, 200)

            self.assertLess(actual, held)                                  # the overcharge existed
            self.assertAlmostEqual(await billing.balance("s"), 100.0 - actual)  # paid actual, not ceiling
            self.assertIsNotNone(out.orchid_billing)
            self.assertAlmostEqual(out.orchid_billing.cost, actual)
            self.assertEqual(out.orchid_billing.pricing_type, "fixed")
            self.assertEqual(out.orchid_billing.output_price, 15.0)
        self._run(scenario())

    def test_non_token_pricing_skips_reconcile(self):
        """tools-only style pricing (no input/output rates) must not crash and
        must leave the hold untouched rather than mis-bill."""
        async def scenario():
            billing = StrictRedisBilling(_FakeRedis())
            await billing.credit("s", amount=10.0)
            await billing.debit("s", amount=2.0)   # held
            api = self._api(billing)

            out = await api._finalize_billing("s", self._completion(5, 5),
                                              {"pricing": {"invoice": 1.0}}, 2.0)

            self.assertAlmostEqual(await billing.balance("s"), 8.0)  # unchanged
            self.assertIsNone(out.orchid_billing)
        self._run(scenario())


if __name__ == "__main__":
    unittest.main()
