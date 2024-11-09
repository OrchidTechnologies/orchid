from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from redis.asyncio import Redis
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, Tuple, List, Literal
import json
import os
import requests
from config_manager import ConfigManager
from billing import StrictRedisBilling, BillingError
import logging

app = FastAPI()
security = HTTPBearer()
logger = logging.getLogger(__name__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Message(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str
    name: Optional[str] = None

class InferenceRequest(BaseModel):
    messages: List[Message]
    model: str
    params: Optional[Dict[str, Any]] = None
    request_id: Optional[str] = None

class ModelInfo(BaseModel):
    id: str
    name: str
    api_type: Literal["openai", "anthropic", "openrouter"]
    endpoint: str

class InferenceAPIError(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail

class PricingError(Exception):
    """Raised when pricing calculation fails"""
    pass

class InferenceAPI:
    def __init__(self, redis: Redis):
        self.redis = redis
        self.config_manager = ConfigManager(redis)
        self.billing = StrictRedisBilling(redis)
        
    async def init(self):
        await self.billing.init()
        await self.config_manager.load_config()

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

    async def validate_session(self, credentials: HTTPAuthorizationCredentials) -> str:
        if not credentials:
            logger.error("No credentials provided")
            raise InferenceAPIError(401, "Missing session ID")
            
        session_id = credentials.credentials
        logger.info(f"Validating session: {session_id}")
            
        try:
            balance = await self.billing.balance(session_id)
            logger.info(f"Session {session_id} balance: {balance}")
            
            if balance is None:
                logger.error(f"No balance found for session {session_id}")
                raise InferenceAPIError(401, "Invalid session")
                
            min_balance = await self.billing.min_balance()
            logger.info(f"Minimum balance required: {min_balance}")
            
            if balance < min_balance:
                logger.warning(f"Insufficient balance: {balance} < {min_balance}")
                raise InferenceAPIError(402, "Insufficient balance")
                
            return session_id
            
        except BillingError as e:
            logger.error(f"Billing error during validation: {e}")
            raise InferenceAPIError(500, "Internal service error")
            
        except Exception as e:
            logger.error(f"Unexpected error during validation: {e}")
            raise InferenceAPIError(500, f"Internal service error: {e}")
        
    async def get_model_config(self, model_id: str) -> Tuple[Dict[str, Any], Dict[str, Any]]:
        config = await self.config_manager.load_config()
        endpoints = config['inference']['endpoints']
        
        for endpoint_id, endpoint in endpoints.items():
            for model in endpoint['models']:
                if model['id'] == model_id:
                    return endpoint, model
                    
        raise InferenceAPIError(400, f"Unknown model: {model_id}")

    def prepare_request(self, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], request: InferenceRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        params = {
            **(endpoint_config.get('params', {})),
            **(model_config.get('params', {})),
            **(request.params or {})
        }
        
        headers = {"Content-Type": "application/json"}
        api_type = endpoint_config['api_type']
        
        if not (api_key := endpoint_config.get('api_key')):
            logger.error("No API key configured for endpoint")
            raise InferenceAPIError(500, "Backend authentication not configured")

        data: Dict[str, Any] = {}
            
        if api_type == 'openai':
            headers["Authorization"] = f"Bearer {api_key}"
            data = {
                'model': model_config['id'],
                'messages': [msg.dict(exclude_none=True) for msg in request.messages]
            }
            if 'max_tokens' in (request.params or {}):
                data['max_tokens'] = params['max_tokens']
            
        elif api_type == 'openrouter':
            headers["Authorization"] = f"Bearer {api_key}"
            data = {
                'model': model_config['id'],
                'messages': [msg.dict(exclude_none=True) for msg in request.messages]
            }
            
            if 'max_tokens' in (request.params or {}):
                user_max_tokens = params['max_tokens']
                config_max_tokens = model_config.get('params', {}).get('max_tokens')
                
                if config_max_tokens and user_max_tokens > config_max_tokens:
                    raise InferenceAPIError(400, f"Requested max_tokens {user_max_tokens} exceeds model limit {config_max_tokens}")
                
                prompt_tokens = self.count_input_tokens(request)
                if config_max_tokens and (prompt_tokens + user_max_tokens) > config_max_tokens:
                    raise InferenceAPIError(400, 
                        f"Combined prompt ({prompt_tokens}) and max_tokens ({user_max_tokens}) "
                        f"exceeds model context limit {config_max_tokens}")
                
                data['max_tokens'] = user_max_tokens
            
        elif api_type == 'anthropic':
            headers["x-api-key"] = api_key
            headers["anthropic-version"] = "2023-06-01"
            system_message = next((msg.content for msg in request.messages if msg.role == "system"), None)
            conversation = [msg for msg in request.messages if msg.role != "system"]
            
            data = {
                'model': model_config['id'],
                'messages': [{'role': msg.role, 'content': msg.content} for msg in conversation],
                'max_tokens': params.get('max_tokens', 4096)
            }
            if system_message:
                data['system'] = system_message
                
        else:
            raise InferenceAPIError(500, f"Unsupported API type: {api_type}")
            
        for k, v in params.items():
            if k != 'max_tokens' and k not in data:
                data[k] = v
                
        return data, headers

    def parse_response(self, api_type: str, response: Dict[str, Any], request_id: Optional[str] = None) -> Dict[str, Any]:
        try:
            base_response = {
                'request_id': request_id,
            }
            
            if api_type in ['openai', 'openrouter']:  # OpenRouter follows OpenAI response format
                return {
                    **base_response,
                    'response': response['choices'][0]['message']['content'],
                    'usage': response['usage']
                }
            elif api_type == 'anthropic':
                return {
                    **base_response,
                    'response': response['content'][0]['text'],
                    'usage': {
                        'prompt_tokens': response['usage']['input_tokens'],
                        'completion_tokens': response['usage']['output_tokens'],
                        'total_tokens': response['usage']['input_tokens'] + response['usage']['output_tokens']
                    }
                }
            else:
                raise InferenceAPIError(500, f"Unsupported API type: {api_type}")
        except KeyError as e:
            logger.error(f"Failed to parse {api_type} response: {e}")
            logger.error(f"Response: {response}")
            logger.debug(f"Raw response: {response}")
            raise InferenceAPIError(502, f"Invalid {api_type} response format")

    def query_backend(self, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], request: InferenceRequest) -> Dict[str, Any]:
        try:
            data, headers = self.prepare_request(endpoint_config, model_config, request)
            
            logger.info(f"Sending request to backend: {endpoint_config['url']}")
            logger.debug(f"Request headers: {headers}")
            logger.debug(f"Request data: {data}")
            
            response = requests.post(
                endpoint_config['url'],
                headers=headers,
                json=data,
                timeout=30
            )
            
            try:
                response.raise_for_status()
            except requests.exceptions.HTTPError as e:
                if response.status_code == 400:
                    if endpoint_config['api_type'] == 'openrouter':
                        error_body = response.json()
                        if 'error' in error_body and 'message' in error_body['error']:
                            raise InferenceAPIError(400, error_body['error']['message'])
                raise
            
            result = response.json()
            logger.debug(f"Raw backend response: {result}")
            
            return self.parse_response(endpoint_config['api_type'], result, request.request_id)
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Backend request failed: {e}")
            raise InferenceAPIError(502, "Backend service error")

    def get_token_prices(self, pricing_config: Dict[str, Any]) -> Tuple[float, float]:
        try:
            pricing_type = pricing_config['type']
            
            if pricing_type == 'fixed':
                return (
                    pricing_config['input_price'],
                    pricing_config['output_price']
                )
                
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
                raise PricingError(f"Unknown pricing type: {pricing_type}")
                
        except KeyError as e:
            raise PricingError(f"Missing required pricing field: {e}")
            
    def calculate_cost(self, pricing_config: Dict[str, Any], input_tokens: int, output_tokens: int) -> float:
        try:
            input_price, output_price = self.get_token_prices(pricing_config)
            
            total_cost = (
                (input_tokens * input_price) +
                (output_tokens * output_price)
            ) / 1_000_000  # Convert to millions of tokens
            
            return total_cost
            
        except Exception as e:
            raise PricingError(f"Failed to calculate cost: {e}")

    def estimate_max_cost(self, pricing_config: Dict[str, Any], input_tokens: int, max_output_tokens: int) -> float:
        return self.calculate_cost(pricing_config, input_tokens, max_output_tokens)
        
    def count_input_tokens(self, request: InferenceRequest) -> int:
        # TODO: Implement proper tokenization based on model
        return sum(len(msg.content) // 4 for msg in request.messages)  # Rough estimate
        
    async def handle_inference(
        self,
        request: InferenceRequest,
        session_id: str
    ) -> Dict[str, Any]:
        try:
            # Get endpoint and model configs - model is now required
            endpoint_config, model_config = await self.get_model_config(request.model)
            
            # Calculate maximum possible cost
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
                logger.warning(f"Insufficient balance for max cost: {balance} < {max_cost}")
                await self.redis.publish(
                    f"billing:balance:updates:{session_id}",
                    str(balance)
                )
                raise InferenceAPIError(402, "Insufficient balance")
                
            await self.billing.debit(session_id, amount=max_cost)
            logger.info(f"Reserved {max_cost} tokens from balance")
            
            try:
                result = self.query_backend(endpoint_config, model_config, request)
                
                actual_cost = self.calculate_cost(
                    model_config['pricing'],
                    result['usage']['prompt_tokens'],
                    result['usage']['completion_tokens']
                )
                
                logger.info(f"Actual cost: {actual_cost} (reserved: {max_cost})")
                
                if actual_cost < max_cost:
                    refund = max_cost - actual_cost
                    await self.billing.credit(session_id, amount=refund)
                    logger.info(f"Refunded excess reservation: {refund}")
                
                return result
                
            except Exception as e:
                logger.error(f"Error during inference: {e}")
                await self.billing.credit(session_id, amount=max_cost)
                raise
                
        except BillingError as e:
            logger.error(f"Billing error: {e}")
            raise InferenceAPIError(500, "Internal service error")
        except PricingError as e:
            logger.error(f"Pricing error: {e}")
            raise InferenceAPIError(500, f"Pricing configuration error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise InferenceAPIError(500, str(e))

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

redis_url = os.environ.get('REDIS_URL', 'redis://localhost:6379')
redis = Redis.from_url(redis_url, decode_responses=True)
api = InferenceAPI(redis)

@app.on_event("startup")
async def startup():
    await api.init()

@app.post("/v1/chat/completions")
async def chat_completion(
    request: InferenceRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    logger.info(f"Received chat completion request with auth: {credentials.scheme} {credentials.credentials}")
    try:
        session_id = await api.validate_session(credentials)
        return await api.handle_inference(request, session_id)
    except InferenceAPIError as e:
        logger.error(f"Inference API error: {e.status_code} - {e.detail}")
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/inference")
async def inference(
    request: InferenceRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    return await chat_completion(request, credentials)

@app.get("/v1/models")
async def list_models():
    """List available inference models"""
    try:
        models = await api.list_models()
        return models
    except Exception as e:
        logger.error(f"Failed to list models: {e}")
        raise HTTPException(status_code=500, detail=str(e))
