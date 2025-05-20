import asyncio
import json
import logging
import os
import secrets
from dataclasses import dataclass, field
from typing import Dict, Optional, Tuple, List, Any, Union
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
    tools_url: Optional[str] = None  # New field for Tool Node Protocol

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

# Models for Tool Node Protocol
@dataclass
class ToolParameter:
    """Parameter definition for a tool."""
    type: str
    description: Optional[str] = None
    enum: Optional[List[str]] = None
    items: Optional[Dict[str, Any]] = None
    properties: Optional[Dict[str, Dict[str, Any]]] = None
    required: Optional[List[str]] = None

@dataclass
class ToolDefinition:
    """Definition of a tool provided by a tool node."""
    name: str
    description: Optional[str] = None
    parameters: Dict[str, Any] = field(default_factory=dict)
    
@dataclass
class ListToolsResponse:
    """Response from a /v1/tools/list request."""
    tools: List[ToolDefinition]
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'ListToolsResponse':
        tools = [ToolDefinition(**tool) for tool in data.get('tools', [])]
        return cls(tools=tools)

@dataclass
class ToolCallRequest:
    """Request to execute a tool with arguments."""
    name: str
    arguments: Dict[str, Any]
    
@dataclass
class ContentItem:
    """Content item in a tool call response."""
    type: str  # Currently only 'text' is supported
    text: str
    
@dataclass
class ToolCallResponse:
    """Response from a /v1/tools/call request."""
    content: List[ContentItem]
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'ToolCallResponse':
        content = [ContentItem(**item) for item in data.get('content', [])]
        return cls(content=content)
    
    def get_text(self) -> str:
        """Get the text content from the response."""
        return "\n".join([item.text for item in self.content if item.type == "text"])

