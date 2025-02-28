from redis.asyncio import Redis
import json
import requests
import copy
from typing import Dict, Any, Tuple, AsyncGenerator, Union
from datetime import datetime
import subprocess
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

from inference_models import (
    ChatCompletionRequest,
    ChatCompletion,
    ChatCompletionChunk,
    ChatChoice,
    Message,
    Usage,
    ModelInfo,
    OpenAIModel,
    OpenAIModelList,
    Tool,
    ToolChoice,
    FunctionDefinition
)
from inference_errors import (
    InferenceError,
    AuthenticationError,
    InsufficientBalanceError,
    BackendServiceError,
    ModelNotFoundError,
    ConfigurationError,
    StreamingError
)
from inference_adapters import ModelAdapter
from config_manager import ConfigManager
from billing import StrictRedisBilling
from inference_logging import configure_logging

logger = configure_logging()

TOOL_TOKENS = {
    "claude-3.5-sonnet-20241022": {
        "auto": 346,
        "tool": 313
    },
    "claude-3-opus": {
        "auto": 530,
        "tool": 281
    },
    "claude-3-sonnet": {
        "auto": 159,
        "tool": 235 
    },
    "claude-3-haiku": {
        "auto": 264,
        "tool": 340
    }
}

class InferenceAPI:
    def __init__(self, redis: Redis):
        self.redis = redis
        self.config_manager = ConfigManager(redis)
        self.billing = StrictRedisBilling(redis)
        self.mcp_session = None

    async def init(self):
        await self.billing.init()
        await self.config_manager.load_config()
        
        # Initialize tool system
        from tool_registry import ToolRegistry
        from tool_executor import ToolExecutor
        
        # Create tool registry and executor
        self.tool_registry = ToolRegistry()
        
        # Set initial tool state
        self.tools_initialized = False
        self.tools_initialization_error = None
        
        # Get configuration
        config = await self.config_manager.load_config()
        
        # Initialize basic components needed for models API to work
        self.tool_executor = ToolExecutor(self.billing, config)
        
        # Start async initialization of tool servers (non-blocking)
        import asyncio
        logger.info("Starting asynchronous tool initialization")
        asyncio.create_task(self._init_tools_async(config))
        
    async def _init_tools_async(self, config):
        """Initialize tool servers asynchronously to avoid blocking API startup"""
        try:
            # Set initialized to False at the start of initialization
            self.tools_initialized = False
            self.tools_initialization_error = None
            
            # Log key config information at debug level
            tools_config = config.get('inference', {}).get('tools', {})
            tools_enabled = tools_config.get('enabled', False)
            inject_defaults = tools_config.get('inject_defaults', False)
            
            logger.debug(f"Tools config: enabled={tools_enabled}, inject_defaults={inject_defaults}")
            
            # Connect to MCP servers for tools
            if tools_enabled:
                logger.debug("Initializing tools from configuration")
                import asyncio
                
                # Create a list to hold all server connection tasks
                server_tasks = []
                mcp_servers = tools_config.get('mcp_servers', {})
                
                # Log the number of MCP servers to be initialized
                logger.info(f"Found {len(mcp_servers)} MCP servers in configuration")
                
                # Start each MCP server connection in sequence (avoid race conditions)
                # This is a key change from the previous approach to ensure reliable initialization
                for server_id, server_config in mcp_servers.items():
                    try:
                        # Get environment variables from parent process and config
                        import os
                        
                        # Start with parent environment
                        combined_env = dict(os.environ)
                        
                        # Add config environment variables (will override parent if same keys)
                        config_env = server_config.get('env', {})
                        combined_env.update(config_env)
                        
                        # Ensure we have EXA_API_KEY if in parent environment
                        if 'EXA_API_KEY' in os.environ and ('EXA_API_KEY' not in config_env or 
                                                           'your' in config_env.get('EXA_API_KEY', '').lower()):
                            logger.info(f"Using EXA_API_KEY from parent environment for {server_id}")
                            combined_env['EXA_API_KEY'] = os.environ['EXA_API_KEY']
                        
                        # Log only critical environment variables
                        logger.debug(f"Environment for {server_id} prepared with {len(combined_env)} variables")
                        
                        server_params = StdioServerParameters(
                            command=server_config.get('command', 'node'),
                            args=server_config.get('args', []),
                            env=combined_env
                        )
                        
                        # Connect to this server directly (not as a task)
                        # This ensures servers are initialized one at a time, avoiding race conditions
                        logger.info(f"Connecting to MCP server: {server_id}")
                        connection_success = await self._connect_mcp_server(server_id, server_params)
                        
                        # Log connection status
                        if connection_success:
                            logger.info(f"Successfully connected to MCP server: {server_id}")
                        else:
                            logger.error(f"Failed to connect to MCP server: {server_id}")
                        
                        # Add a small delay between server initializations
                        await asyncio.sleep(1.0)
                        
                    except Exception as e:
                        logger.error(f"Failed to initialize MCP server {server_id}: {e}", exc_info=True)
                
                # Initialize tools from configuration with an increased timeout
                try:
                    # Add timeout for tool initialization
                    async with asyncio.timeout(30):
                        logger.debug("Starting tool registry initialization from config")
                        await self.tool_registry.init_from_config(config)
                        logger.debug("Completed tool registry initialization")
                except asyncio.TimeoutError:
                    logger.error("Timeout during tool registry initialization after 30 seconds")
                    self.tools_initialization_error = "Timeout during tool registry initialization"
                except Exception as e:
                    logger.error(f"Error during tool registry initialization: {e}", exc_info=True)
                    self.tools_initialization_error = str(e)
                
                # Log registered tools
                tools = self.tool_registry.list_tools()
                logger.debug(f"Registered tools: {tools}")
                
                if not tools:
                    logger.warning("No tools were registered! Tool injection will not work.")
                else:
                    logger.info(f"Successfully registered {len(tools)} tools: {', '.join(tools)}")
                
                # Mark tools as successfully initialized (even if there was an error)
                # This allows the server to continue operating without tools if needed
                self.tools_initialized = True
                logger.info("Tool initialization completed")
            else:
                # Tools not enabled, mark as initialized to avoid waiting
                self.tools_initialized = True
                logger.info("Tools are disabled in configuration")
        except Exception as e:
            logger.error(f"Error during async tool initialization: {e}", exc_info=True)
            self.tools_initialization_error = str(e)
            # Mark as initialized but with an error
            self.tools_initialized = True
            
    async def _connect_mcp_server(self, server_id, server_params):
        """Connect to a single MCP server using direct subprocess communication"""
        try:
            import asyncio
            import os
            from contextlib import AsyncExitStack
            
            # Detailed environment logging for debugging
            env = server_params.env or {}
            has_api_key = False
            
            # Check for API key presence - don't show the actual key
            for k, v in env.items():
                if k.upper() == 'EXA_API_KEY' and v and 'your' not in v.lower():
                    has_api_key = True
                    logger.debug(f"Found EXA_API_KEY in environment for {server_id}")
            
            if not has_api_key and server_id == 'exa-mcp':
                logger.warning(f"No valid EXA_API_KEY found for {server_id} - connection will likely fail")
                
                # Check if it's in the parent environment
                if 'EXA_API_KEY' in os.environ and 'your' not in os.environ['EXA_API_KEY'].lower():
                    logger.info(f"Found EXA_API_KEY in parent environment, will use that for {server_id}")
                    has_api_key = True
                    
                    # Make sure the environment is updated
                    if isinstance(server_params.env, dict):
                        server_params.env['EXA_API_KEY'] = os.environ['EXA_API_KEY']
                    else:
                        server_params.env = {'EXA_API_KEY': os.environ['EXA_API_KEY']}
            
            # Use the direct subprocess approach
            try:
                # Get command and args
                command = server_params.command
                args = server_params.args
                env_dict = dict(server_params.env) if server_params.env else dict(os.environ)
                
                logger.info(f"Starting MCP server {server_id} with command: {command} {' '.join(args)}")
                
                # Import our direct subprocess implementation
                from mcp_wrapper import create_mcp_server, MCPSession
                
                # Use the context manager to create and manage server process
                stack = AsyncExitStack()
                process = await stack.enter_async_context(create_mcp_server(command, args, env=env_dict))
                
                # Create and initialize session
                logger.info(f"Creating MCP session for {server_id}")
                session = await MCPSession.create(process)
                logger.info(f"Session created and initialized for {server_id}")
                
                # Test connection by listing tools
                logger.info(f"Listing tools for {server_id}")
                tools_response = await session.list_tools()
                
                if tools_response:
                    # Handle different return types from the MCPSession.list_tools method
                    if hasattr(tools_response, 'tools'):
                        # New style response (ToolsResponse object)
                        tools_list = tools_response.tools
                        tool_count = len(tools_list)
                        
                        # Log tool information
                        logger.info(f"MCP server {server_id} has {tool_count} tools available")
                        for tool in tools_list:
                            # Handle both attribute and dictionary style access
                            if hasattr(tool, 'name') and hasattr(tool, 'description'):
                                logger.info(f"Tool: {tool.name} - {tool.description}")
                            else:
                                logger.info(f"Tool: {tool.get('name')} - {tool.get('description')}")
                    
                    elif isinstance(tools_response, list):
                        # Old style response (list of dictionaries)
                        tool_count = len(tools_response)
                        
                        # Log tool information
                        logger.info(f"MCP server {server_id} has {tool_count} tools available")
                        for tool in tools_response:
                            logger.info(f"Tool: {tool.get('name')} - {tool.get('description')}")
                    
                    else:
                        # Unexpected response type
                        logger.warning(f"Unexpected tools response type: {type(tools_response)}")
                        await stack.aclose()
                        return False
                    
                    # Register the session
                    self.tool_registry.register_mcp_session(server_id, session)
                    logger.info(f"Successfully connected and registered MCP server: {server_id}")
                    
                    # Store the exit stack for proper cleanup later
                    if not hasattr(self, '_mcp_stacks'):
                        self._mcp_stacks = {}
                    self._mcp_stacks[server_id] = stack
                    
                    return True
                else:
                    logger.warning(f"No tools found for MCP server {server_id}")
                    await stack.aclose()
                    return False
                
            except Exception as e:
                logger.error(f"Error connecting to MCP server {server_id}: {e}", exc_info=True)
                return False
                
        except Exception as e:
            logger.error(f"Failed to connect to MCP server {server_id}: {e}", exc_info=True)
            return False

    async def validate_session(self, session_id: str) -> None:
        if not session_id:
            raise AuthenticationError("Missing session ID")
            
        balance = await self.billing.balance(session_id)
        if balance is None:
            raise AuthenticationError()
            
        min_balance = await self.billing.min_balance()
        if balance < min_balance:
            raise InsufficientBalanceError()

    async def get_model_config(self, model_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
        config = await self.config_manager.load_config()
        endpoints = config['inference']['endpoints']
        
        for endpoint_id, endpoint in endpoints.items():
            for model in endpoint['models']:
                if model['id'] == model_id:
                    return endpoint, model
                    
        raise ModelNotFoundError(model_id)

    def get_tool_system_tokens(self, model: str, tool_choice: Union[str, ToolChoice]) -> int:
        if model not in TOOL_TOKENS:
            return 0
            
        choice_type = tool_choice.type if isinstance(tool_choice, ToolChoice) else tool_choice
        return TOOL_TOKENS[model]["tool" if choice_type == "function" else "auto"]

    def get_token_prices(self, pricing_config: Dict[str, Any]) -> tuple[float, float]:
        pricing_type = pricing_config['type']
        
        if pricing_type == 'fixed':
            return (pricing_config['input_price'], pricing_config['output_price'])
        elif pricing_type == 'cost_plus':
            return (
                pricing_config['backend_input'] + pricing_config['input_markup'],
                pricing_config['backend_output'] + pricing_config['output_markup']
            )
        elif pricing_type == 'multiplier':
            return (
                pricing_config['backend_input'] * pricing_config['input_multiplier'],
                pricing_config['backend_output'] * pricing_config['output_multiplier']
            )
        else:
            raise ConfigurationError(f"Unknown pricing type: {pricing_type}")

    def calculate_cost(self, pricing_config: Dict[str, Any], input_tokens: int, output_tokens: int) -> float:
        input_price, output_price = self.get_token_prices(pricing_config)
        return ((input_tokens * input_price) + (output_tokens * output_price)) / 1_000_000

    def count_input_tokens(self, request: ChatCompletionRequest) -> int:
        count = sum(len(msg.content or "") // 4 for msg in request.messages)
        
        tools = request.get_effective_tools()
        if tools:
            count += sum(
                (len(tool.function.name) + 
                len(tool.function.description or "") + 
                len(str(tool.function.parameters)) // 4)
                for tool in tools
            )
            
            count += self.get_tool_system_tokens(
                request.model,
                request.get_effective_tool_choice()
            )
            
        return count

    def query_backend(self, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], 
                     request: ChatCompletionRequest) -> ChatCompletion:
        try:
            data, headers = ModelAdapter.prepare_request(endpoint_config, model_config, request)
            
            # Log the prepared request data for debugging (redact API keys)
            sanitized_headers = {k: v if k.lower() != 'authorization' and 'key' not in k.lower() else '[REDACTED]' 
                               for k, v in headers.items()}
            logger.debug(f"Backend request - URL: {endpoint_config['url']}")
            logger.debug(f"Backend request - Headers: {sanitized_headers}")
            
            # Check for tools in prepared request data
            if 'tools' in data:
                logger.debug(f"Backend request contains {len(data['tools'])} tools")
            elif request.tools:
                logger.warning("Request had tools but they were not included in backend request!")
            
            response = requests.post(
                endpoint_config['url'],
                headers=headers,
                json=data,
                timeout=(10, 90)
            )
            
            try:
                response.raise_for_status()
            except requests.exceptions.HTTPError as e:
                if response.status_code == 400:
                    error_body = response.json()
                    if 'error' in error_body and 'message' in error_body['error']:
                        raise BackendServiceError(error_body['error']['message'])
                raise BackendServiceError("Provider request failed")
            
            result = response.json()
            
            return ModelAdapter.parse_response(
                api_type=endpoint_config['api_type'],
                response=result,
                model=request.model,
                request_id=request.request_id
            )
                
        except requests.exceptions.RequestException as e:
            raise BackendServiceError()

    async def list_models(self) -> Dict[str, ModelInfo]:
        try:
            config = await self.config_manager.load_config()
            models = {}

            # Safely access endpoints if they exist
            endpoints = config.get('inference', {}).get('endpoints', {})
            if not endpoints:
                logger.warning("No endpoints found in configuration")
                return {}

            for endpoint_id, endpoint in endpoints.items():
                # Make sure the endpoint has the required fields
                if 'api_type' not in endpoint or 'models' not in endpoint:
                    logger.warning(f"Endpoint {endpoint_id} is missing required fields")
                    continue
                    
                for model in endpoint['models']:
                    if 'id' not in model:
                        logger.warning(f"Model in endpoint {endpoint_id} is missing id")
                        continue
                        
                    models[model['id']] = ModelInfo(
                        id=model['id'],
                        name=model.get('display_name', model['id']),
                        api_type=endpoint['api_type'],
                        endpoint=endpoint_id
                    )

            return models
        except Exception as e:
            logger.error(f"Error fetching models list: {e}", exc_info=True)
            return {}  # Return empty dict instead of failing

    async def list_openai_models(self) -> OpenAIModelList:
        try:
            config = await self.config_manager.load_config()
            models = []
            created = int(datetime.now().timestamp())

            # Safely access endpoints if they exist
            endpoints = config.get('inference', {}).get('endpoints', {})
            if not endpoints:
                logger.warning("No endpoints found in configuration")
                return OpenAIModelList(data=[])

            for endpoint_id, endpoint in endpoints.items():
                # Make sure the endpoint has models
                if 'models' not in endpoint:
                    logger.warning(f"Endpoint {endpoint_id} has no models")
                    continue
                    
                for model in endpoint['models']:
                    if 'id' not in model:
                        logger.warning(f"Model in endpoint {endpoint_id} is missing id")
                        continue
                        
                    models.append(OpenAIModel(
                        id=model['id'],
                        created=model.get('created', created),
                        owned_by=endpoint.get('provider', 'orchid-labs')
                    ))

            return OpenAIModelList(data=models)
        except Exception as e:
            logger.error(f"Error fetching OpenAI models list: {e}", exc_info=True)
            return OpenAIModelList(data=[])  # Return empty list instead of failing

    async def create_stream_chunks(self, completion: ChatCompletion) -> AsyncGenerator[str, None]:
        first_chunk = ChatCompletionChunk(
            id=completion.id,
            model=completion.model,
            choices=[
                ChatChoice(
                    index=0,
                    delta={"role": "assistant"},
                    finish_reason=None
                )
            ]
        )
        yield f"data: {json.dumps(first_chunk.dict(exclude_none=True))}\n\n"

        for choice in completion.choices:
            message = choice.message
            if message.tool_calls:
                for tool_call in message.tool_calls:
                    tool_chunk = ChatCompletionChunk(
                        id=completion.id,
                        model=completion.model,
                        choices=[
                            ChatChoice(
                                index=choice.index,
                                delta={"tool_calls": [tool_call]},
                                finish_reason=None
                            )
                        ]
                    )
                    yield f"data: {json.dumps(tool_chunk.dict(exclude_none=True))}\n\n"
            
            if message.content:
                # For content that was concatenated from multiple completions,
                # we split by newline and stream each part separately
                content_parts = message.content.split("\n")
                
                for part in content_parts:
                    if not part:  # Skip empty parts
                        continue
                        
                    content_chunk = ChatCompletionChunk(
                        id=completion.id,
                        model=completion.model,
                        choices=[
                            ChatChoice(
                                index=choice.index,
                                delta={"content": part + "\n"},  # Add newline to maintain formatting
                                finish_reason=None
                            )
                        ]
                    )
                    yield f"data: {json.dumps(content_chunk.dict(exclude_none=True))}\n\n"

        final_chunk = ChatCompletionChunk(
            id=completion.id,
            model=completion.model,
            choices=[
                ChatChoice(
                    index=choice.index,
                    delta={},
                    finish_reason=choice.finish_reason
                )
                for choice in completion.choices
            ]
        )
        yield f"data: {json.dumps(final_chunk.dict(exclude_none=True))}\n\n"
        yield "data: [DONE]\n\n"

    async def stream_inference(self, request: ChatCompletionRequest, session_id: str) -> AsyncGenerator[str, None]:
        try:
            completion = await self.handle_inference(request, session_id)
            async for chunk in self.create_stream_chunks(completion):
                yield chunk
        except Exception as e:
            error_payload = {
                "error": {
                    "message": str(e),
                    "type": type(e).__name__,
                }
            }
            yield f"data: {json.dumps(error_payload)}\n\n"
            yield "data: [DONE]\n\n"

    async def handle_inference(self, request: ChatCompletionRequest, session_id: str) -> ChatCompletion:
        try:
            # Add retry mechanism for tool initialization
            max_retries = 1
            retry_count = 0
            retry_delay = 0.5  # seconds
            
            while retry_count <= max_retries:
                try:
                    logger.debug(f"Starting inference handling for session {session_id}")
                    if retry_count > 0:
                        logger.info(f"Retry attempt {retry_count} for request {request.request_id}")
                    endpoint_config, model_config = await self.get_model_config(request.model)

                    # Inject tools if configured and no tools are specified
                    config = await self.config_manager.load_config()
                    logger.debug(f"Handle inference - Tools config: {json.dumps(config.get('inference', {}).get('tools', {}))}")
                    
                    tools_config = config.get('inference', {}).get('tools', {})
                    tools_enabled = tools_config.get('enabled', False)
                    inject_defaults = tools_config.get('inject_defaults', False)
                    
                    # Check if the request already has tools
                    if request.tools:
                        logger.debug(f"Request already has {len(request.tools)} tools defined, not injecting")
                    elif tools_enabled and inject_defaults:
                        # Check if tools are initialized
                        if not self.tools_initialized:
                            logger.warning("Tools are still initializing, skipping tool injection")
                            retry_count += 1
                            if retry_count <= max_retries:
                                logger.info(f"Waiting {retry_delay}s before retry {retry_count}/{max_retries}")
                                import asyncio
                                await asyncio.sleep(retry_delay)
                                continue
                            else:
                                logger.warning("Max retries reached waiting for tool initialization")
                        
                        # Check if there was an error during initialization
                        if self.tools_initialization_error:
                            logger.warning(f"Tool initialization had errors: {self.tools_initialization_error}")
                        
                        # Get available tools from registry
                        available_tools = self.tool_registry.get_available_tools()
                        logger.debug(f"Available tools count: {len(available_tools)}")
                        
                        # Log details about available tools
                        for tool in available_tools:
                            logger.debug(f"Tool to inject: {tool.function.name} - {tool.function.description}")
                            
                        if available_tools:
                            logger.debug("Injecting tools into request")
                            request.tools = available_tools
                            logger.debug(f"After injection, request has {len(request.tools)} tools")
                        else:
                            logger.warning("No tools available to inject!")
                    else:
                        logger.debug("Tool injection is disabled or not configured")

                    # Calculate and validate costs
                    input_tokens = self.count_input_tokens(request)
                    max_output_tokens = request.max_tokens or model_config.get('params', {}).get(
                        'max_tokens',
                        endpoint_config.get('params', {}).get('max_tokens', 4096)
                    )

                    max_cost = self.calculate_cost(
                        model_config['pricing'],
                        input_tokens,
                        max_output_tokens
                    )

                    logger.debug(f"Calculated max cost: {max_cost}")

                    balance = await self.billing.balance(session_id)
                    if balance < max_cost:
                        await self.redis.publish(
                            f"billing:balance:updates:{session_id}",
                            str(balance)
                        )
                        raise InsufficientBalanceError()

                    await self.billing.debit(session_id, amount=max_cost)
                    logger.debug(f"Debited {max_cost} from session {session_id}")

                    # Log the request before sending for debugging
                    if request.tools:
                        logger.debug(f"Sending request to backend with {len(request.tools)} tools")
                        for tool in request.tools:
                            logger.debug(f"Tool in request: {tool.function.name}")
                    
                    # Get initial completion which may include tool calls
                    initial_completion = self.query_backend(endpoint_config, model_config, request)
                    
                    # Check if the response includes tool calls
                    if initial_completion.choices and initial_completion.choices[0].message.tool_calls:
                        # Save the initial content from the model (may be None)
                        initial_content = initial_completion.choices[0].message.content
                        accumulated_content = [] if initial_content is None else [initial_content]
                        
                        # Clone the request for our follow-up
                        follow_up_request = copy.deepcopy(request)
                        
                        # Get the tool calls
                        tool_calls = initial_completion.choices[0].message.tool_calls

                        # Add the assistant's initial response with tool calls
                        follow_up_request.messages.append(Message(
                            role="assistant",
                            content=initial_content,
                            tool_calls=tool_calls
                        ))

                        # Process tool calls with the tool executor
                        execution_context = {
                            'request_id': request.request_id,
                            'model': request.model,
                            'endpoint': endpoint_config['api_type']
                        }
                        
                        # Execute all tools
                        tool_responses = await self.tool_executor.execute_all_tools(
                            session_id=session_id,
                            tool_calls=tool_calls,
                            context=execution_context
                        )
                        
                        # Add tool responses to the follow-up request
                        for response in tool_responses:
                            follow_up_request.messages.append(response)
                        
                        # Track completion costs for final calculation
                        total_prompt_tokens = initial_completion.usage.prompt_tokens
                        total_completion_tokens = initial_completion.usage.completion_tokens
                        
                        # Process recursive tool calls with a loop - no fixed limit
                        # as long as the user keeps paying, we'll keep processing
                        iteration = 0
                        reached_limit = False
                        max_consecutive_errors = 3  # Safety limit for errors
                        consecutive_errors = 0
                        logger.info(f"Starting recursive tool execution for request {request.request_id}")
                        
                        # Continue processing as long as errors don't exceed the threshold
                        while consecutive_errors < max_consecutive_errors:
                            try:
                                # Get next completion with tool results
                                next_completion = self.query_backend(endpoint_config, model_config, follow_up_request)
                                
                                # Add costs
                                total_prompt_tokens += next_completion.usage.prompt_tokens
                                total_completion_tokens += next_completion.usage.completion_tokens
                                
                                # Reset error counter on successful completion
                                consecutive_errors = 0
                            except Exception as e:
                                # Increment error counter and log the error
                                consecutive_errors += 1
                                logger.warning(f"Error during tool iteration {iteration+1} (error {consecutive_errors}/{max_consecutive_errors}): {e}")
                                
                                if consecutive_errors < max_consecutive_errors:
                                    continue
                                else:
                                    # We'll handle this outside the loop
                                    break
                            
                            # Check if this response includes more tool calls
                            if (next_completion.choices and next_completion.choices[0].message.tool_calls):
                                # Track the next tool calls
                                # Try to detect if we're in an infinite loop by tracking repeated identical tool calls
                                # Save any content from this response
                                content = next_completion.choices[0].message.content
                                if content:
                                    accumulated_content.append(content)
                                
                                # Get new tool calls
                                tool_calls = next_completion.choices[0].message.tool_calls
                                
                                # Add the assistant's response to the conversation
                                follow_up_request.messages.append(Message(
                                    role="assistant",
                                    content=content,
                                    tool_calls=tool_calls
                                ))
                                
                                # Execute the new tools
                                tool_responses = await self.tool_executor.execute_all_tools(
                                    session_id=session_id,
                                    tool_calls=tool_calls,
                                    context=execution_context
                                )
                                
                                # Add new tool responses
                                for response in tool_responses:
                                    follow_up_request.messages.append(response)
                                    
                                # Continue the loop
                                iteration += 1
                                logger.info(f"Completed tool iteration {iteration} for request {request.request_id}")
                            else:
                                # No more tool calls, we're done
                                # Add the final content and break the loop
                                if next_completion.choices[0].message.content:
                                    accumulated_content.append(next_completion.choices[0].message.content)
                                logger.info(f"Finished tool iterations (no more tool calls) after {iteration} iterations")
                                break
                        
                        # Handle consecutive errors - if we reached error limit
                        if consecutive_errors >= max_consecutive_errors:
                            logger.warning(f"Reached maximum consecutive errors ({max_consecutive_errors}) for request {request.request_id}")
                            # Add a user message asking for a summary of what was retrieved
                            follow_up_request.messages.append(Message(
                                role="user",
                                content="There appears to be an issue with continued tool execution. Please summarize what information you've retrieved so far."
                            ))
                            
                            # Get the final summary
                            final_summary = self.query_backend(endpoint_config, model_config, follow_up_request)
                            
                            # Add costs for the summary
                            total_prompt_tokens += final_summary.usage.prompt_tokens
                            total_completion_tokens += final_summary.usage.completion_tokens
                            
                            # Add the summary to accumulated content
                            if final_summary.choices and final_summary.choices[0].message.content:
                                logger.info(f"Received error summary of length {len(final_summary.choices[0].message.content)} for request {request.request_id}")
                                accumulated_content.append(final_summary.choices[0].message.content)
                            else:
                                logger.warning(f"Error summary has no content for request {request.request_id}")
                            
                            # Use this as our final completion
                            final_completion = final_summary
                        else:
                            logger.info(f"Tool execution completed normally after {iteration} iterations for request {request.request_id}")
                            # Create the final completion from the last completion
                            final_completion = next_completion
                        
                        # Join all accumulated content with newlines
                        final_content = "\n".join([c for c in accumulated_content if c])
                        
                        # Update the final completion's content
                        if final_completion.choices and final_completion.choices[0].message:
                            final_completion.choices[0].message.content = final_content
                        
                        # Update usage statistics
                        final_completion.usage.prompt_tokens = total_prompt_tokens
                        final_completion.usage.completion_tokens = total_completion_tokens
                        final_completion.usage.total_tokens = total_prompt_tokens + total_completion_tokens

                        return final_completion
                    
                    # If no tool calls, return the initial completion
                    return initial_completion
                
                except Exception as e:
                    retry_count += 1
                    if retry_count <= max_retries:
                        logger.warning(f"Error during inference (attempt {retry_count}/{max_retries+1}): {e}")
                        import asyncio
                        await asyncio.sleep(retry_delay)
                        continue
                    
                    logger.error(f"Error during inference: {str(e)}", exc_info=True)
                    if 'max_cost' in locals():
                        await self.billing.credit(session_id, amount=max_cost)
                    raise
            
            raise Exception("Unexpected end of retry loop in handle_inference")

        except InferenceError:
            raise
        except Exception as e:
            logger.error(f"Unexpected error in handle_inference: {str(e)}", exc_info=True)
            raise ConfigurationError(str(e))
