from pydantic import BaseModel, Field, constr
from typing import Optional, Dict, Any, List, Literal, Union
from datetime import datetime
import uuid
import re

def validate_tool_name(v: str) -> str:
    if not re.match(r'^[a-zA-Z0-9_-]{1,64}$', v):
        raise ValueError("Tool name must match regex ^[a-zA-Z0-9_-]{1,64}$")
    return v

class FunctionDefinition(BaseModel):
    name: str = Field(..., description="The name of the function")
    description: Optional[str] = Field(None, description="A description of what the function does")
    parameters: Dict[str, Any] = Field(..., description="The parameters the function accepts")
    
class ToolFunction(BaseModel):
    type: Literal["function"]
    function: FunctionDefinition
    
class Tool(BaseModel):
    type: Literal["function"] = "function"
    function: FunctionDefinition

class ToolChoice(BaseModel):
    type: Literal["none", "auto", "function"] = "auto"
    function: Optional[Dict[str, str]] = None

class Message(BaseModel):
    role: Literal["system", "user", "assistant", "function", "tool"]
    content: Optional[str] = None
    name: Optional[str] = None
    function_call: Optional[Dict[str, Any]] = None
    tool_calls: Optional[List[Dict[str, Any]]] = None
    tool_call_id: Optional[str] = None

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
    
    # Tool/Function calling fields
    tools: Optional[List[Tool]] = Field(None, max_items=128)
    tool_choice: Optional[Union[str, ToolChoice]] = "auto"
    
    # Legacy function calling
    functions: Optional[List[Dict[str, Any]]] = None
    function_call: Optional[Union[str, Dict[str, str]]] = None

    def get_effective_tools(self) -> Optional[List[Tool]]:
        """Get the effective list of tools, converting legacy functions if needed."""
        if self.tools:
            return self.tools
        elif self.functions:
            return [
                Tool(
                    type="function",
                    function=FunctionDefinition(
                        name=fn["name"],
                        description=fn.get("description"),
                        parameters=fn["parameters"]
                    )
                )
                for fn in self.functions
            ]
        return None

    def get_effective_tool_choice(self) -> Union[str, ToolChoice]:
        """Get the effective tool choice, converting legacy function_call if needed."""
        if self.tool_choice != "auto":
            return self.tool_choice
        elif self.function_call:
            if isinstance(self.function_call, str):
                return "auto" if self.function_call == "auto" else ToolChoice(
                    type="function",
                    function={"name": self.function_call}
                )
            else:
                return ToolChoice(
                    type="function",
                    function={"name": self.function_call["name"]}
                )
        return "auto"

class ToolCallChoice(BaseModel):
    index: int
    id: str = Field(default_factory=lambda: f"call_{uuid.uuid4().hex[:12]}")
    type: Literal["function"]
    function: Dict[str, Any]

class ChatChoice(BaseModel):
    index: int
    message: Optional[Message] = None
    delta: Optional[Dict[str, Any]] = None
    finish_reason: Optional[str] = None
    logprobs: Optional[Any] = None

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
