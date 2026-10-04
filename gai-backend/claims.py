"""Durable winner queue for on-chain claim (Tier-1 #6b).

When ticket acceptance books a *winning* ticket (EV credited, replay-checked,
funding-verified), the ticket also carries realisable on-chain value: the
recipient can submit it to the lottery contract and collect its face. That
collection is what makes the server's books balance — over many tickets,
Σ(claimed face) → Σ(EV credited) (see DESIGN-DECISIONS D3/D6).

This module is the durable hand-off between the (latency-sensitive) acceptance
path and the (slow, batched, on-chain) claim path. The acceptor pushes a
self-contained claim record to a Redis list; the claim worker (#6b-b) drains and
submits it. Persisting to Redis means winners survive a restart instead of being
lost — today they are merely logged.

This file does NOT touch the chain. Building the claim transaction and
broadcasting it lives in the worker (#6b-b) and is gated off by default.
"""

import asyncio
import json
import logging
import time

logger = logging.getLogger(__name__)

PENDING_KEY = "billing:claims:pending"
ZERO_TOKEN = "0x0000000000000000000000000000000000000000"


class ClaimQueue:
    def __init__(self, redis, *, pending_key: str = PENDING_KEY):
        self.redis = redis
        self.pending_key = pending_key

    @staticmethod
    def record_from_ticket(ticket, funder: str, signer: str) -> dict:
        """A self-contained, JSON-serialisable claim record. Carries exactly what
        the worker needs to rebuild the ticket for `claim()` plus audit/economic
        fields. packed0/packed1 are stringified (they exceed JS-safe ints, and
        Redis stores text anyway)."""
        return {
            "ticket_id": ticket.ticket_id(),
            "packed0": str(ticket.packed0),
            "packed1": str(ticket.packed1),
            "sig_r": ticket.sig_r,
            "sig_s": ticket.sig_s,
            "reveal": ticket.reveal,
            "token": ticket.token_addr,
            "funder": funder,
            "signer": signer,
            "face_wei": str(ticket.face_value()),
            "enqueued_at": time.time(),
        }

    async def enqueue(self, ticket, funder: str, signer: str) -> dict:
        record = self.record_from_ticket(ticket, funder, signer)
        await self.redis.rpush(self.pending_key, json.dumps(record))
        logger.info("Queued winning ticket %s (face_wei=%s) for claim",
                    record["ticket_id"][:12], record["face_wei"])
        return record

    async def pending_count(self) -> int:
        return await self.redis.llen(self.pending_key)

    async def peek(self, max_n: int = -1):
        """Read pending records without removing them (the worker removes only
        what it successfully claims). max_n < 0 = all."""
        end = -1 if max_n < 0 else max_n - 1
        raw = await self.redis.lrange(self.pending_key, 0, end)
        return [json.loads(r) for r in raw]

    async def remove_front(self, n: int):
        """Drop the first n records (FIFO) — the worker calls this after a
        successful on-chain claim of exactly that front batch. LTRIM keeps the
        tail [n, end]. Safe because the only mutations are append (RPUSH) at the
        back and this single-worker trim at the front, so front indices are
        stable between peek and trim."""
        if n <= 0:
            return
        await self.redis.ltrim(self.pending_key, n, -1)


class ClaimWorker:
    """Drains the ClaimQueue and banks winning tickets on-chain in batches.

    The on-chain submission is INJECTED (``submit``), so this orchestration is
    contract-agnostic and fully unit-testable without a chain. The real broadcast
    wrapper is wired in server.py and is GATED OFF by default (``enabled=False``);
    it also stays blocked on the funder-derivation question (DESIGN-DECISIONS D6)
    until that is resolved on a testnet. While disabled, winners simply accumulate
    in the durable queue.

    Claim policy (placeholders until the real A1 win-ratio and Gnosis gas are
    known — see DESIGN-DECISIONS D6 #2): claim when the pending face value reaches
    ``min_face_wei`` OR the oldest pending winner has waited ``max_wait_seconds``
    (so small balances still get swept eventually), up to ``max_batch`` per claim.
    """

    def __init__(self, queue: "ClaimQueue", *, submit, recipient_addr,
                 token: str = ZERO_TOKEN, escrow_verifier=None, enabled: bool = False,
                 min_face_wei: int = 10 ** 18, max_wait_seconds: float = 3600.0,
                 max_batch: int = 50, poll_interval_seconds: float = 30.0):
        self.queue = queue
        self.submit = submit                 # async callable(records) -> tx_hash | None
        self.recipient_addr = recipient_addr
        self.token = token
        self.escrow_verifier = escrow_verifier
        self.enabled = enabled
        self.min_face_wei = min_face_wei
        self.max_wait_seconds = max_wait_seconds
        self.max_batch = max_batch
        self.poll_interval = poll_interval_seconds
        self._task = None

    def _should_claim(self, records, now: float) -> bool:
        if not records:
            return False
        total_face = sum(int(r["face_wei"]) for r in records)
        if total_face >= self.min_face_wei:
            return True
        oldest = min(r.get("enqueued_at", now) for r in records)
        return (now - oldest) >= self.max_wait_seconds

    async def run_once(self, now: float = None):
        """One drain attempt. Returns the tx hash if a claim was submitted and
        confirmed-as-sent, else None. Removes ONLY the front batch it successfully
        claimed; on any failure the batch stays queued for the next cycle."""
        if now is None:
            now = time.time()
        records = await self.queue.peek(self.max_batch)
        if not self._should_claim(records, now):
            return None
        try:
            tx_hash = await self.submit(records)
        except Exception as e:
            logger.error("Claim submission failed (%d tickets left queued): %s",
                         len(records), e)
            return None
        if not tx_hash:
            logger.warning("Claim submit returned no tx hash; leaving %d queued",
                           len(records))
            return None
        await self.queue.remove_front(len(records))
        logger.info("Claimed %d winning tickets in tx %s", len(records), tx_hash)
        # The claim debited each (funder, signer) escrow; drop stale cached
        # balances so the next funding check re-reads the reduced amount.
        if self.escrow_verifier is not None:
            for r in records:
                try:
                    self.escrow_verifier.invalidate(r["funder"], r["signer"], r["token"])
                except Exception:
                    pass
        return tx_hash

    async def run_forever(self):
        logger.info("ClaimWorker started (min_face_wei=%s max_wait=%ss batch=%d "
                    "poll=%ss)", self.min_face_wei, self.max_wait_seconds,
                    self.max_batch, self.poll_interval)
        while True:
            try:
                await self.run_once()
            except Exception as e:
                logger.error("ClaimWorker cycle error: %s", e)
            await asyncio.sleep(self.poll_interval)

    def start(self):
        """Start the background loop iff enabled. When disabled, log loudly that
        winners are NOT being banked (they remain durably queued)."""
        if not self.enabled:
            logger.warning(
                "ClaimWorker DISABLED — winners accumulate in '%s' but are NOT "
                "claimed on-chain (set ORCHID_GENAI_CLAIM_ENABLED to bank them)",
                self.queue.pending_key)
            return None
        if self._task is None:
            self._task = asyncio.create_task(self.run_forever())
        return self._task

    async def stop(self):
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None
