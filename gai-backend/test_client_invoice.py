"""Tests for the client invoice path — OrchidLLMTestClient._handle_invoice (C3).

When the server sends an invoice, the client reads the funder's on-chain
(balance, escrow), sizes the ticket face at min(escrow//2, balance) — the largest
face the recipient will honor, since it gates on 2*face <= escrow (DESIGN-DECISIONS
D10) and face <= balance (a winner is paid from balance; the contract slashes the
whole escrow if it falls short) — and mints a ticket whose booked EV equals the
invoice amount. These tests assert that sizing, the EV target, the on-chain read
is cached (~one read per TTL, not per invoice), and that an account too small to
back the invoice (thin escrow or thin balance) is rejected.

No chain/network/config: the client is built field-by-field (bypassing __init__),
the escrow read is faked, and the websocket send just captures the payload. The
ticket itself is minted by the real OrchidAccount and re-verified. unittest, no
new deps.
"""

import asyncio
import json
import logging
import unittest

from eth_account import Account
from web3 import Web3

from account import OrchidAccount, InvalidAmountError
from client import OrchidLLMTestClient
from lottery import Lottery
from ticket import Ticket

LOTTERY = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"

FUNDER_KEY = "0x" + "11" * 32                 # self-funded: funder == signer
FUNDER = Account.from_key(FUNDER_KEY).address
SIGNER = FUNDER
RECIPIENT = Account.from_key("0x" + "33" * 32).address

_REVEAL = "0x" + "22" * 32
_COMMIT = "0x" + Web3.keccak(bytes.fromhex(_REVEAL[2:])).hex()


class _FakeWS:
    """Captures every payload the client tries to send."""
    def __init__(self):
        self.sent = []

    async def send(self, payload):
        self.sent.append(payload)


def _client(escrow_wei, balance_wei=None):
    """An OrchidLLMTestClient with just the fields _handle_invoice touches, a real
    offline OrchidAccount, and a faked on-chain read returning
    ``(balance_wei, escrow_wei)``. balance defaults to escrow so the face-sizing
    tests are bounded by the collateral rule alone."""
    if balance_wei is None:
        balance_wei = escrow_wei
    lottery = Lottery(Web3(Web3.HTTPProvider("http://127.0.0.1:1")), chain_id=100)
    acct = OrchidAccount(lottery, FUNDER, FUNDER_KEY)

    reads = {"n": 0}

    async def fake_get_balance_wei(token_addr="0x0000000000000000000000000000000000000000"):
        reads["n"] += 1
        return (balance_wei, escrow_wei)        # (balance, escrow)
    acct.get_balance_wei = fake_get_balance_wei

    c = object.__new__(OrchidLLMTestClient)
    c.logger = logging.getLogger("test_client_invoice")
    c.account = acct
    c.ws = _FakeWS()
    c.debug = False
    c._funding_wei = None
    c._funding_expiry = 0.0
    return c, reads


def _sent_ticket(client):
    """Pull the single ticket out of the client's one captured payment payload."""
    msgs = [json.loads(p) for p in client.ws.sent]
    payments = [m for m in msgs if m.get("type") == "payment"]
    assert len(payments) == 1, payments
    tickets = payments[0]["tickets"]
    assert len(tickets) == 1
    return Ticket.deserialize(tickets[0], reveal=_REVEAL, commitment=_COMMIT,
                              recipient=RECIPIENT, lottery_addr=LOTTERY)


class HandleInvoiceTest(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_face_is_half_escrow_and_ev_is_amount(self):
        """face == escrow//2, and the solved ratio books EV == the invoice amount."""
        async def s():
            escrow = 10 ** 18                       # face will be 5e17
            amount = 10 ** 15
            c, _ = _client(escrow)
            await c._handle_invoice({"amount": amount, "recipient": RECIPIENT,
                                     "commit": _COMMIT})
            t = _sent_ticket(c)
            self.assertEqual(t.face_value(), escrow // 2)
            self.assertLessEqual(t.expected_value(), amount * (1 + 1e-9))
            self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-6)
            self.assertTrue(t.verify_signature(SIGNER))
        self._run(s())

    def test_amount_equal_half_escrow_is_guaranteed_win(self):
        """When the invoice EV equals escrow//2, face==amount -> P=1 (always win)."""
        async def s():
            escrow = 2 * 10 ** 15
            amount = 10 ** 15                        # == escrow//2
            c, _ = _client(escrow)
            await c._handle_invoice({"amount": amount, "recipient": RECIPIENT,
                                     "commit": _COMMIT})
            t = _sent_ticket(c)
            self.assertEqual(t.face_value(), amount)
            self.assertTrue(t.is_winner())
            self.assertEqual(t.expected_value(), amount)
        self._run(s())

    def test_escrow_read_is_cached_across_invoices(self):
        """Two invoices in one session -> one on-chain escrow read (TTL cache)."""
        async def s():
            c, reads = _client(10 ** 18)
            amount = 10 ** 15
            for _ in range(3):
                await c._handle_invoice({"amount": amount, "recipient": RECIPIENT,
                                         "commit": _COMMIT})
            self.assertEqual(reads["n"], 1)
            self.assertEqual(len(c.ws.sent), 3)     # all three still paid
        self._run(s())

    def test_underfunded_escrow_is_rejected_and_nothing_sent(self):
        """escrow < 2*amount -> face=escrow//2 < amount, unreachable EV: reject,
        send nothing (the funder must add collateral)."""
        async def s():
            c, _ = _client(2 * 10 ** 15 - 2)        # escrow//2 = 1e15 - 1 < amount
            amount = 10 ** 15
            with self.assertRaises(InvalidAmountError):
                await c._handle_invoice({"amount": amount, "recipient": RECIPIENT,
                                         "commit": _COMMIT})
            self.assertEqual(c.ws.sent, [])
        self._run(s())

    def test_face_is_capped_by_spendable_balance(self):
        """balance < escrow//2 -> face == balance. A face above the balance would
        have the contract pay a winner only the balance and zero our whole escrow."""
        async def s():
            escrow = 10 ** 18                       # escrow//2 = 5e17 ...
            balance = 3 * 10 ** 17                  # ... but only 3e17 is liquid
            c, _ = _client(escrow, balance_wei=balance)
            amount = 10 ** 17
            await c._handle_invoice({"amount": amount, "recipient": RECIPIENT,
                                     "commit": _COMMIT})
            t = _sent_ticket(c)
            self.assertEqual(t.face_value(), balance)
            self.assertLessEqual(t.expected_value(), amount)
        self._run(s())

    def test_thin_balance_is_rejected_and_nothing_sent(self):
        """balance < amount -> no honorable face can reach the invoiced EV: reject,
        send nothing (the funder must deposit, not just add collateral)."""
        async def s():
            c, _ = _client(10 ** 18, balance_wei=10 ** 15 - 1)
            with self.assertRaises(InvalidAmountError):
                await c._handle_invoice({"amount": 10 ** 15, "recipient": RECIPIENT,
                                         "commit": _COMMIT})
            self.assertEqual(c.ws.sent, [])
        self._run(s())


if __name__ == "__main__":
    unittest.main()
