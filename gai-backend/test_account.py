"""Tests for OrchidAccount.create_ticket — the A1 real-ratio client mint.

A ticket transfers its EXPECTED value (face x win_prob) at handoff; the recipient
credits that EV and only claims winners on-chain. These tests assert the mint
hits the EV target across win probabilities, packs the win ratio correctly, stays
backward-compatible at win_prob=1.0, and that the result still verifies. No chain
(create_ticket only signs). unittest, no new deps.
"""

import unittest

from eth_account import Account
from web3 import Web3

from account import OrchidAccount, InvalidAmountError
from lottery import Lottery
from ticket import Ticket

UINT64_MAX = (1 << 64) - 1
KEY = "0x" + "11" * 32
SIGNER = Account.from_key(KEY).address
RECIPIENT = Account.from_key("0x" + "33" * 32).address

_LOTTERY = Lottery(Web3(Web3.HTTPProvider("http://127.0.0.1:1")), chain_id=100)
_ACCT = OrchidAccount(_LOTTERY, SIGNER, KEY)

_REVEAL = "0x" + "22" * 32
_COMMIT = "0x" + Web3.keccak(bytes.fromhex(_REVEAL[2:])).hex()


def _mint(amount, win_prob=1.0):
    ts = _ACCT.create_ticket(amount=amount, recipient=RECIPIENT,
                             commitment=_COMMIT, win_prob=win_prob)
    return Ticket.deserialize(ts, reveal=_REVEAL, commitment=_COMMIT,
                              recipient=RECIPIENT, lottery_addr=_LOTTERY.contract_addr)


def _mint_face(amount, face, win_prob=1.0):
    ts = _ACCT.create_ticket(amount=amount, recipient=RECIPIENT,
                             commitment=_COMMIT, face=face, win_prob=win_prob)
    return Ticket.deserialize(ts, reveal=_REVEAL, commitment=_COMMIT,
                              recipient=RECIPIENT, lottery_addr=_LOTTERY.contract_addr)


class CreateTicketTest(unittest.TestCase):

    def test_default_is_guaranteed_win_face_equals_amount(self):
        """win_prob=1.0 (default) preserves the legacy behaviour: ratio=max,
        face==amount, always a winner, EV==amount."""
        amount = 10 ** 15
        t = _mint(amount)
        self.assertEqual(t.win_ratio(), UINT64_MAX)
        self.assertEqual(t.face_value(), amount)
        self.assertTrue(t.is_winner())
        self.assertEqual(t.expected_value(), amount)
        self.assertTrue(t.verify_signature(SIGNER))

    def test_fractional_prob_scales_face_and_holds_ev(self):
        """p=0.001 -> face ~= 1000x amount, ratio ~= p*2^64, EV ~= amount."""
        amount = 10 ** 15
        p = 0.001
        t = _mint(amount, win_prob=p)
        self.assertAlmostEqual(t.face_value(), amount / p, delta=amount * 1e-6)
        self.assertAlmostEqual(t.win_ratio() / (1 << 64), p, delta=1e-9)
        self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-3)
        self.assertLess(t.face_value(), (1 << 128))      # fits uint128
        self.assertTrue(t.verify_signature(SIGNER))      # still a valid ticket

    def test_half_prob(self):
        amount = 10 ** 18
        t = _mint(amount, win_prob=0.5)
        self.assertAlmostEqual(t.face_value(), 2 * amount, delta=2)
        self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-6)

    def test_ev_is_held_across_a_range_of_probs(self):
        amount = 10 ** 16
        for p in (1.0, 0.5, 0.1, 0.01, 0.001):
            t = _mint(amount, win_prob=p)
            self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-3,
                                   msg=f"EV drifted at p={p}")

    def test_invalid_win_prob_rejected(self):
        for bad in (0, -0.1, 1.5, 2):
            with self.assertRaises(InvalidAmountError):
                _ACCT.create_ticket(amount=10 ** 15, recipient=RECIPIENT,
                                    commitment=_COMMIT, win_prob=bad)

    def test_face_overflow_rejected(self):
        """A win_prob so small that face = amount/p exceeds uint128 must be
        rejected rather than silently truncated."""
        with self.assertRaises(InvalidAmountError):
            _ACCT.create_ticket(amount=10 ** 30, recipient=RECIPIENT,
                                commitment=_COMMIT, win_prob=1e-12)

    # --- Workstream C: exact-integer face= path (client sizes face = escrow//2) ---

    def test_face_equal_amount_is_guaranteed_win(self):
        """face == amount solves to ratio = UINT64_MAX (P=1), EV == amount."""
        amount = 10 ** 15
        t = _mint_face(amount, face=amount)
        self.assertEqual(t.win_ratio(), UINT64_MAX)
        self.assertEqual(t.face_value(), amount)
        self.assertTrue(t.is_winner())
        self.assertEqual(t.expected_value(), amount)
        self.assertTrue(t.verify_signature(SIGNER))

    def test_face_double_amount_is_half_prob(self):
        """face == 2*amount -> P(win) = 1/2 exactly, EV == amount."""
        amount = 10 ** 18
        t = _mint_face(amount, face=2 * amount)
        self.assertEqual(t.face_value(), 2 * amount)
        self.assertEqual(t.win_ratio(), (1 << 63) - 1)        # ratio = 2^63 - 1 => P=1/2
        self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-9)
        self.assertTrue(t.verify_signature(SIGNER))

    def test_face_path_books_ev_at_most_amount(self):
        """The floor in ratio = (amount<<64)//face - 1 never lets the booked EV
        exceed the invoice amount (it favours the recipient), and stays ~= amount."""
        amount = 10 ** 15
        for face in (amount, 3 * amount, 7 * amount, 1000 * amount):
            t = _mint_face(amount, face=face)
            self.assertLessEqual(t.expected_value(), amount * (1 + 1e-9),
                                 msg=f"EV overshot amount at face={face}")
            self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-6,
                                   msg=f"EV drifted low at face={face}")
            self.assertTrue(t.verify_signature(SIGNER))

    def test_face_overrides_win_prob(self):
        """When face is given, win_prob is ignored — the ratio derives from face."""
        amount = 10 ** 18
        t = _mint_face(amount, face=2 * amount, win_prob=0.001)
        self.assertEqual(t.win_ratio(), (1 << 63) - 1)        # from face, not p=0.001
        self.assertAlmostEqual(t.expected_value(), amount, delta=amount * 1e-9)

    def test_face_below_amount_rejected(self):
        """face < amount can't reach EV == amount at P <= 1 -> rejected."""
        with self.assertRaises(InvalidAmountError):
            _ACCT.create_ticket(amount=10 ** 15, recipient=RECIPIENT,
                                commitment=_COMMIT, face=10 ** 15 - 1)

    def test_face_uint128_overflow_rejected(self):
        """A face exceeding uint128 must be rejected, not truncated into packed0."""
        with self.assertRaises(InvalidAmountError):
            _ACCT.create_ticket(amount=1, recipient=RECIPIENT,
                                commitment=_COMMIT, face=1 << 128)


if __name__ == "__main__":
    unittest.main()
