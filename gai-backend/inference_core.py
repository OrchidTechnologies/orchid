from redis.asyncio import Redis
import json
import requests
from typing import Dict, Any, Tuple, AsyncGenerator, Union
from datetime import datetime

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
    ToolChoice
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

    async def init(self):
        await self.billing.init()
        await self.config_manager.load_config()

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
        config = await self.config_manager.load_config()
        models = {}

        for endpoint_id, endpoint in config['inference']['endpoints'].items():
            for model in endpoint['models']:
                models[model['id']] = ModelInfo(
                    id=model['id'],
                    name=model.get('display_name', model['id']),
                    api_type=endpoint['api_type'],
                    endpoint=endpoint_id
                )

        return models

    async def list_openai_models(self) -> OpenAIModelList:
        config = await self.config_manager.load_config()
        models = []
        created = int(datetime.now().timestamp())

        for endpoint_id, endpoint in config['inference']['endpoints'].items():
            for model in endpoint['models']:
                models.append(OpenAIModel(
                    id=model['id'],
                    created=model.get('created', created),
                    owned_by=endpoint.get('provider', 'orchid-labs')
                ))

        return OpenAIModelList(data=models)

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
                content_chunk = ChatCompletionChunk(
                    id=completion.id,
                    model=completion.model,
                    choices=[
                        ChatChoice(
                            index=choice.index,
                            delta={"content": message.content},
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
            logger.debug(f"Starting inference handling for session {session_id}")
            endpoint_config, model_config = await self.get_model_config(request.model)
            logger.debug(f"Retrieved model config for {request.model}")
            
            tools = request.get_effective_tools()
            if tools and len(tools) > 128:
                raise ValidationError("Maximum of 128 tools allowed")
            
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
            
            try:
                logger.debug("Querying backend API")
                result = self.query_backend(endpoint_config, model_config, request)
                logger.debug(f"Received backend response: {result.dict(exclude_none=True)}")
                
                actual_cost = self.calculate_cost(
                    model_config['pricing'],
                    result.usage.prompt_tokens,
                    result.usage.completion_tokens
                )
                
                if actual_cost < max_cost:
                    refund = max_cost - actual_cost
                    await self.billing.credit(session_id, amount=refund)
                    logger.debug(f"Credited refund of {refund} to session {session_id}")
                
                return result
                
            except Exception as e:
                logger.error(f"Error during backend query: {str(e)}", exc_info=True)
                await self.billing.credit(session_id, amount=max_cost)
                raise
                
        except InferenceError:
            raise
        except Exception as e:
            logger.error(f"Unexpected error in handle_inference: {str(e)}", exc_info=True)
            raise ConfigurationError(str(e))
