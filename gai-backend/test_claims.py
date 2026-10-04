"""Tests for ClaimQueue — the durable winner hand-off (Tier-1 #6b-a).

In-memory fake for the Redis list ops; no chain, no network. Verifies the claim
record is self-contained and JSON-round-trips, and that enqueue/peek behave like
a durable FIFO that peek does not consume. unittest, no new deps.
"""

import asyncio
import json
import unittest

from claims import ClaimQueue, ClaimWorker, PENDING_KEY
from ticket import Ticket

ZERO = "0x0000000000000000000000000000000000000000"
UINT64_MAX = (1 << 64) - 1


class _FakeRedis:
    def __init__(self):
        self.lists = {}

    async def rpush(self, key, *values):
        self.lists.setdefault(key, []).extend(values)
        return len(self.lists[key])

    async def llen(self, key):
        return len(self.lists.get(key, []))

    async def lrange(self, key, start, end):
        lst = self.lists.get(key, [])
        return lst[start:] if end == -1 else lst[start:end + 1]

    async def ltrim(self, key, start, end):
        lst = self.lists.get(key, [])
        self.lists[key] = lst[start:] if end == -1 else lst[start:end + 1]
        return True


def _ticket(face=10 ** 15, ratio=UINT64_MAX, nonce=7):
    packed0 = face | (nonce << 128)
    packed1 = (ratio << 161)
    return Ticket(packed0=packed0, packed1=packed1, sig_r="aa" * 32, sig_s="bb" * 32,
                  reveal="0x" + "22" * 32, token_addr=ZERO)


class ClaimQueueTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_record_carries_everything_to_rebuild_the_ticket(self):
        t = _ticket()
        rec = ClaimQueue.record_from_ticket(t, "0xFUNDER", "0xSIGNER")
        self.assertEqual(rec["packed0"], str(t.packed0))
        self.assertEqual(rec["packed1"], str(t.packed1))
        self.assertEqual(rec["sig_r"], t.sig_r)
        self.assertEqual(rec["sig_s"], t.sig_s)
        self.assertEqual(rec["reveal"], t.reveal)
        self.assertEqual(rec["token"], ZERO)
        self.assertEqual(rec["funder"], "0xFUNDER")
        self.assertEqual(rec["signer"], "0xSIGNER")
        self.assertEqual(rec["face_wei"], str(t.face_value()))
        self.assertEqual(rec["ticket_id"], t.ticket_id())
        self.assertIn("enqueued_at", rec)

    def test_enqueue_persists_fifo_and_peek_does_not_consume(self):
        async def s():
            cq = ClaimQueue(_FakeRedis())
            self.assertEqual(await cq.pending_count(), 0)
            await cq.enqueue(_ticket(face=10 ** 15, nonce=1), "0xF", "0xS")
            await cq.enqueue(_ticket(face=2 * 10 ** 15, nonce=2), "0xF", "0xS")
            self.assertEqual(await cq.pending_count(), 2)

            recs = await cq.peek()
            self.assertEqual([r["face_wei"] for r in recs],
                             [str(10 ** 15), str(2 * 10 ** 15)])   # FIFO order
            self.assertEqual(await cq.pending_count(), 2)          # peek didn't consume
            # survived JSON round-trip with big ints intact
            self.assertEqual(recs[1]["packed0"],
                             str(_ticket(face=2 * 10 ** 15, nonce=2).packed0))
        self._run(s())

    def test_peek_honours_limit(self):
        async def s():
            cq = ClaimQueue(_FakeRedis())
            for i in range(5):
                await cq.enqueue(_ticket(nonce=i), "0xF", "0xS")
            self.assertEqual(len(await cq.peek(2)), 2)
            self.assertEqual(len(await cq.peek()), 5)
        self._run(s())

    def test_remove_front_trims_fifo(self):
        async def s():
            cq = ClaimQueue(_FakeRedis())
            for i in range(4):
                await cq.enqueue(_ticket(face=(i + 1) * 10 ** 15, nonce=i), "0xF", "0xS")
            await cq.remove_front(2)
            recs = await cq.peek()
            self.assertEqual([r["face_wei"] for r in recs],
                             [str(3 * 10 ** 15), str(4 * 10 ** 15)])  # first two gone
        self._run(s())


NOW = 1000.0
ZERO_TOK = "0x0000000000000000000000000000000000000000"


def _rec(face_wei, *, enqueued_at=NOW, ticket_id="t", funder="0xFUN", signer="0xSIG"):
    return json.dumps({
        "ticket_id": ticket_id, "packed0": "1", "packed1": "2",
        "sig_r": "aa" * 32, "sig_s": "bb" * 32, "reveal": "0x" + "22" * 32,
        "token": ZERO_TOK, "funder": funder, "signer": signer,
        "face_wei": str(face_wei), "enqueued_at": enqueued_at,
    })


