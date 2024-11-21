import asyncio
import json
import logging
import os
import secrets
from dataclasses import dataclass
from typing import Dict, Optional, Tuple, List
from web3 import Web3
import websockets
import aiohttp
import time

from account import OrchidAccount
from lottery import Lottery
from ticket import Ticket

@dataclass
class InferenceConfig:
    provider: str
    funder: Optional[str] = None
    secret: Optional[str] = None
    chainid: Optional[int] = None
    currency: Optional[str] = None
    rpc: Optional[str] = None

@dataclass
class ProviderLocation:
    billing_url: str

@dataclass
class LocationConfig:
    providers: Dict[str, ProviderLocation]
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'LocationConfig':
        providers = {
            k: ProviderLocation(**v) for k, v in data.items()
        }
        return cls(providers=providers)

@dataclass
class Message:
    role: str
    content: str
    name: Optional[str] = None

@dataclass
class TestConfig:
    messages: List[Message]
    model: str
    params: Dict
    retry_delay: float = 1.5

    @classmethod
    def from_dict(cls, data: Dict) -> 'TestConfig':
        messages = []
        if 'prompt' in data:
            messages = [Message(role="user", content=data['prompt'])]
        elif 'messages' in data:
            messages = [Message(**msg) for msg in data['messages']]
        else:
            raise ValueError("Config must contain either 'prompt' or 'messages'")
            
        return cls(
            messages=messages,
            model=data['model'],
            params=data.get('params', {}),
            retry_delay=data.get('retry_delay', 1.5)
        )

@dataclass
class LoggingConfig:
    level: str
    file: Optional[str]

@dataclass
class ClientConfig:
    inference: InferenceConfig
    location: LocationConfig
    test: TestConfig
    logging: LoggingConfig
    
    @classmethod
    def from_file(cls, config_path: str) -> 'ClientConfig':
        with open(config_path) as f:
            data = json.load(f)
            
        # Make inference config fields optional
        inference_data = data.get('inference', {})
        if not isinstance(inference_data, dict):
            inference_data = {}
            
        return cls(
            inference=InferenceConfig(**inference_data),
            location=LocationConfig.from_dict(data['location']),
            test=TestConfig.from_dict(data['test']),
            logging=LoggingConfig(**data['logging'])
        )

