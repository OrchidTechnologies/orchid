from web3 import Web3
from decimal import Decimal
import secrets
from eth_account.messages import encode_defunct
from lottery import Lottery
from typing import Optional, Dict, Tuple

class OrchidAccountError(Exception):
    """Base class for Orchid account errors"""
    pass

class InvalidAddressError(OrchidAccountError):
    """Invalid Ethereum address"""
    pass

class InvalidAmountError(OrchidAccountError):
    """Invalid payment amount"""
    pass

class SigningError(OrchidAccountError):
    """Error signing transaction or message"""
    pass

class OrchidAccount:
    def __init__(self, 
                 lottery: Lottery,
                 funder_address: str,
                 private_key: str):
        try:
            self.lottery = lottery
            self.web3 = lottery.web3
            self.funder = self.web3.to_checksum_address(funder_address)
            self.key = private_key
            self.signer = self.web3.eth.account.from_key(private_key).address
        except ValueError as e:
            raise InvalidAddressError(f"Invalid address format: {e}")
        except Exception as e:
            raise OrchidAccountError(f"Failed to initialize account: {e}")

    def create_ticket(self, 
                     amount: int,
                     recipient: str,
                     commitment: str,
                     token_addr: str = "0x0000000000000000000000000000000000000000"
                     ) -> str:
        """
        Create signed nanopayment ticket
        
        Args:
            amount: Payment amount in wei
            recipient: Recipient address
            commitment: Random commitment hash
            token_addr: Token contract address
            
        Returns:
            Serialized ticket string
        """
        try:
            if amount <= 0:
                raise InvalidAmountError("Amount must be positive")
                
            recipient = self.web3.to_checksum_address(recipient)
            token_addr = self.web3.to_checksum_address(token_addr)
            
            # Random nonce
            nonce = secrets.randbits(128)
            
            # Pack ticket data
            packed0 = amount | (nonce << 128)
            ratio = 0xffffffffffffffff  # Always create winning tickets for testing
            packed1 = (ratio << 161) | (0 << 160)  # v=0
            
            # Sign ticket
            message_hash = self._get_ticket_hash(
                token_addr,
                recipient, 
                commitment,
                packed0,
                packed1
            )
            
            sig = self.web3.eth.account.sign_message(
                encode_defunct(message_hash),
                private_key=self.key
            )
            
            # Adjust v and update packed1
            v = sig.v - 27
            packed1 = packed1 | v
            
            # Format as hex strings
            return (
                hex(packed0)[2:].zfill(64) +
                hex(packed1)[2:].zfill(64) +
                hex(sig.r)[2:].zfill(64) +
                hex(sig.s)[2:].zfill(64)
            )
            
        except OrchidAccountError:
            raise
        except Exception as e:
            raise SigningError(f"Failed to create ticket: {e}")

    def _get_ticket_hash(self,
                        token_addr: str,
                        recipient: str,
                        commitment: str,
                        packed0: int,
                        packed1: int) -> bytes:
        try:
            return Web3.solidity_keccak(
                ['bytes1', 'bytes1', 'address', 'bytes32', 'address', 'address', 
                 'bytes32', 'uint256', 'uint256', 'bytes32'],
                [b'\x19', b'\x00',
                 self.lottery.contract_addr,
                 b'\x00' * 31 + b'\x64',  # Chain ID
                 token_addr,
                 recipient,
                 Web3.solidity_keccak(['bytes32'], [commitment]),
                 packed0,
                 packed1 >> 1,  # Remove v
                 b'\x00' * 32]  # Empty data field
            )
        except Exception as e:
            raise SigningError(f"Failed to create message hash: {e}")

    async def get_balance(self,
                         token_addr: str = "0x0000000000000000000000000000000000000000"
                         ) -> Tuple[float, float]:
        try:
            balance, escrow = await self.lottery.check_balance(
                token_addr,
                self.funder,
                self.signer
            )
            return (
                self.lottery.wei_to_token(balance),
                self.lottery.wei_to_token(escrow)
            )
        except Exception as e:
            raise OrchidAccountError(f"Failed to get balance: {e}")
