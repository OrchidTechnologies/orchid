"""End-to-end ticket lifecycle — composes every piece of the Tier-1 payment path
with real crypto and in-memory fakes (no chain, no network, no Redis).

  client mint (OrchidAccount, real win ratio)
    -> billing-server accept (ChallengeBook + TicketAcceptor)
       -> escrow funding check (EscrowVerifier, mocked balance)
       -> EV credited to the session balance
       -> winner enqueued (ClaimQueue)
    -> claim worker drains the queue (ClaimWorker, mocked on-chain submit)
       -> escrow cache invalidated

This is the integration safety net: the unit suites prove each component; this
proves they actually fit together. unittest, no new deps.
"""

import asyncio
import unittest

from eth_account import Account
from web3 import Web3

from account import OrchidAccount
from lottery import Lottery
from payment_handler import PaymentHandler
from ticket_acceptance import AcceptStatus, ChallengeBook, TicketAcceptor
from escrow import EscrowVerifier
from claims import ClaimQueue, ClaimWorker, PENDING_KEY
from billing import StrictRedisBilling

LOTTERY = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"
ZERO = "0x0000000000000000000000000000000000000000"

FUNDER_KEY = "0x" + "11" * 32                 # self-funded: funder == signer
FUNDER = Account.from_key(FUNDER_KEY).address
RECIPIENT_KEY = "0x" + "77" * 32


class _FakeRedis:
    """In-memory stand-in covering the kv (billing + ledger) and list (claim
    queue) ops the whole path touches."""
    def __init__(self):
        self.kv = {}
        self.lists = {}

    # kv (billing balance + double-credit ledger)
    async def ping(self):
        return True

    async def get(self, key):
        return self.kv.get(key)

    async def set(self, key, value, nx=False, ex=None):
        if nx and key in self.kv:
            return None
        self.kv[key] = value
        return True

    def pipeline(self):
        return _FakePipeline(self.kv)

    # lists (claim queue)
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


class _FakePipeline:
    """Minimal WATCH/MULTI/EXEC for StrictRedisBilling.adjust()."""
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


def _escrow_verifier(escrow_wei):
    ev = EscrowVerifier(lottery_address=LOTTERY)

    async def fake_check_balance(token, funder, signer):
        return (escrow_wei, escrow_wei)   # (balance, escrow): liquid AND collateralised

    ev.lottery.check_balance = fake_check_balance
    return ev


class _Submit:
    def __init__(self, result="0xTXHASH"):
        self.result = result
        self.calls = []

    async def __call__(self, records):
        self.calls.append(list(records))
        return self.result


class EndToEndTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def _stack(self, *, escrow_wei):
        """Wire a full billing-server stack around shared fakes."""
        redis = _FakeRedis()
        ph = PaymentHandler(LOTTERY, RECIPIENT_KEY)        # offline (no network on init)
        lottery = Lottery(Web3(Web3.HTTPProvider("http://127.0.0.1:1")), chain_id=100)
        acct = OrchidAccount(lottery, FUNDER, FUNDER_KEY)
        book = ChallengeBook(ph)
        billing = StrictRedisBilling(redis)
        escrow = _escrow_verifier(escrow_wei)
        cq = ClaimQueue(redis)
        acceptor = TicketAcceptor(
            recipient_addr=ph.recipient_addr, lottery_addr=LOTTERY, redis=redis,
            funding_verifier=escrow.check, claim_queue=cq)
        return dict(redis=redis, ph=ph, acct=acct, book=book, billing=billing,
                    escrow=escrow, cq=cq, acceptor=acceptor)

    def test_full_lifecycle_mint_credit_enqueue_claim(self):
        async def scenario():
            s = self._stack(escrow_wei=5 * 10 ** 18)       # well-funded
            amount = 10 ** 15                              # 0.001 token EV target

            # 1. server issues a challenge / invoice
            _, commit = s["book"].issue()

            # 2. client mints a winning ticket worth `amount` (p=1.0 -> always win)
            ticket_str = s["acct"].create_ticket(
                amount=amount, recipient=s["ph"].recipient_addr,
                commitment=ChallengeBook.canon(commit), win_prob=1.0)

            # 3. server accepts: authentic + funded + winner -> credit EV, enqueue
            await s["billing"].credit("sess", amount=0.0)  # ensure key exists
            result = await s["acceptor"].accept(ticket_str, book=s["book"], funder=FUNDER)
            self.assertEqual(result.status, AcceptStatus.CREDITED)
            self.assertTrue(result.is_winner)
            self.assertAlmostEqual(result.credit, amount / 10 ** 18)

            # 4. apply the credit to the session balance (as server.py does)
            await s["billing"].credit("sess", amount=result.credit)
            self.assertAlmostEqual(await s["billing"].balance("sess"), amount / 10 ** 18)

            # 5. the winner is durably queued for claim
            self.assertEqual(await s["cq"].pending_count(), 1)

            # 6. claim worker drains it, banks it (mock), invalidates escrow cache
            sub = _Submit("0xTXHASH")
            worker = ClaimWorker(s["cq"], submit=sub, recipient_addr=s["ph"].recipient_addr,
                                 escrow_verifier=s["escrow"], enabled=True, min_face_wei=1)
            tx = await worker.run_once(now=1.0)
            self.assertEqual(tx, "0xTXHASH")
            self.assertEqual(len(sub.calls[0]), 1)
            self.assertEqual(sub.calls[0][0]["funder"], FUNDER)
            self.assertEqual(await s["cq"].pending_count(), 0)   # drained
        self._run(scenario())

    def test_real_ratio_credits_expected_value(self):
        """A p<1 ticket credits ~its EV (= amount), not its (much larger) face."""
        async def scenario():
            s = self._stack(escrow_wei=10 ** 21)           # big escrow backs big face
            amount = 10 ** 15
            p = 0.01
            _, commit = s["book"].issue()
            ticket_str = s["acct"].create_ticket(
                amount=amount, recipient=s["ph"].recipient_addr,
                commitment=ChallengeBook.canon(commit), win_prob=p)
            result = await s["acceptor"].accept(ticket_str, book=s["book"], funder=FUNDER)
            self.assertEqual(result.status, AcceptStatus.CREDITED)
            self.assertAlmostEqual(result.credit, amount / 10 ** 18, delta=amount / 10 ** 18 * 1e-3)
            self.assertGreater(result.face_value, result.credit)   # face >> EV
        self._run(scenario())

    def test_unfunded_escrow_blocks_credit(self):
        """Same authentic ticket, but the escrow can't back the face -> rejected,
        nothing credited, nothing queued."""
        async def scenario():
            s = self._stack(escrow_wei=10 ** 12)           # far below a 0.001-token face
            amount = 10 ** 15
            _, commit = s["book"].issue()
            ticket_str = s["acct"].create_ticket(
                amount=amount, recipient=s["ph"].recipient_addr,
                commitment=ChallengeBook.canon(commit), win_prob=1.0)
            result = await s["acceptor"].accept(ticket_str, book=s["book"], funder=FUNDER)
            self.assertEqual(result.status, AcceptStatus.REJECTED_UNFUNDED)
            self.assertTrue(result.is_error)
            self.assertEqual(await s["cq"].pending_count(), 0)
        self._run(scenario())


if __name__ == "__main__":
    unittest.main()