class OrchidLLMTestClient:
    def __init__(self, config_path: str, wallet_only: bool = False, inference_only: bool = False, 
                 inference_url: Optional[str] = None, auth_key: Optional[str] = None, 
                 prompt: Optional[str] = None):
        self.config = ClientConfig.from_file(config_path)
        if prompt:
            self.config.test.messages = [Message(role="user", content=prompt)]
            
        self._setup_logging()
        self.logger = logging.getLogger(__name__)
        
        self.wallet_only = wallet_only
        self.inference_only = inference_only
        self.cli_inference_url = inference_url
        self.cli_auth_key = auth_key
        
        if not inference_only:
            if not self.config.inference.rpc:
                raise Exception("RPC URL required in config for wallet mode")
            if not self.config.inference.chainid:
                raise Exception("Chain ID required in config for wallet mode")
            if not self.config.inference.funder:
                raise Exception("Funder address required in config for wallet mode")
            if not self.config.inference.secret:
                raise Exception("Secret required in config for wallet mode")
                
            self.web3 = Web3(Web3.HTTPProvider(self.config.inference.rpc))
            self.lottery = Lottery(
                self.web3,
                chain_id=self.config.inference.chainid
            )
            self.account = OrchidAccount(
                self.lottery,
                self.config.inference.funder,
                self.config.inference.secret
            )
        
        self.ws = None
        self.session_id = None
        self.inference_url = None
        self.message_queue = asyncio.Queue()
        self._handler_task = None

    def _setup_logging(self):
        logging.basicConfig(
            level=getattr(logging, self.config.logging.level.upper()),
            filename=self.config.logging.file,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )

    async def _handle_invoice(self, invoice_data: Dict) -> None:
        try:
            amount = int(invoice_data['amount'])
            recipient = invoice_data['recipient']
            commit = invoice_data['commit']
            
            self.logger.info(f"Received invoice for {amount/1e18} tokens")
            
            # Create and send ticket immediately
            ticket_str = self.account.create_ticket(
                amount=amount,
                recipient=recipient,
                commitment=commit
            )
            
            payment = {
                'type': 'payment',
                'tickets': [ticket_str]
            }
            await self.ws.send(json.dumps(payment))
            self.logger.info(f"Sent payment ticket")
            
        except Exception as e:
            self.logger.error(f"Failed to handle invoice: {e}")
            raise

    async def _billing_handler(self) -> None:
        try:
            async for message in self.ws:
                msg = json.loads(message)
                self.logger.debug(f"Received WS message: {msg['type']}")
                
                if msg['type'] == 'invoice':
                    # Handle invoice immediately
                    await self._handle_invoice(msg)
                elif msg['type'] == 'auth_token':
                    self.session_id = msg['session_id']
                    self.inference_url = msg['inference_url']
                    if self.wallet_only:
                        print(f"\nAuth Token: {self.session_id}")
                        print(f"Inference URL: {self.inference_url}")
                        print("\nWallet is active and handling payments. Press Ctrl+C to exit.")
                    else:
                        await self.message_queue.put(('auth_received', self.session_id))
                elif msg['type'] == 'error':
                    self.logger.error(f"Received error: {msg['code']}")
                    await self.message_queue.put(('error', msg['code']))

        except websockets.exceptions.ConnectionClosed:
            self.logger.info("Billing WebSocket closed")
        except Exception as e:
            self.logger.error(f"Billing handler error: {e}")
            await self.message_queue.put(('error', str(e)))

    async def connect(self) -> None:
        if self.inference_only:
            if self.cli_auth_key:
                self.session_id = self.cli_auth_key
            else:
                self.session_id = self.config.test.params.get('session_id')
                if not self.session_id:
                    raise Exception("session_id required either in config or via --key parameter")
            
            if self.cli_inference_url:
                self.inference_url = self.cli_inference_url
            else:
                self.inference_url = self.config.test.params.get('inference_url')
                if not self.inference_url:
                    raise Exception("inference_url required either in config or via --url parameter")
            return

        try:
            provider = self.config.inference.provider
            provider_config = self.config.location.providers.get(provider)
            if not provider_config:
                raise Exception(f"No configuration found for provider: {provider}")
                
            self.logger.info(f"Connecting to provider {provider} at {provider_config.billing_url}")
            self.ws = await websockets.connect(provider_config.billing_url)
            
            self._handler_task = asyncio.create_task(self._billing_handler())
            
            await self.ws.send(json.dumps({
                'type': 'request_token',
                'orchid_account': self.config.inference.funder
            }))
            
            if not self.wallet_only:
                msg_type, session_id = await self.message_queue.get()
                if msg_type != 'auth_received':
                    raise Exception(f"Authentication failed: {session_id}")
                    
                self.logger.info("Successfully authenticated")
            
        except Exception as e:
            self.logger.error(f"Connection failed: {e}")
            raise

    async def run_wallet(self) -> None:
        """Keep the wallet running and handling payments"""
        try:
            while True:
                await asyncio.sleep(3600)
        except asyncio.CancelledError:
            self.logger.info("Wallet operation cancelled")
            raise

    async def send_inference_request(self, retry_count: int = 0) -> Dict:
        if not self.session_id:
            raise Exception("Not authenticated")
        
        if not self.inference_url:
            raise Exception("No inference URL received")
            
        try:
            async with aiohttp.ClientSession() as session:
                self.logger.debug(f"Using session ID: {self.session_id}")
                headers = {
                    'Authorization': f'Bearer {self.session_id}',
                    'Content-Type': 'application/json'
                }
                
                data = {
                    'messages': [
                        {
                            'role': msg.role,
                            'content': msg.content,
                            **(({'name': msg.name} if msg.name else {}))
                        }
                        for msg in self.config.test.messages
                    ],
                    'model': self.config.test.model,
                    'params': self.config.test.params
                }
                
                self.logger.info(f"Sending inference request (attempt {retry_count + 1})")
                self.logger.debug(f"Request URL: {self.inference_url}")
                self.logger.debug(f"Request data: {data}")
                
                async with session.post(
                    self.inference_url,
                    headers=headers,
                    json=data,
                    timeout=30
                ) as response:
                    if response.status == 402:
                        if self.inference_only:
                            raise Exception("Insufficient balance and unable to pay in inference-only mode")
                        retry_delay = self.config.test.retry_delay
                        self.logger.info(f"Insufficient balance, waiting {retry_delay}s for payment processing...")
                        await asyncio.sleep(retry_delay)
                        return await self.send_inference_request(retry_count + 1)
                    elif response.status == 401:
                        error_text = await response.text()
                        self.logger.error(f"Authentication failed: {error_text}")
                        raise Exception(f"Authentication failed: {error_text}")
                    elif response.status != 200:
                        error_text = await response.text()
                        self.logger.error(f"Inference request failed (status {response.status}): {error_text}")
                        raise Exception(f"Inference request failed: {error_text}")
                        
                    result = await response.json()
                    self.logger.info(f"Inference complete: {result['usage']} tokens used")
                    return result
                    
        except Exception as e:
            self.logger.error(f"Inference request failed: {e}")
            raise

    async def close(self) -> None:
        if self.ws:
            try:
                await self.ws.close()
                self.logger.info("Connection closed")
            except Exception as e:
                self.logger.error(f"Error closing connection: {e}")
                
        if self._handler_task:
            self._handler_task.cancel()
            try:
                await self._handler_task
            except asyncio.CancelledError:
                pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()

async def main(config_path: str, wallet_only: bool = False, inference_only: bool = False,
               inference_url: Optional[str] = None, auth_key: Optional[str] = None,
               prompt: Optional[str] = None):
    async with OrchidLLMTestClient(
        config_path, 
        wallet_only, 
        inference_only,
        inference_url,
        auth_key,
        prompt
    ) as client:
        try:
            await client.connect()
            if wallet_only:
                await client.run_wallet()
            elif not wallet_only:
                result = await client.send_inference_request()
                print("\nInference Results:")
                messages = client.config.test.messages
                print(f"Messages:")
                for msg in messages:
                    print(f"  {msg.role}: {msg.content}")
                print(f"Response: {result['response']}")
                print(f"Usage: {json.dumps(result['usage'], indent=2)}")
            
        except Exception as e:
            print(f"Test failed: {e}")
            raise

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("config", help="Path to config file")
    parser.add_argument("--wallet", action="store_true", help="Run in wallet-only mode")
    parser.add_argument("--inference", action="store_true", help="Run in inference-only mode")
    parser.add_argument("--url", help="Override inference URL from config")
    parser.add_argument("--key", help="Override auth key from config")
    parser.add_argument("prompt", nargs="*", help="Optional prompt to override config")
    args = parser.parse_args()
    
    if args.wallet and args.inference:
        print("Cannot specify both --wallet and --inference")
        exit(1)
        
    if (args.url and not args.key) or (args.key and not args.url):
        print("Must specify both --url and --key together")
        exit(1)
    
    prompt = " ".join(args.prompt) if args.prompt else None
    asyncio.run(main(
        args.config,
        args.wallet,
        args.inference,
        args.url,
        args.key,
        prompt
    ))
