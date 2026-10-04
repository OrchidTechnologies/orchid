import asyncio
import websockets
import functools
import json
import hashlib
import random
from redis.asyncio import Redis
import redis
from decimal import Decimal
import uuid
import time
import os
import sys
import traceback
from typing import Optional, Dict

import billing
from config_manager import ConfigManager, ConfigError
from payment_handler import PaymentHandler
from ticket_acceptance import ChallengeBook, TicketAcceptor
from escrow import EscrowVerifier
from claims import ClaimQueue, ClaimWorker
from ticket import Ticket

# Configuration
LOTTERY_ADDRESS = '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'
disconnect_threshold = -25

async def send_error(ws, code):
    await ws.send(json.dumps({'type': 'error', 'code': code}))

class BalanceMonitor:
    def __init__(self, redis: Redis, bills: billing.StrictRedisBilling):
        self.redis = redis
        self.bills = bills
        self._monitors = {}
        self.pubsub = self.redis.pubsub()
        
    def _get_channel(self, client_id: str) -> str:
        return f"billing:balance:updates:{client_id}"
        
    async def start_monitoring(self, client_id: str, websocket, payment_handler: PaymentHandler, book: ChallengeBook):
        if client_id in self._monitors:
            await self.stop_monitoring(client_id)

        channel = self._get_channel(client_id)
        await self.pubsub.subscribe(channel)

        self._monitors[client_id] = asyncio.create_task(
            self._monitor_balance(client_id, channel, websocket, payment_handler, book)
        )
        
    async def stop_monitoring(self, client_id: str):
        if client_id in self._monitors:
            channel = self._get_channel(client_id)
            await self.pubsub.unsubscribe(channel)
            self._monitors[client_id].cancel()
            try:
                await self._monitors[client_id]
            except asyncio.CancelledError:
                pass
            del self._monitors[client_id]
            
    async def _monitor_balance(self, client_id: str, channel: str, websocket, payment_handler: PaymentHandler, book: ChallengeBook):
        try:
            last_invoice_time = 0
            MIN_INVOICE_INTERVAL = 1.0  # Minimum seconds between invoices
            
            while True:
                message = await self.pubsub.get_message(ignore_subscribe_messages=True)
                if message is None:
                    await asyncio.sleep(0.01)
                    continue
                    
                try:
                    # Wait for in-flight payments to process
                    await asyncio.sleep(0.1)
                    
                    current_time = time.time()
                    if current_time - last_invoice_time < MIN_INVOICE_INTERVAL:
                        continue
                        
                    balance = await self.bills.balance(client_id)
                    min_balance = await self.bills.min_balance()
                    
                    if balance < min_balance:
                        await self.bills.debit(client_id, type='invoice')
                        invoice_amount = 2 * min_balance - balance
                        _, commit = book.issue()
                        await websocket.send(
                            payment_handler.create_invoice(invoice_amount, commit)
                        )
                        last_invoice_time = current_time
                        
                except Exception as e:
                    print(f"Error processing balance update for {client_id}: {e}")
                    
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"Balance monitor error for {client_id}: {e}")

