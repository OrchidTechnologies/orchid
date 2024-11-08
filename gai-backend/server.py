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
from payment_handler import PaymentHandler, PaymentError

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
        
    async def start_monitoring(self, client_id: str, websocket, payment_handler: PaymentHandler, commit: str):
        if client_id in self._monitors:
            await self.stop_monitoring(client_id)
            
        channel = self._get_channel(client_id)
        await self.pubsub.subscribe(channel)
        
        self._monitors[client_id] = asyncio.create_task(
            self._monitor_balance(client_id, channel, websocket, payment_handler, commit)
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
            
    async def _monitor_balance(self, client_id: str, channel: str, websocket, payment_handler: PaymentHandler, commit: str):
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
    config_manager=None
):
    print("New client connection")
    try:
        id = websocket.id
        balance_monitor = BalanceMonitor(bills.redis, bills)
        inference_url = None

        if config_manager:
            config = await config_manager.load_config()
            inference_url = config.get('inference', {}).get('api_url')
        if not inference_url:
            print("No inference URL configured")
            await websocket.close(reason='Configuration error')
            return
            
        await bills.debit(id, type='invoice')
        reveal, commit = payment_handler.new_reveal()
        await websocket.send(
            payment_handler.create_invoice(2 * await bills.min_balance(), commit)
        )
        
        await balance_monitor.start_monitoring(id, websocket, payment_handler, commit)
        
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
                        await bills.debit(id, type='auth_token')
                        print(f"Using inference URL: {inference_url}")
                        await websocket.send(json.dumps({
                            'type': 'auth_token',
                            'session_id': str(id),
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
                        amount, reveal, commit = await payment_handler.process_ticket(
                            msg['tickets'][0], reveal, commit
                        )
                        print(f'Got ticket worth {amount}')
                        await bills.credit(id, amount=amount)
                    except PaymentError as e:
                        print(f'Payment processing failed: {e}')
                        await bills.debit(id, type='error')
                        await send_error(websocket, -6001)
                        continue
                    except Exception as e:
                        print(f'Unexpected payment error: {e}')
                        await bills.debit(id, type='error')
                        await send_error(websocket, -6001)
                        continue
                        
        except websockets.exceptions.ConnectionClosed:
            print('Connection closed normally')
        except Exception as e:
            print(f"Error processing message: {e}")
            await websocket.close(reason='Internal server error')
        finally:
            await balance_monitor.stop_monitoring(id)
                
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

    print("\n*****")
    print(f"* Server starting up at {bind_addr} {bind_port}")
    print(f"* Using wallet at {payment_handler.recipient_addr}")
    print(f"* Connected to Redis at {redis_url}")
    print("******\n\n")

    async with websockets.serve(
        functools.partial(
            session,
            bills=bills,
            payment_handler=payment_handler,
            config_manager=config_manager
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

