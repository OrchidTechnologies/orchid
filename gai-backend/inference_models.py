from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List, Literal, Union
from datetime import datetime
import uuid

class Message(BaseModel):
    role: Literal["system", "user", "assistant", "function"]
    content: Optional[str] = None
    name: Optional[str] = None
    function_call: Optional[Dict[str, Any]] = None

class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[Message]
    temperature: Optional[float] = 1.0
    top_p: Optional[float] = 1.0
    n: Optional[int] = 1
    stream: Optional[bool] = False
    stop: Optional[Union[str, List[str]]] = None
    max_tokens: Optional[int] = None
    presence_penalty: Optional[float] = 0
    frequency_penalty: Optional[float] = 0
    user: Optional[str] = None
    request_id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    tools: Optional[List[Dict[str, Any]]] = None
    tool_choice: Optional[Union[str, Dict[str, Any]]] = None
    functions: Optional[List[Dict[str, Any]]] = None
    function_call: Optional[Union[str, Dict[str, Any]]] = None

class ChatChoice(BaseModel):
    index: int
    message: Optional[Message] = None
    delta: Optional[Dict[str, Any]] = None
    finish_reason: Optional[str] = None

class Usage(BaseModel):
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int

class ChatCompletion(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    model: str
    choices: List[ChatChoice]
    usage: Usage
    system_fingerprint: Optional[str] = None

class ChatCompletionChunk(BaseModel):
    id: str
    object: str = "chat.completion.chunk"
    created: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    model: str
    choices: List[ChatChoice]
    system_fingerprint: Optional[str] = None

class ModelInfo(BaseModel):
    id: str
    name: str
    api_type: Literal["openai", "anthropic", "openrouter"]
    endpoint: str

class OpenAIModel(BaseModel):
    id: str
    object: str = "model"
    created: int
    owned_by: str

class OpenAIModelList(BaseModel):
    object: str = "list"
    data: List[OpenAIModel]

class InferenceAPIError(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail

class PricingError(Exception):
    pass