async def session(
    websocket,
    bills=None,
    payment_handler=None,
    config_manager=None,
    escrow_verifier=None,
    claim_queue=None
):
    print("New client connection")
    try:
        # The session identity is the per-connection UUID the websockets library
        # assigns. It is the billing key (Redis `billing:balance:<session_id>`), the
        # balance-update pubsub channel, AND the bearer token handed to the client in
        # `auth_token` — so paying on THIS socket funds exactly the session the client
        # later authenticates the inference HTTP API with. Stringify it once here and
        # use that single value everywhere; downstream layers all call it `session_id`
        # (see docs/BYOC-PROTOCOL.md). (Previously this was the raw UUID named `id`,
        # which shadowed the builtin and only matched the string key by f-string luck.)
        session_id = str(websocket.id)
        balance_monitor = BalanceMonitor(bills.redis, bills)
        book = ChallengeBook(payment_handler)
        acceptor = TicketAcceptor(
            recipient_addr=payment_handler.recipient_addr,
            lottery_addr=LOTTERY_ADDRESS,
            chain_id=payment_handler.lottery.chain_id,
            redis=bills.redis,
            funding_verifier=(escrow_verifier.check if escrow_verifier else None),
            claim_queue=claim_queue,
        )
        session_state = {'funder': None}
        inference_url = None

        if config_manager:
            config = await config_manager.load_config()
            
            # First check top-level api_url (new format)
            inference_url = config.get('api_url')
            
            # Fall back to inference.api_url for backward compatibility
            if not inference_url:
                inference_url = config.get('inference', {}).get('api_url')
            
            # Check if tools are enabled - could be at top level or in inference section
            tools_section = config.get('tools', config.get('inference', {}).get('tools', {}))
            tools_enabled = tools_section.get('enabled', False)
            
            if not inference_url:
                print("No inference API URL configured")
                await websocket.close(reason='Missing required api_url')
                return
                
            # Detect tools-only mode
            has_endpoints = bool(config.get('inference', {}).get('endpoints'))
            if tools_enabled and (not has_endpoints or not config.get('inference', {}).get('endpoints')):
                print(f"Running in tools-only mode with API URL: {inference_url}")
        else:
            # No config manager means we can't proceed
            print("No configuration manager available")
            await websocket.close(reason='Configuration error')
            return
            
        await bills.debit(session_id, type='invoice')
        _, commit = book.issue()
        await websocket.send(
            payment_handler.create_invoice(2 * await bills.min_balance(), commit)
        )

        await balance_monitor.start_monitoring(session_id, websocket, payment_handler, book)
        
        try:
            while True:
                message = await websocket.recv()
                try:
                    msg = json.loads(message)
                except json.JSONDecodeError:
                    print(f"Failed to parse message: {message}")
                    continue

                if msg['type'] == 'request_token':
                    try:
                        # Advisory only: the authoritative funder is signed into
                        # each ticket (packed1) and read there by the acceptor. We
                        # keep the declared orchid_account as a cross-check so a
                        # client/funder mismatch can be logged, not trusted.
                        funder_addr = msg.get('orchid_account')
                        if funder_addr:
                            session_state['funder'] = funder_addr
                        await bills.debit(session_id, type='auth_token')
                        print(f"Using inference URL: {inference_url}")
                        await websocket.send(json.dumps({
                            'type': 'auth_token',
                            'session_id': session_id,
                            'inference_url': inference_url
                        }))
                    except billing.BillingError as e:
                        print(f"Auth token billing failed: {e}")
                        await send_error(websocket, -6002)
                        continue
                    except Exception as e:
                        print(f"Auth token error: {e}")
                        await send_error(websocket, -6002)
                        continue

                elif msg['type'] == 'payment':
                    try:
                        tickets = msg.get('tickets') or []
                        if not tickets:
                            await send_error(websocket, -6001)
                            continue
                        # funder= is the advisory declared account; the acceptor
                        # reads the authoritative funder from the signed ticket.
                        result = await acceptor.accept(
                            tickets[0], book=book, funder=session_state['funder']
                        )
                        if result.is_credited:
                            # Credit the EV transferred at handoff. Winner-ness is
                            # incidental to the books — it only decides whether the
                            # ticket is later claimed on-chain (#6b).
                            await bills.credit(session_id, amount=result.credit)
                            tag = "winner" if result.is_winner else "miss"
                            print(f"Credited ticket {result.ticket_id[:12]} "
                                  f"EV {result.credit} ({tag})")
                        elif result.is_error:
                            print(f"Rejected ticket: {result.status.value} — {result.detail}")
                            await bills.debit(session_id, type='error')
                            await send_error(websocket, -6001)
                        else:
                            # No-fault non-credit (e.g. escrow RPC unavailable):
                            # neither credit nor penalise; the client retries on
                            # the next invoice.
                            print(f"Ticket not credited (no fault): "
                                  f"{result.status.value} — {result.detail}")
                    except Exception as e:
                        print(f'Unexpected payment error: {e}')
                        await bills.debit(session_id, type='error')
                        await send_error(websocket, -6001)
                        continue
                        
        except websockets.exceptions.ConnectionClosed:
            print('Connection closed normally')
        except Exception as e:
            print(f"Error processing message: {e}")
            await websocket.close(reason='Internal server error')
        finally:
            await balance_monitor.stop_monitoring(session_id)
                
    except Exception as e:
        print(f"Fatal error in session: {e}")
        await websocket.close(reason='Internal server error')

