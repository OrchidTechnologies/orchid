import os
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from redis.asyncio import Redis
from contextlib import asynccontextmanager
import uuid

from inference_models import (
    ChatCompletionRequest, 
    ListToolsResponse,
    ToolCallRequest, 
    ToolCallResponse, 
    ToolDefinition,
    ContentItem
)
from inference_errors import InferenceError
from inference_core import InferenceAPI
from inference_logging import configure_logging

logger = configure_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    await api.init()
    yield
    await redis.close()

async def validation_error_handler(request, exc: RequestValidationError):
    """Handle request validation errors"""
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "message": "Request validation failed",
                "type": "invalid_request_error",
                "code": "422",
                "details": exc.errors()
            }
        }
    )

async def inference_error_handler(request, exc: InferenceError):
    """Handle inference API errors"""
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.to_dict()
    )

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.add_exception_handler(RequestValidationError, validation_error_handler)
app.add_exception_handler(InferenceError, inference_error_handler)

redis_url = os.environ.get('ORCHID_GENAI_REDIS_URL', os.environ.get('REDIS_URL', 'redis://localhost:6379'))
redis = Redis.from_url(redis_url, decode_responses=True)
api = InferenceAPI(redis)

security = HTTPBearer()

@app.post("/v1/chat/completions")
async def chat_completion(
    request: Request,
    chat_request: ChatCompletionRequest
):
    request_id = chat_request.request_id or str(uuid.uuid4())
    logger.info(f"Processing chat completion request {request_id}")
    
    try:
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            raise HTTPException(status_code=401, detail="Missing Authorization header")
            
        session_id = auth_header.replace("Bearer ", "") if auth_header.startswith("Bearer ") else auth_header
        await api.validate_session(session_id)
        
        if chat_request.stream:
            return StreamingResponse(
                api.stream_inference(chat_request, session_id),
                media_type="text/event-stream",
                headers={
                    "Content-Type": "text/event-stream",
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                    "Transfer-Encoding": "chunked",
                }
            )
        
        result = await api.handle_inference(chat_request, session_id)
        return result.dict(exclude_none=True)
        
    except Exception as e:
        if isinstance(e, InferenceError):
            raise
        logger.error(f"Unexpected error in request {request_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/v1/models")
async def list_openai_models():
    try:
        logger.debug("Handling request to /v1/models")
        return await api.list_openai_models()
    except Exception as e:
        logger.error(f"Error listing OpenAI models: {e}", exc_info=True)
        if isinstance(e, InferenceError):
            raise
        # Return empty list instead of error
        return {"data": []}

@app.get("/v1/inference/models")
async def list_inference_models():
    try:
        logger.debug("Handling request to /v1/inference/models")
        return await api.list_models()
    except Exception as e:
        logger.error(f"Error listing inference models: {e}", exc_info=True)
        if isinstance(e, InferenceError):
            raise
        # Return empty dict instead of error
        return {}
        
@app.post("/v1/tools/list")
@app.options("/v1/tools/list")
async def list_tools(
    request: Request, 
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    # Handle OPTIONS request for CORS preflight
    if request.method == "OPTIONS":
        return {}
    try:
        logger.info("Processing tools list request")
        session_id = credentials.credentials
        await api.validate_session(session_id)
        
        # Get available tools from registry
        tool_definitions = await api.list_tools()
        
        # Debug output to see what's happening with tool parameters
        for tool in tool_definitions:
            logger.debug(f"Tool {tool.name} parameters: {tool.parameters}")
        
        # Format the response according to the spec
        response = ListToolsResponse(tools=tool_definitions)
        return response
    except Exception as e:
        logger.error(f"Error listing tools: {str(e)}", exc_info=True)
        if isinstance(e, InferenceError):
            raise
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/tools/call")
@app.options("/v1/tools/call")
async def call_tool(
    request: Request,
    tool_request: ToolCallRequest = None,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    # Handle OPTIONS request for CORS preflight
    if request.method == "OPTIONS":
        return {}
    try:
        if tool_request is None:
            raise HTTPException(status_code=400, detail="Missing tool request body")
        
        logger.info(f"Processing tool call request for tool: {tool_request.name}")
        session_id = credentials.credentials
        await api.validate_session(session_id)
        
        # Execute the tool with billing
        result = await api.execute_tool(tool_request.name, tool_request.arguments, session_id)
        
        # Format the response according to the spec
        content_item = ContentItem(type="text", text=result)
        response = ToolCallResponse(content=[content_item])
        return response
    except Exception as e:
        logger.error(f"Error executing tool {tool_request.name}: {str(e)}", exc_info=True)
        if isinstance(e, InferenceError):
            raise
        raise HTTPException(status_code=500, detail=str(e))