class ToolNodeClient:
    """Client for communicating with Tool Node Protocol servers."""
    
    def __init__(self, provider_name: str, tools_url: str, session_id: str, logger: logging.Logger):
        """
        Initialize a Tool Node client.
        
        Args:
            provider_name: Name of the provider
            tools_url: Base URL for the tools API
            session_id: Session ID for authentication
            logger: Logger instance
        """
        self.provider_name = provider_name
        self.tools_url = tools_url.rstrip('/')
        self.session_id = session_id
        self.logger = logger
        self.available_tools = []
        
    async def list_tools(self) -> List[ToolDefinition]:
        """List available tools from the provider."""
        try:
            # Ensure the base URL has the correct format
            base_url = self.tools_url.rstrip('/')
            
            # Try different URL formats in case the server has different path structures
            urls_to_try = [
                f"{base_url}/v1/tools/list",         # Standard path
                f"{base_url}/tools/list",            # Without v1
                f"{base_url}/list"                   # Minimal path
            ]
            
            headers = {
                'Authorization': f'Bearer {self.session_id}',
                'Content-Type': 'application/json'
            }
            
            # Try each URL until one works
            last_error = None
            for url in urls_to_try:
                try:
                    self.logger.debug(f"Trying to list tools from {self.provider_name} at {url}")
                    async with aiohttp.ClientSession() as session:
                        async with session.post(url, headers=headers) as response:
                            if response.status == 401:
                                error_text = await response.text()
                                self.logger.error(f"Authentication failed when listing tools: {error_text}")
                                raise Exception(f"Authentication failed: {error_text}")
                            elif response.status != 200:
                                error_text = await response.text()
                                self.logger.error(f"Failed to list tools at {url} (status {response.status}): {error_text}")
                                last_error = f"HTTP {response.status}: {error_text}"
                                # Continue to the next URL to try
                                continue
                            
                            # Success!
                            result = await response.json()
                            response_obj = ListToolsResponse.from_dict(result)
                            self.available_tools = response_obj.tools
                            
                            self.logger.info(f"Got {len(self.available_tools)} tools from {self.provider_name}")
                            return self.available_tools
                except Exception as e:
                    self.logger.error(f"Error trying URL {url}: {e}")
                    last_error = str(e)
                    # Continue to the next URL
            
            # If we get here, all URLs failed
            raise Exception(f"Failed to list tools from any URL. Last error: {last_error}")
                    
        except Exception as e:
            self.logger.error(f"Error listing tools from {self.provider_name}: {e}")
            raise
            
    async def call_tool(self, tool_name: str, arguments: Dict[str, Any]) -> str:
        """
        Call a tool with the given arguments.
        
        Args:
            tool_name: Name of the tool to call
            arguments: Arguments to pass to the tool
            
        Returns:
            The tool's response as a string
        """
        try:
            # Ensure the base URL has the correct format
            base_url = self.tools_url.rstrip('/')
            
            # Try different URL formats in case the server has different path structures
            urls_to_try = [
                f"{base_url}/v1/tools/call",         # Standard path
                f"{base_url}/tools/call",            # Without v1
                f"{base_url}/call"                   # Minimal path
            ]
            
            headers = {
                'Authorization': f'Bearer {self.session_id}',
                'Content-Type': 'application/json'
            }
            
            data = ToolCallRequest(
                name=tool_name,
                arguments=arguments
            )
            
            # Try each URL until one works
            last_error = None
            for url in urls_to_try:
                try:
                    self.logger.debug(f"Calling tool {tool_name} from {self.provider_name} at {url}")
                    async with aiohttp.ClientSession() as session:
                        async with session.post(
                            url, 
                            headers=headers, 
                            json=data.__dict__,
                            timeout=30
                        ) as response:
                            if response.status == 402:
                                self.logger.error("Insufficient balance for tool execution")
                                raise Exception("Insufficient balance for tool execution")
                            elif response.status == 401:
                                error_text = await response.text()
                                self.logger.error(f"Authentication failed: {error_text}")
                                raise Exception(f"Authentication failed: {error_text}")
                            elif response.status != 200:
                                error_text = await response.text()
                                self.logger.error(f"Tool call failed at {url} (status {response.status}): {error_text}")
                                last_error = f"HTTP {response.status}: {error_text}"
                                # Continue to the next URL to try
                                continue
                            
                            # Success!
                            result = await response.json()
                            response_obj = ToolCallResponse.from_dict(result)
                            return response_obj.get_text()
                except Exception as e:
                    self.logger.error(f"Error trying URL {url}: {e}")
                    last_error = str(e)
                    # Continue to the next URL
            
            # If we get here, all URLs failed
            raise Exception(f"Failed to call tool from any URL. Last error: {last_error}")
                    
        except Exception as e:
            self.logger.error(f"Error calling tool {tool_name} from {self.provider_name}: {e}")
            raise

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
        
        # Initialize tool clients dictionary
        self.tool_clients = {}

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
            
            # Initialize tool clients if tools_url is provided in the params
            if self.config.test.params.get('tools_url'):
                provider = self.config.inference.provider
                tools_url = self.config.test.params.get('tools_url')
                self.logger.info(f"Setting up tool client for {provider} at {tools_url}")
                
                self.tool_clients[provider] = ToolNodeClient(
                    provider_name=provider,
                    tools_url=tools_url,
                    session_id=self.session_id,
                    logger=self.logger
                )
            
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
                
                # Initialize tool clients if tools_url is provided in the provider config
                if provider_config.tools_url:
                    self.logger.info(f"Setting up tool client for {provider} at {provider_config.tools_url}")
                    
                    self.tool_clients[provider] = ToolNodeClient(
                        provider_name=provider,
                        tools_url=provider_config.tools_url,
                        session_id=self.session_id,
                        logger=self.logger
                    )
            
        except Exception as e:
            self.logger.error(f"Connection failed: {e}")
            raise
            
    async def list_provider_tools(self, provider: Optional[str] = None) -> Dict[str, List[ToolDefinition]]:
        """
        List available tools from the specified provider or all providers.
        
        Args:
            provider: Name of the provider to query, or None for all providers
            
        Returns:
            Dictionary mapping provider names to lists of tools
        """
        results = {}
        
        try:
            if provider:
                if provider not in self.tool_clients:
                    raise Exception(f"No tool client available for provider: {provider}")
                    
                client = self.tool_clients[provider]
                tools = await client.list_tools()
                results[provider] = tools
            else:
                # Query all providers
                for provider_name, client in self.tool_clients.items():
                    try:
                        tools = await client.list_tools()
                        results[provider_name] = tools
                    except Exception as e:
                        self.logger.error(f"Error listing tools from {provider_name}: {e}")
                        results[provider_name] = []
                        
            return results
            
        except Exception as e:
            self.logger.error(f"Error listing tools: {e}")
            raise
            
    async def call_tool(self, provider: str, tool_name: str, arguments: Dict[str, Any]) -> str:
        """
        Call a tool from the specified provider.
        
        Args:
            provider: Name of the provider with the tool
            tool_name: Name of the tool to call
            arguments: Arguments to pass to the tool
            
        Returns:
            The tool's response as a string
        """
        if provider not in self.tool_clients:
            raise Exception(f"No tool client available for provider: {provider}")
            
        client = self.tool_clients[provider]
        return await client.call_tool(tool_name, arguments)

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
               cmd_providers: List[str] = None, auth_key: Optional[str] = None,
               prompt: Optional[str] = None, 
               list_tools: bool = False, 
               tool_name: Optional[str] = None, tool_args: Optional[str] = None):
    """
    Run the client with the specified options.
    
    Args:
        config_path: Path to the configuration file
        wallet_only: Run in wallet-only mode
        inference_only: Run in inference-only mode
        cmd_providers: List of provider URLs to connect to from command line
        auth_key: Authentication key
        prompt: User prompt for inference
        list_tools: Whether to list available tools
        tool_name: Name of the tool to call
        tool_args: Arguments for the tool
    """
    # First, load the config to get configured providers
    with open(config_path) as f:
        config_data = json.load(f)
    
    # Get providers from config
    config_providers = {}
    if 'location' in config_data and 'providers' in config_data['location']:
        config_providers = config_data['location']['providers']
    
    # Determine which providers to use
    providers_to_connect = []
    
    # Add providers from command line
    if cmd_providers:
        for url in cmd_providers:
            providers_to_connect.append({
                'name': f"cmdline_{len(providers_to_connect)}",
                'url': url
            })
    
    # Add providers from config if not in inference_only mode
    if not inference_only and config_providers:
        for name, details in config_providers.items():
            if 'billing_url' in details:
                providers_to_connect.append({
                    'name': name,
                    'url': details['billing_url'],
                    'config': details
                })
    
    if not providers_to_connect:
        print("Error: No providers specified. Use --providers or define providers in config.")
        return
        
    print(f"Will connect to {len(providers_to_connect)} providers")
    
    # Use the first provider for the main client connection
    main_provider = providers_to_connect[0]
    client = OrchidLLMTestClient(
        config_path, 
        wallet_only, 
        inference_only,
        main_provider['url'] if inference_only else None,  # Use URL directly only in inference_only mode
        auth_key,
        prompt
    )
    
    try:
        # For inference_only mode with auth_key, we don't need to connect to billing
        if inference_only and auth_key:
            client.session_id = auth_key
            
            # Check if we need to set up tool clients
            if list_tools or tool_name:
                for provider in providers_to_connect:
                    provider_name = provider['name']
                    billing_url = provider['url']
                    
                    # Determine the tools URL
                    tools_url = None
                    if 'config' in provider and 'tools_url' in provider['config']:
                        tools_url = provider['config']['tools_url']
                    else:
                        # Convert billing URL to inferred tools URL
                        tools_url = billing_url.replace("ws://", "http://").replace(":8060", ":8086")
                        
                    # Ensure the URL doesn't have "/v1/tools" in it already - will be added by ToolNodeClient
                    if tools_url.endswith("/v1/tools"):
                        tools_url = tools_url[:-9]  # Remove "/v1/tools"
                        
                    print(f"Setting up tool client for {provider_name} at {tools_url}")
                    client.tool_clients[provider_name] = ToolNodeClient(
                        provider_name=provider_name,
                        tools_url=tools_url,
                        session_id=client.session_id,
                        logger=client.logger
                    )
        else:
            # Connect to each provider's billing WebSocket for authentication
            for provider in providers_to_connect:
                provider_name = provider['name']
                billing_url = provider['url']
                
                print(f"Connecting to provider {provider_name} at {billing_url}")
                
                # Create a dedicated client for each provider
                provider_client = OrchidLLMTestClient(
                    config_path,
                    False,  # Not wallet_only
                    False,  # Not inference_only
                    None,   # No URL override
                    None,   # No key override
                    None    # No prompt
                )
                
                # Manually set the provider to connect to
                provider_client.config.inference.provider = provider_name
                
                # Create a custom location config with just this provider
                provider_client.config.location.providers = {
                    provider_name: ProviderLocation(billing_url=billing_url)
                }
                
                # Connect to get authentication token
                try:
                    await provider_client.connect()
                    
                    # Store the session information
                    if provider is main_provider:
                        # This is our main provider, copy session info to main client
                        client.session_id = provider_client.session_id
                        client.inference_url = provider_client.inference_url
                    
                    # Set up tool client if needed
                    if list_tools or tool_name:
                        # Determine the tools URL
                        tools_url = None
                        if 'config' in provider and 'tools_url' in provider['config']:
                            tools_url = provider['config']['tools_url']
                        else:
                            # Convert billing URL to inferred tools URL or use the inference URL's host
                            base_url = provider_client.inference_url
                            if base_url and "://" in base_url:
                                # Use the same host as inference but different path
                                host_part = base_url.split("/v1")[0] if "/v1" in base_url else base_url
                                tools_url = f"{host_part}"  # Base URL without path
                            else:
                                # Fallback to pattern-based URL conversion
                                tools_url = billing_url.replace("ws://", "http://").replace(":8060", ":8086")
                        
                        print(f"Setting up tool client for {provider_name} at {tools_url}")
                        client.tool_clients[provider_name] = ToolNodeClient(
                            provider_name=provider_name,
                            tools_url=tools_url,
                            session_id=provider_client.session_id,  # Use provider's own session
                            logger=client.logger
                        )
                    
                    # Close the provider's connection if not the main provider
                    if provider is not main_provider:
                        await provider_client.close()
                    
                except Exception as e:
                    print(f"Failed to connect to provider {provider_name}: {e}")
                    await provider_client.close()
            
            # Verify we have a session for the main client
            if not client.session_id:
                print("Failed to authenticate with main provider")
                return
        
        # Load available tools for each provider
        for provider_name, tool_client in client.tool_clients.items():
            try:
                await tool_client.list_tools()
                print(f"Discovered {len(tool_client.available_tools)} tools from provider {provider_name}")
            except Exception as e:
                print(f"Warning: Failed to load tools from provider {provider_name}: {e}")
        
        # Handle tool-related commands
        if list_tools:
            # List available tools from all providers
            tools_by_provider = await client.list_provider_tools()
            
            if not tools_by_provider:
                print("No tools available or no tool providers configured.")
                return
                
            for provider_name, tools in tools_by_provider.items():
                print(f"\nTools from provider {provider_name} ({len(tools)} tools):")
                for tool in tools:
                    print(f"  {tool.name}: {tool.description or 'No description'}")
                    params = tool.parameters.get('properties', {})
                    if params:
                        print(f"    Parameters:")
                        for param_name, param_props in params.items():
                            required = "required" if param_name in tool.parameters.get('required', []) else "optional"
                            param_type = param_props.get('type', 'any')
                            desc = param_props.get('description', 'No description')
                            print(f"      {param_name} ({param_type}, {required}): {desc}")
                    print()
        
        elif tool_name:
            # Call a specific tool
            if not tool_args:
                print(f"Error: Must provide tool arguments when calling a tool")
                return
                
            try:
                args_dict = json.loads(tool_args)
            except json.JSONDecodeError:
                print(f"Error: Tool arguments must be valid JSON")
                return
            
            # Find which provider has this tool
            provider_with_tool = None
            for provider_name, tool_client in client.tool_clients.items():
                for tool in tool_client.available_tools:
                    if tool.name == tool_name:
                        provider_with_tool = provider_name
                        break
                if provider_with_tool:
                    break
            
            if not provider_with_tool:
                print(f"Error: Tool '{tool_name}' not found in any provider")
                return
                
            print(f"Calling tool {tool_name} from provider {provider_with_tool} with arguments: {tool_args}")
            result = await client.call_tool(provider_with_tool, tool_name, args_dict)
            print(f"\nTool Result:\n{result}")
        
        elif wallet_only:
            await client.run_wallet()
        
        elif not wallet_only and not list_tools and not tool_name:
            # Run inference
            result = await client.send_inference_request()
            print("\nInference Results:")
            messages = client.config.test.messages
            print(f"Messages:")
            for msg in messages:
                print(f"  {msg.role}: {msg.content}")
            print(f"Response: {result['response']}")
            print(f"Usage: {json.dumps(result['usage'], indent=2)}")
            
    except Exception as e:
        print(f"Operation failed: {e}")
        raise
    finally:
        await client.close()

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("config", help="Path to config file")
    
    # Mode arguments
    mode_group = parser.add_argument_group("Mode options")
    mode_group.add_argument("--wallet", action="store_true", help="Run in wallet-only mode")
    mode_group.add_argument("--inference", action="store_true", help="Run in inference-only mode")
    
    # Provider and authentication options
    provider_group = parser.add_argument_group("Provider options")
    provider_group.add_argument("--providers", nargs="+", help="List of provider URLs to connect to")
    provider_group.add_argument("--key", help="Authentication key")
    
    # Inference options
    inference_group = parser.add_argument_group("Inference options")
    inference_group.add_argument("prompt", nargs="*", help="Optional prompt to override config")
    
    # Tool options
    tool_group = parser.add_argument_group("Tool options")
    tool_group.add_argument("--list-tools", action="store_true", help="List available tools from all providers")
    tool_group.add_argument("--tool-name", help="Name of the tool to call")
    tool_group.add_argument("--tool-args", help="JSON-formatted arguments for the tool")
    
    args = parser.parse_args()
    
    # Validate argument combinations
    if args.wallet and args.inference:
        print("Error: Cannot specify both --wallet and --inference")
        exit(1)
        
    # Providers in config are used by default, so this is just a warning not an error
    if not args.providers and (args.list_tools or args.tool_name):
        print("Warning: No providers specified with --providers, will use providers from config file")
    
    if args.tool_name and not args.tool_args:
        print("Error: Must provide --tool-args when specifying --tool-name")
        exit(1)
    
    prompt = " ".join(args.prompt) if args.prompt else None
    asyncio.run(main(
        args.config,
        args.wallet,
        args.inference,
        args.providers,
        args.key,
        prompt,
        args.list_tools,
        args.tool_name,
        args.tool_args
    ))
