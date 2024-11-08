import datetime
from web3 import Web3
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
            ratio = (self.packed1 >> 161) & ((1 << 64) - 1)
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

    def verify_signature(self, expected_signer: str) -> bool:
        if not all([self.commitment, self.recipient, self.lottery_addr]):
            raise TicketError("Missing required fields for signature verification")
            
        try:
            digest = Web3.solidity_keccak(
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
            
            recovered = Web3.eth.account.recover_message(
                eth_message_hash=digest,
                vrs=(self.sig_v + 27, int(self.sig_r, 16), int(self.sig_s, 16))
            )
            return recovered.lower() == expected_signer.lower()
        except Exception as e:
            raise TicketError(f"Failed to verify signature: {e}")