class _Submit:
    """Records calls; returns a tx hash, None, or raises (to drive the worker)."""
    def __init__(self, result="0xTX"):
        self.result = result
        self.calls = []

    async def __call__(self, records):
        self.calls.append(list(records))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


class _Escrow:
    def __init__(self):
        self.invalidated = []

    def invalidate(self, funder, signer, token=ZERO_TOK):
        self.invalidated.append((funder, signer, token))


class ClaimWorkerTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    async def _queue(self, *records):
        r = _FakeRedis()
        for rec in records:
            await r.rpush(PENDING_KEY, rec)
        return ClaimQueue(r)

    def _worker(self, q, submit, **kw):
        kw.setdefault("recipient_addr", "0xR")
        kw.setdefault("enabled", True)
        kw.setdefault("min_face_wei", 10 ** 18)
        return ClaimWorker(q, submit=submit, **kw)

    def test_below_threshold_and_young_does_not_submit(self):
        async def s():
            q = await self._queue(_rec(10 ** 15))           # tiny, fresh
            sub = _Submit()
            w = self._worker(q, sub, max_wait_seconds=3600)
            self.assertIsNone(await w.run_once(now=NOW + 10))
            self.assertEqual(sub.calls, [])
            self.assertEqual(await q.pending_count(), 1)     # left queued
        self._run(s())

    def test_face_threshold_triggers_and_removes_batch(self):
        async def s():
            q = await self._queue(_rec(6 * 10 ** 17, ticket_id="a"),
                                  _rec(6 * 10 ** 17, ticket_id="b"))  # sum 1.2 > 1.0
            sub = _Submit("0xTX")
            w = self._worker(q, sub)
            self.assertEqual(await w.run_once(now=NOW), "0xTX")
            self.assertEqual(len(sub.calls[0]), 2)
            self.assertEqual(await q.pending_count(), 0)     # front batch removed
        self._run(s())

    def test_age_triggers_even_below_face_threshold(self):
        async def s():
            q = await self._queue(_rec(10 ** 15, enqueued_at=NOW))   # tiny
            sub = _Submit("0xTX")
            w = self._worker(q, sub, max_wait_seconds=100)
            self.assertEqual(await w.run_once(now=NOW + 101), "0xTX")  # waited 101 > 100
            self.assertEqual(await q.pending_count(), 0)
        self._run(s())

    def test_submit_failure_leaves_queue_intact(self):
        async def s():
            q = await self._queue(_rec(2 * 10 ** 18))
            sub = _Submit(RuntimeError("rpc boom"))
            w = self._worker(q, sub)
            self.assertIsNone(await w.run_once(now=NOW))
            self.assertEqual(await q.pending_count(), 1)     # NOT removed on failure
        self._run(s())

    def test_no_txhash_leaves_queue_intact(self):
        async def s():
            q = await self._queue(_rec(2 * 10 ** 18))
            sub = _Submit(None)                              # submit returned nothing
            w = self._worker(q, sub)
            self.assertIsNone(await w.run_once(now=NOW))
            self.assertEqual(await q.pending_count(), 1)
        self._run(s())

    def test_success_invalidates_escrow_cache(self):
        async def s():
            q = await self._queue(_rec(2 * 10 ** 18, funder="0xAA", signer="0xBB"))
            esc = _Escrow()
            w = self._worker(q, _Submit("0xTX"), escrow_verifier=esc)
            await w.run_once(now=NOW)
            self.assertEqual(esc.invalidated, [("0xAA", "0xBB", ZERO_TOK)])
        self._run(s())

    def test_max_batch_limits_claim_size(self):
        async def s():
            q = await self._queue(*[_rec(2 * 10 ** 18, ticket_id=f"t{i}") for i in range(5)])
            sub = _Submit("0xTX")
            w = self._worker(q, sub, max_batch=2)
            await w.run_once(now=NOW)
            self.assertEqual(len(sub.calls[0]), 2)           # only the front 2
            self.assertEqual(await q.pending_count(), 3)     # 3 remain for next cycle
        self._run(s())

    def test_disabled_worker_does_not_start(self):
        async def s():
            q = await self._queue(_rec(2 * 10 ** 18))
            w = ClaimWorker(q, submit=_Submit(), recipient_addr="0xR", enabled=False)
            self.assertIsNone(w.start())                     # no task created
            self.assertIsNone(w._task)
        self._run(s())


if __name__ == "__main__":
    unittest.main()
