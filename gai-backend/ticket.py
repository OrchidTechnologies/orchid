import datetime
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct
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
                 token_addr: str = "0x0000000000000000000000000000000000000000"):
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
        self.data = b'\x00' * 32  # Fixed empty data field
        
    @classmethod
    def deserialize(cls, 
                   ticket_str: str,
                   reveal: Optional[str] = None,
                   commitment: Optional[str] = None,
                   recipient: Optional[str] = None,
                   lottery_addr: Optional[str] = None,
                   token_addr: str = "0x0000000000000000000000000000000000000000"
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
                token_addr=token_addr
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

    def _signing_digest(self) -> bytes:
        """The EIP-191 v0 (intended-validator) digest the signer committed to.
        Must mirror OrchidAccount._get_ticket_hash exactly, or recovery is wrong."""
        if not all([self.commitment, self.recipient, self.lottery_addr]):
            raise TicketError("Missing required fields for signature verification")
        return Web3.solidity_keccak(
            ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address',
             'bytes32', 'uint256', 'uint256', 'bytes32'],
            [b'\x19', b'\x00',
             self.lottery_addr,
             b'\x00' * 31 + b'\x64',
             self.token_addr,
             self.recipient,
             Web3.solidity_keccak(['bytes32'], [self.commitment]),
             self.packed0,
             self.packed1 >> 1,
             self.data]
        )

    def recover_signer(self) -> str:
        """Recover the address that signed this ticket.

        The signer wraps the digest with encode_defunct (personal_sign) before
        signing (see OrchidAccount.create_ticket), so recovery must do the same.
        NOTE: any well-formed (r,s) recovers to *some* address — recovery proves
        authenticity only when the result is checked against an address known to
        back the payment (the funder, or an escrow-funded signer in #6b)."""
        try:
            digest = self._signing_digest()
            return Account.recover_message(
                encode_defunct(digest),
                vrs=(self.sig_v + 27, int(self.sig_r, 16), int(self.sig_s, 16))
            )
        except TicketError:
            raise
        except Exception as e:
            raise TicketError(f"Failed to recover signer: {e}")

    def verify_signature(self, expected_signer: str) -> bool:
        """True iff this ticket was signed by expected_signer."""
        return self.recover_signer().lower() == expected_signer.lower()
