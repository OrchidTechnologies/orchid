from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from redis.asyncio import Redis
from typing import Dict, Any, AsyncGenerator
import os
import json
import requests
import logging
from datetime import datetime
import uuid

from config_manager import ConfigManager
from billing import StrictRedisBilling, BillingError
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
    InferenceAPIError
)
from inference_adapters import ModelAdapter

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await api.init()
    yield
    # Shutdown (if needed)
    await redis.close()

app = FastAPI(lifespan=lifespan)
security = HTTPBearer()
logger = logging.getLogger(__name__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class InferenceAPI:
    def __init__(self, redis: Redis):
        self.redis = redis
        self.config_manager = ConfigManager(redis)
        self.billing = StrictRedisBilling(redis)
        
    async def init(self):
        await self.billing.init()
        await self.config_manager.load_config()

    async def validate_session(self, credentials: HTTPAuthorizationCredentials) -> str:
        if not credentials:
            raise InferenceAPIError(401, "Missing session ID")
            
        session_id = credentials.credentials
        
        try:
            balance = await self.billing.balance(session_id)
            
            if balance is None:
                raise InferenceAPIError(401, "Invalid session")
                
            min_balance = await self.billing.min_balance()
            
            if balance < min_balance:
                raise InferenceAPIError(402, "Insufficient balance")
                
            return session_id
            
        except BillingError as e:
            raise InferenceAPIError(500, "Internal service error")
            
        except Exception as e:
            raise InferenceAPIError(500, f"Internal service error: {e}")

    async def get_model_config(self, model_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
        config = await self.config_manager.load_config()
        endpoints = config['inference']['endpoints']
        
        for endpoint_id, endpoint in endpoints.items():
            for model in endpoint['models']:
                if model['id'] == model_id:
                    return endpoint, model
                    
        raise InferenceAPIError(400, f"Unknown model: {model_id}")

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
            raise InferenceAPIError(500, f"Unknown pricing type: {pricing_type}")

    def calculate_cost(self, pricing_config: Dict[str, Any], input_tokens: int, output_tokens: int) -> float:
        input_price, output_price = self.get_token_prices(pricing_config)
        return ((input_tokens * input_price) + (output_tokens * output_price)) / 1_000_000

    def estimate_max_cost(self, pricing_config: Dict[str, Any], input_tokens: int, max_output_tokens: int) -> float:
        return self.calculate_cost(pricing_config, input_tokens, max_output_tokens)
        
    def count_input_tokens(self, request: ChatCompletionRequest) -> int:
        return sum(len(msg.content or "") // 4 for msg in request.messages)

    def query_backend(self, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], request: ChatCompletionRequest) -> ChatCompletion:
        try:
            data, headers = ModelAdapter.prepare_request(endpoint_config, model_config, request)
            
            response = requests.post(
                endpoint_config['url'],
                headers=headers,
                json=data,
                timeout=30
            )
            
            try:
                response.raise_for_status()
            except requests.exceptions.HTTPError as e:
                if response.status_code == 400 and endpoint_config['api_type'] == 'openrouter':
                    error_body = response.json()
                    if 'error' in error_body and 'message' in error_body['error']:
                        raise InferenceAPIError(400, error_body['error']['message'])
                raise
            
            result = response.json()
            
            completion = ModelAdapter.parse_response(
                api_type=endpoint_config['api_type'],
                response=result,
                model=request.model,
                request_id=request.request_id
            )
            
            return completion
                
        except requests.exceptions.RequestException as e:
            raise InferenceAPIError(502, "Backend service error")

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

        content = completion.choices[0].message.content
        if content:
            content_chunk = ChatCompletionChunk(
                id=completion.id,
                model=completion.model,
                choices=[
                    ChatChoice(
                        index=0,
                        delta={"content": content},
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
                    index=0,
                    delta={},
                    finish_reason=completion.choices[0].finish_reason
                )
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
            endpoint_config, model_config = await self.get_model_config(request.model)
            
            input_tokens = self.count_input_tokens(request)
            max_output_tokens = model_config.get('params', {}).get(
                'max_tokens',
                endpoint_config.get('params', {}).get('max_tokens', 4096)
            )
            
            max_cost = self.estimate_max_cost(
                model_config['pricing'],
                input_tokens,
                max_output_tokens
            )
            
            balance = await self.billing.balance(session_id)
            if balance < max_cost:
                await self.redis.publish(
                    f"billing:balance:updates:{session_id}",
                    str(balance)
                )
                raise InferenceAPIError(402, "Insufficient balance")
                
            await self.billing.debit(session_id, amount=max_cost)
            
            try:
                result = self.query_backend(endpoint_config, model_config, request)
                
                actual_cost = self.calculate_cost(
                    model_config['pricing'],
                    result.usage.prompt_tokens,
                    result.usage.completion_tokens
                )
                
                if actual_cost < max_cost:
                    refund = max_cost - actual_cost
                    await self.billing.credit(session_id, amount=refund)
                
                return result
                
            except Exception as e:
                await self.billing.credit(session_id, amount=max_cost)
                raise
                
        except Exception as e:
            if isinstance(e, InferenceAPIError):
                raise
            raise InferenceAPIError(500, str(e))

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.detail,
                "type": "invalid_request_error",
                "code": str(exc.status_code)
            }
        }
    )

logging.basicConfig(level=logging.INFO)

redis_url = os.environ.get('REDIS_URL', 'redis://localhost:6379')
redis = Redis.from_url(redis_url, decode_responses=True)
api = InferenceAPI(redis)

@app.post("/v1/chat/completions")
async def chat_completion(
    request: ChatCompletionRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        session_id = await api.validate_session(credentials)
        
        if request.stream:
            return StreamingResponse(
                api.stream_inference(request, session_id),
                media_type="text/event-stream",
                headers={
                    "Content-Type": "text/event-stream",
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                    "Transfer-Encoding": "chunked",
                }
            )
        
        result = await api.handle_inference(request, session_id)
        return result.dict(exclude_none=True)
    except InferenceAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/inference")
async def inference(
    request: ChatCompletionRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    return await chat_completion(request, credentials)

@app.get("/v1/models")
async def list_openai_models():
    try:
        return await api.list_openai_models()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/v1/inference/models")
async def list_inference_models():
    try:
        models = await api.list_models()
        return models
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
