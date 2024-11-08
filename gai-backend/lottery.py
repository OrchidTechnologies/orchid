import web3
from web3 import Web3
from typing import Tuple, Optional, List
import json
from eth_abi.packed import encode_packed
from ticket import Ticket
import os

class LotteryError(Exception):
    """Raised when lottery operations fail"""
    pass

class Lottery:
    V1_ADDR = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"  # v1 on all chains
    V0_CHAIN_ID = 1
    V0_TOKEN = "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb"  # OXT
    V0_ADDR = "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1"
    
    WEI = 10**18
    UINT128_MAX = (1 << 128) - 1
    UINT64_MAX = (1 << 64) - 1

    def __init__(self, 
                 web3_provider: Web3, 
                 chain_id: int = 100,
                 addr: str = None,
                 gas_amount: int = 100000):
        self.web3 = web3_provider
        self.chain_id = chain_id
        self.contract_addr = addr or self.V1_ADDR
        self.gas_amount = gas_amount
        self.version = self._detect_version()
        self.contract = None
        self.init_contract()

    def _detect_version(self) -> int:
        """Determine if this is a v0 or v1 lottery"""
        if (self.chain_id == self.V0_CHAIN_ID and 
            self.contract_addr.lower() == self.V0_ADDR.lower()):
            return 0
        if self.contract_addr.lower() != self.V1_ADDR.lower():
            raise LotteryError(f"Unknown lottery contract address: {self.contract_addr}")
        return 1

    def init_contract(self):
        try:
            if self.version == 0:
                abi = self._load_contract_abi("lottery0.abi")
            else:
                abi = self._load_contract_abi("lottery1.abi")
            
            self.contract = self.web3.eth.contract(
                address=self.contract_addr,
                abi=abi
            )
        except Exception as e:
            raise LotteryError(f"Failed to initialize contract: {e}")

    def _load_contract_abi(self, filename: str) -> dict:
        try:
            module_dir = os.path.dirname(os.path.abspath(__file__))
            abi_path = os.path.join(module_dir, filename)
            
            with open(abi_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            raise LotteryError(f"Failed to load contract ABI from {abi_path}: {e}")

    async def check_balance(self, 
                          token_addr: str,
                          funder: str, 
                          signer: str) -> Tuple[int, int]:
        try:
            funder = self.web3.to_checksum_address(funder)
            signer = self.web3.to_checksum_address(signer)
            token_addr = self.web3.to_checksum_address(token_addr)

            if self.version == 0:
                if token_addr.lower() != self.V0_TOKEN.lower():
                    raise LotteryError("V0 lottery only supports OXT token")
                escrow_amount, unlock_warned = await self.contract.functions.look(
                    funder, 
                    signer
                ).call()
            else:
                escrow_amount, unlock_warned = await self.contract.functions.read(
                    token_addr,
                    funder,
                    signer
                ).call()
                
            balance = escrow_amount & self.UINT128_MAX
            escrow = escrow_amount >> 128
            return balance, escrow
            
        except Exception as e:
            raise LotteryError(f"Failed to check balance: {e}")

    def claim_tickets(self,
                     recipient: str,
                     tickets: List[Ticket],
                     executor_key: str,
                     token_addr: str = "0x0000000000000000000000000000000000000000"
                     ) -> str:
        try:
            recipient = self.web3.to_checksum_address(recipient)
            token_addr = self.web3.to_checksum_address(token_addr)
            
            if self.version == 0 and token_addr.lower() != self.V0_TOKEN.lower():
                raise LotteryError("V0 lottery only supports OXT token")
                
            executor_address = self.web3.eth.account.from_key(executor_key).address
            nonce = self.web3.eth.get_transaction_count(executor_address)

            prepared_tickets = [
                self._prepare_ticket(ticket, ticket.reveal) 
                for ticket in tickets
            ]

            func = self.contract.functions.claim(
                token_addr,
                recipient,
                prepared_tickets,
                []  # Empty refunds array
            )

            tx = func.build_transaction({
                'chainId': self.chain_id,
                'gas': self.gas_amount,
                'maxFeePerGas': self.web3.to_wei('100', 'gwei'),
                'maxPriorityFeePerGas': self.web3.to_wei('40', 'gwei'),
                'nonce': nonce
            })

            signed = self.web3.eth.account.sign_transaction(
                tx, 
                private_key=executor_key
            )
            tx_hash = self.web3.eth.send_raw_transaction(signed.rawTransaction)
            return tx_hash.hex()
            
        except Exception as e:
            raise LotteryError(f"Failed to claim tickets: {e}")

    def _prepare_ticket(self, ticket: Ticket, reveal: str) -> list:
        return [
            ticket.data,
            Web3.to_bytes(hexstr=reveal),
            ticket.packed0,
            ticket.packed1,
            Web3.to_bytes(hexstr=ticket.sig_r),
            Web3.to_bytes(hexstr=ticket.sig_s)
        ]

    @staticmethod
    def wei_to_token(wei_amount: int) -> float:
        return wei_amount / Lottery.WEI

    @staticmethod
    def token_to_wei(token_amount: float) -> int:
        return int(token_amount * Lottery.WEI)
