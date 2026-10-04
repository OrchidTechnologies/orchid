import datetime
from web3 import Web3
from eth_account import Account
from typing import Optional, Tuple

class TicketError(Exception):
    pass

class Ticket:
    def __init__(self,
                 packed0: int,
                 packed1: int,
                 sig_r: str,
                 sig_s: str,
                 reveal: Optional[str] = None,
                 commitment: Optional[str] = None,
                 recipient: Optional[str] = None,
                 lottery_addr: Optional[str] = None,
                 token_addr: str = "0x0000000000000000000000000000000000000000",
                 chain_id: int = 100):
        self.packed0 = packed0
        self.packed1 = packed1
        self.sig_r = sig_r
        self.sig_s = sig_s
        self.sig_v = packed1 & 1
        self.reveal = reveal
        self.commitment = commitment
        self.recipient = recipient
        self.lottery_addr = lottery_addr
        self.token_addr = token_addr
        # The chain the lottery is deployed on. It is part of the signed digest's
        # domain (the contract hashes chainid()), so it must match the deployed
        # contract or recovery yields a stranger. Lottery.chain_id is the source
        # of truth; 100 (Gnosis) is only the default.
        self.chain_id = chain_id
        self.data = b'\x00' * 32  # Fixed empty data field
        
    @classmethod
    def deserialize(cls, 
                   ticket_str: str,
                   reveal: Optional[str] = None,
                   commitment: Optional[str] = None,
                   recipient: Optional[str] = None,
                   lottery_addr: Optional[str] = None,
                   token_addr: str = "0x0000000000000000000000000000000000000000",
                   chain_id: int = 100,
                   ) -> 'Ticket':
        try:
            if len(ticket_str) != 256:  # 4 x 64 hex chars
                raise TicketError("Invalid ticket format")
                
            parts = [ticket_str[i:i+64] for i in range(0, 256, 64)]
            return cls(
                packed0=int(parts[0], 16),
                packed1=int(parts[1], 16),
                sig_r=parts[2],
                sig_s=parts[3],
                reveal=reveal,
                commitment=commitment,
                recipient=recipient,
                lottery_addr=lottery_addr,
                token_addr=token_addr,
                chain_id=chain_id,
            )
        except Exception as e:
            raise TicketError(f"Failed to deserialize ticket: {e}")
            
    def is_winner(self) -> bool:
        if not self.reveal:
            raise TicketError("No reveal value available")
            
        try:
            ratio = self.win_ratio()
            issued_nonce = (self.packed0 >> 128)
            hash_val = Web3.keccak(
                Web3.to_bytes(hexstr=self.reveal[2:]) +
                issued_nonce.to_bytes(length=16, byteorder='big')
            )
            comp = ((1 << 64) - 1) & int(hash_val.hex(), 16)
            return ratio >= comp
        except Exception as e:
            raise TicketError(f"Failed to check winning status: {e}")
            
    def face_value(self) -> int:
        return self.packed0 & ((1 << 128) - 1)

    def win_ratio(self) -> int:
        """Signed win-probability numerator: P(win) = (win_ratio + 1) / 2**64."""
        return (self.packed1 >> 161) & ((1 << 64) - 1)

    def funder(self) -> str:
        """The funder address packed into packed1[1,161) and covered by the
        signature (the digest hashes packed1>>1). This is the account whose escrow
        backs the face — keyed on-chain by keccak(token, funder, signer). It is read
        from the *signed* ticket, never taken on the client's word."""
        funder_int = (self.packed1 >> 1) & ((1 << 160) - 1)
        return Web3.to_checksum_address('0x' + format(funder_int, '040x'))

    def issued(self) -> int:
        """Unix timestamp the ticket was minted, packed0[192,256) (uint64)."""
        return self.packed0 >> 192

    def expire(self) -> int:
        """Unix time the ticket becomes worthless on-chain: issued + expire_delta,
        where expire_delta is packed1[225,256) (uint31). Mirrors the contract's
        `expire = (packed0 >> 192) + (packed1 >> 225)`."""
        return self.issued() + (self.packed1 >> 225)

    def is_expired(self, now: int) -> bool:
        """The contract treats a ticket as worthless when `expire <= now`; the
        recipient must refuse to credit such tickets — they can never be claimed."""
        return self.expire() <= now

    def expected_value(self) -> int:
        """EV in wei = face_value * P(win), fixed at signing time (both face and
        ratio are signed). This is the value actually transferred when the ticket
        is handed off — independent of whether it later resolves to a winner. The
        server books *this*; it claims face on the winners afterward purely as
        housekeeping, and over many tickets sum(claimed face) -> sum(EV)."""
        return (self.face_value() * (self.win_ratio() + 1)) >> 64

    def ticket_id(self) -> str:
        """Stable, collision-resistant identifier for double-credit detection.

        Hashes the immutable ticket payload (packed0|packed1|r|s). packed0 carries
        a random 128-bit nonce, so distinct legitimate tickets get distinct ids
        while a re-presented (replayed) ticket hashes to the same id. Independent
        of commitment/reveal (which the server supplies), so it can be computed
        before the challenge is matched. No 0x prefix (web3 7.x keccak.hex())."""
        r = self.sig_r[2:] if self.sig_r.startswith('0x') else self.sig_r
        s = self.sig_s[2:] if self.sig_s.startswith('0x') else self.sig_s
        raw = (self.packed0.to_bytes(32, 'big') + self.packed1.to_bytes(32, 'big')
               + bytes.fromhex(r) + bytes.fromhex(s))
        return Web3.keccak(raw).hex()

    def track_key(self, signer: str) -> str:
        """The contract's own replay key: keccak(digest || signer), the index into
        lottery1.sol's ``tracks_`` mapping (``tracks_[keccak256(abi.encodePacked(
        digest, signer))]``). Two tickets with the same key are the same payment
        on-chain whatever their (r, s) bytes — so THIS, not ticket_id(), is what
        the double-credit ledger must key on: a malleated signature (v flipped,
        s -> N - s) recovers to the same signer over the same digest and collides
        here while hashing to a different ticket_id. Requires the commitment to be
        set (the digest covers it). No 0x prefix, like ticket_id()."""
        return Web3.solidity_keccak(['bytes32', 'address'],
                                    [self._signing_digest(), signer]).hex()

    def _signing_digest(self) -> bytes:
        """The EIP-191 v0 (intended-validator) digest the signer committed to.
        Must mirror OrchidAccount._get_ticket_hash exactly, or recovery is wrong.

        The commitment slot is the commitment *itself* — the contract hashes
        `keccak256(abi.encodePacked(reveal))`, and the server-issued commitment IS
        keccak(reveal), so it goes in directly (NOT keccak(commitment), which would
        be a double hash and make on-chain ecrecover yield the wrong signer).

        The chain-id slot is ``self.chain_id`` (the contract hashes chainid()),
        not a hardcoded constant — a ticket is bound to one deployment."""
        if not all([self.commitment, self.recipient, self.lottery_addr]):
            raise TicketError("Missing required fields for signature verification")
        return Web3.solidity_keccak(
            ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address',
             'bytes32', 'uint256', 'uint256', 'bytes32'],
            [b'\x19', b'\x00',
             self.lottery_addr,
             self.chain_id.to_bytes(32, 'big'),
             self.token_addr,
             self.recipient,
             self.commitment,
             self.packed0,
             self.packed1 >> 1,
             self.data]
        )

    def recover_signer(self) -> str:
        """Recover the address that signed this ticket.

        The signer signs the digest RAW (the EIP-191 v0 intended-validator envelope
        is already baked into the digest preimage), exactly as the contract's
        ecrecover(digest, v, r, s) expects — so recovery hashes nothing further.
        NOTE: any well-formed (r,s) recovers to *some* address — recovery proves
        authenticity only when the result is checked against an address known to
        back the payment (the funder read from the ticket, or an escrow-funded
        signer)."""
        try:
            digest = self._signing_digest()
            return Account._recover_hash(
                digest,
                vrs=(self.sig_v + 27, int(self.sig_r, 16), int(self.sig_s, 16))
            )
        except TicketError:
            raise
        except Exception as e:
            raise TicketError(f"Failed to recover signer: {e}")

    def verify_signature(self, expected_signer: str) -> bool:
        """True iff this ticket was signed by expected_signer."""
        return self.recover_signer().lower() == expected_signer.lower()
