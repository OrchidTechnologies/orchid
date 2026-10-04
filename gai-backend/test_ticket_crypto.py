"""Cross-check the ticket crypto against the lottery1.sol contract ground truth.

The danger with a hand-rolled signing digest is that the mint and the verify can
*agree with each other* while both disagreeing with the contract — self-consistent
but on-chain-worthless (exactly the bug this rework fixes). So this suite does NOT
reuse Ticket._signing_digest as its oracle. It independently rebuilds the contract's
digest from raw concatenated bytes following claim_() in lottery1.sol:

    expire   = (packed0 >> 192) + (packed1 >> 225)
    winner  iff ratio >= uint64(keccak(reveal, uint128(packed0 >> 128)))
    digest   = keccak(0x19, 0x00, this, chainid, token, recipient,
                      keccak(reveal), packed0, packed1>>1, data)
    signer   = ecrecover(digest, (packed1 & 1) + 27, r, s)
    funder   = address(packed1 >> 1)

and asserts our minted ticket matches at every layer: digest, recovered signer,
funder/issued/expire bit fields, and the winner predicate. unittest, no chain.
"""

import unittest

from eth_account import Account
from web3 import Web3

from account import OrchidAccount, DEFAULT_EXPIRE_SECONDS
from lottery import Lottery
from ticket import Ticket

CHAIN_ID = 100
TOKEN = "0x0000000000000000000000000000000000000000"
KEY = "0x" + "11" * 32
SIGNER = Account.from_key(KEY).address
RECIPIENT = Account.from_key("0x" + "33" * 32).address
REVEAL = "0x" + "22" * 32
COMMIT = "0x" + Web3.keccak(bytes.fromhex(REVEAL[2:])).hex()
ISSUED = 1_700_000_000

_LOTTERY = Lottery(Web3(Web3.HTTPProvider("http://127.0.0.1:1")), chain_id=CHAIN_ID)
LOTTERY_ADDR = _LOTTERY.contract_addr


def _addr_bytes(a: str) -> bytes:
    return bytes.fromhex(a[2:] if a.startswith("0x") else a)


def _contract_digest(t: Ticket) -> bytes:
    """Rebuild lottery1.sol's claim_() digest from first principles (no reuse of
    Ticket._signing_digest), via abi.encodePacked semantics = byte concatenation."""
    preimage = (
        b"\x19" + b"\x00"
        + _addr_bytes(LOTTERY_ADDR)                       # this (20)
        + CHAIN_ID.to_bytes(32, "big")                    # chainid as bytes32
        + _addr_bytes(TOKEN)                              # token (20)
        + _addr_bytes(RECIPIENT)                          # recipient (20)
        + Web3.keccak(_addr_bytes(REVEAL))                # keccak(reveal) == commitment (32)
        + t.packed0.to_bytes(32, "big")                   # packed0
        + (t.packed1 >> 1).to_bytes(32, "big")            # packed1 >> 1 (drops v)
        + b"\x00" * 32                                     # data
    )
    return Web3.keccak(preimage)


def _contract_winner(t: Ticket) -> bool:
    ratio = t.packed1 >> 161 & ((1 << 64) - 1)
    preimage = _addr_bytes(REVEAL) + ((t.packed0 >> 128) & ((1 << 128) - 1)).to_bytes(16, "big")
    threshold = int(Web3.keccak(preimage).hex(), 16) & ((1 << 64) - 1)
    return ratio >= threshold


def _mint(*, funder_key=KEY, win_prob=1.0, issued=ISSUED):
    funder = Account.from_key(funder_key).address
    acct = OrchidAccount(_LOTTERY, funder, funder_key)
    ts = acct.create_ticket(amount=10 ** 15, recipient=RECIPIENT, commitment=COMMIT,
                            win_prob=win_prob, issued=issued)
    return Ticket.deserialize(ts, reveal=REVEAL, commitment=COMMIT,
                              recipient=RECIPIENT, lottery_addr=LOTTERY_ADDR)


class TicketCryptoTest(unittest.TestCase):

    def test_digest_matches_contract_formula(self):
        """Our signing digest equals the independently-rebuilt contract digest."""
        t = _mint()
        self.assertEqual(t._signing_digest(), _contract_digest(t))

    def test_signer_recovers_from_contract_digest(self):
        """ecrecover over the contract digest yields the minting signer — i.e. an
        on-chain claim would attribute this ticket to the right signer."""
        t = _mint()
        recovered = Account._recover_hash(
            _contract_digest(t), vrs=(t.sig_v + 27, int(t.sig_r, 16), int(t.sig_s, 16)))
        self.assertEqual(recovered, SIGNER)
        self.assertTrue(t.verify_signature(SIGNER))

    def test_funder_is_packed_and_readable(self):
        """The funder address lives in packed1[1,161) and reads back intact —
        not zero (the old bug that sent claims to a nonexistent account)."""
        t = _mint()
        self.assertEqual(t.funder(), SIGNER)            # self-funded vector
        self.assertNotEqual(int(t.funder(), 16), 0)

    def test_delegated_funder_differs_from_signer(self):
        """A signer distinct from the funder still packs the funder verbatim, and
        the signature recovers to the signer (supports delegated signing)."""
        funder = Account.from_key("0x" + "11" * 32).address
        signer_key = "0x" + "44" * 32
        signer = Account.from_key(signer_key).address
        acct = OrchidAccount(_LOTTERY, funder, signer_key)   # funder != signer
        ts = acct.create_ticket(amount=10 ** 15, recipient=RECIPIENT,
                                commitment=COMMIT, issued=ISSUED)
        t = Ticket.deserialize(ts, reveal=REVEAL, commitment=COMMIT,
                               recipient=RECIPIENT, lottery_addr=LOTTERY_ADDR)
        self.assertEqual(t.funder(), funder)
        self.assertEqual(t.recover_signer(), signer)
        self.assertNotEqual(t.funder(), t.recover_signer())

    def test_issued_and_expire_bitfields(self):
        t = _mint(issued=ISSUED)
        self.assertEqual(t.issued(), ISSUED)
        self.assertEqual(t.expire(), ISSUED + DEFAULT_EXPIRE_SECONDS)
        self.assertFalse(t.is_expired(ISSUED + 10))
        self.assertTrue(t.is_expired(ISSUED + DEFAULT_EXPIRE_SECONDS))
        self.assertTrue(t.is_expired(ISSUED + DEFAULT_EXPIRE_SECONDS + 1))

    def test_winner_predicate_matches_contract(self):
        """Ticket.is_winner agrees with the contract's threshold computation, for
        both a guaranteed win and a fractional-probability ticket."""
        for p in (1.0, 0.5, 0.1):
            t = _mint(win_prob=p)
            self.assertEqual(t.is_winner(), _contract_winner(t), msg=f"p={p}")

    def test_expire_delta_clamped_to_uint31(self):
        funder = SIGNER
        acct = OrchidAccount(_LOTTERY, funder, KEY)
        ts = acct.create_ticket(amount=10 ** 15, recipient=RECIPIENT, commitment=COMMIT,
                                expire_delta_seconds=1 << 40, issued=ISSUED)  # huge
        t = Ticket.deserialize(ts, reveal=REVEAL, commitment=COMMIT,
                               recipient=RECIPIENT, lottery_addr=LOTTERY_ADDR)
        self.assertEqual(t.expire() - t.issued(), (1 << 31) - 1)


if __name__ == "__main__":
    unittest.main()