async def main(bind_addr, bind_port, recipient_key, redis_url, config_path: Optional[str] = None):
    redis = Redis.from_url(redis_url, decode_responses=True)

    try:
        config_manager = ConfigManager(redis)
        config = await config_manager.load_config(config_path)
    except ConfigError as e:
        print(f"Configuration error: {e}")
        return
    except Exception as e:
        print(f"Unexpected error loading config: {e}")
        return

    try:
        bills = billing.StrictRedisBilling(redis)
        await bills.init()
    except billing.BillingError as e:
        print(f"Billing initialization error: {e}")
        return
    except Exception as e:
        print(f"Unexpected error initializing billing: {e}")
        return

    payment_handler = PaymentHandler(LOTTERY_ADDRESS, recipient_key)

    rpc_url = os.environ.get('ORCHID_GENAI_RPC_URL', 'https://rpc.gnosischain.com/')
    escrow_verifier = EscrowVerifier(lottery_address=LOTTERY_ADDRESS, rpc_url=rpc_url)
    claim_queue = ClaimQueue(redis)

    # Claim worker: drains queued winners and banks them on-chain. GATED OFF by
    # default — broadcasting real claim() transactions requires opting in AND
    # resolving the funder-derivation question (DESIGN-DECISIONS D6). While off,
    # winners accumulate durably in Redis but are not claimed.
    claim_enabled = os.environ.get('ORCHID_GENAI_CLAIM_ENABLED', '').lower() in ('1', 'true', 'yes')

    async def submit_claims(records):
        # Rebuild the signed tickets and submit one on-chain claim() for the front
        # batch. claim_tickets uses PaymentHandler's sync web3, so run it off the
        # event loop. All records share one token (native xDAI here).
        tickets = [
            Ticket(packed0=int(r["packed0"]), packed1=int(r["packed1"]),
                   sig_r=r["sig_r"], sig_s=r["sig_s"], reveal=r["reveal"],
                   token_addr=r["token"], chain_id=payment_handler.lottery.chain_id)
            for r in records
        ]
        token = records[0]["token"]
        return await asyncio.to_thread(
            payment_handler.lottery.claim_tickets,
            payment_handler.recipient_addr, tickets, recipient_key, token)

    claim_worker = ClaimWorker(
        claim_queue, submit=submit_claims,
        recipient_addr=payment_handler.recipient_addr,
        escrow_verifier=escrow_verifier, enabled=claim_enabled)

    print("\n*****")
    print(f"* Server starting up at {bind_addr} {bind_port}")
    print(f"* Using wallet at {payment_handler.recipient_addr}")
    print(f"* Connected to Redis at {redis_url}")
    print(f"* Verifying escrow against {rpc_url}")
    print(f"* On-chain claim worker: {'ENABLED' if claim_enabled else 'disabled (winners queued only)'}")
    print("******\n\n")

    claim_worker.start()

    async with websockets.serve(
        functools.partial(
            session,
            bills=bills,
            payment_handler=payment_handler,
            config_manager=config_manager,
            escrow_verifier=escrow_verifier,
            claim_queue=claim_queue
        ),
        bind_addr,
        bind_port
    ):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Start the billing server')
    parser.add_argument('--config', type=str, help='Path to config file (optional)')

    args = parser.parse_args()

    required_env = {
        'ORCHID_GENAI_ADDR': "Bind address",
        'ORCHID_GENAI_PORT': "Bind port",
        'ORCHID_GENAI_RECIPIENT_KEY': "Recipient key",
        'ORCHID_GENAI_REDIS_URL': "Redis connection URL",
    }

    # Check required environment variables
    missing = [name for name in required_env if name not in os.environ]
    if missing:
        print("Missing required environment variables:")
        for name in missing:
            print(f"  {name}: {required_env[name]}")
        sys.exit(1)

    bind_addr = os.environ['ORCHID_GENAI_ADDR']
    bind_port = os.environ['ORCHID_GENAI_PORT']
    recipient_key = os.environ['ORCHID_GENAI_RECIPIENT_KEY']
    redis_url = os.environ['ORCHID_GENAI_REDIS_URL']

    asyncio.run(main(bind_addr, bind_port, recipient_key, redis_url, args.config))

