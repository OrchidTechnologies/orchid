import web3
from decimal import Decimal
import random
from typing import Tuple, Optional
import json
import sys
import traceback
import logging

from ticket import Ticket
from lottery import Lottery

logger = logging.getLogger(__name__)

wei = pow(10, 18)

class PaymentError(Exception):
    """Base class for payment processing errors"""
    pass

class PaymentHandler:
    def __init__(self, lottery_address: str, recipient_key: str, rpc_url: str = 'https://rpc.gnosischain.com/'):
        self.lottery_address = lottery_address
        self.recipient_key = recipient_key
        self.w3 = web3.Web3(web3.Web3.HTTPProvider(rpc_url))
        self.recipient_addr = web3.Account.from_key(recipient_key).address
        self.lottery = Lottery(self.w3)
        
    def new_reveal(self) -> Tuple[str, str]:
        num = hex(random.randrange(pow(2,256)))[2:]
        reveal = '0x' + num[2:].zfill(64)
        try:
            # Using Web3's keccak instead of ethereum.utils.sha3
            reveal_bytes = bytes.fromhex(reveal[2:])
            commit = self.w3.keccak(reveal_bytes).hex()
            return reveal, commit
        except Exception as e:
            logger.error(f"Failed to generate reveal/commit pair: {e}")
            raise PaymentError("Failed to generate payment credentials")
            
    def create_invoice(self, amount: float, commit: str) -> str:
        return json.dumps({
            'type': 'invoice',
            'amount': int(wei * amount),
            'commit': '0x' + str(commit),
            'recipient': self.recipient_addr
        })
            
    async def process_ticket(self, ticket_data: str, reveal: str, commit: str) -> Tuple[float, str, str]:
        try:
            ticket = Ticket.deserialize(
                ticket_data,
                reveal=reveal,
                commitment=commit,
                recipient=self.recipient_addr,
                lottery_addr=self.lottery_address
            )
            
            if ticket.is_winner():
                logger.info(
                    f"Winner found! Face value: {ticket.face_value() / wei}, "
                    "Adding to claim queue (stubbed)"
                )

            new_reveal, new_commit = self.new_reveal()
            return ticket.face_value() / wei, new_reveal, new_commit
            
        except Exception as e:
            logger.error("Failed to process ticket")
            logger.error(traceback.format_exc())
            raise PaymentError(f"Ticket processing failed: {e}")

    async def queue_claim(self, ticket: Ticket):
        logger.info(f"Queued ticket claim for {ticket.face_value() / wei} tokens (stubbed)")
        pass
