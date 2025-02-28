import uuid
import json
import logging
from datetime import datetime
from typing import Dict, Any, Tuple, Optional, List, Union
from inference_models import (
    ChatCompletionRequest, 
    ChatCompletion,
    ChatCompletionChunk,
    ChatChoice,
    Message,
    Usage,
    InferenceAPIError,
    Tool,
    ToolChoice
)

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class ModelAdapter:
    logger = logging.getLogger(__name__)
    
    @staticmethod
    def parse_response(api_type: str, response: Dict[str, Any], model: str, request_id: str) -> ChatCompletion:
        if api_type in ('openai', 'openrouter'):
            return ModelAdapter.parse_openai_response(response, model, request_id)
        elif api_type == 'anthropic':
            return ModelAdapter.parse_anthropic_response(response, model, request_id)
        else:
            raise InferenceAPIError(500, f"Unsupported API type: {api_type}")

    @staticmethod
    def parse_anthropic_response(response: Dict[str, Any], model: str, response_id: str) -> ChatCompletion:
        content = response.get('content', [])
        message = Message(role="assistant")
        
        # Process content blocks
        for block in content:
            block_type = block.get('type')
            if block_type == 'text':
                message.content = block.get('text', '')
            elif block_type == 'tool_use':
                if not message.tool_calls:
                    message.tool_calls = []
                message.tool_calls.append({
                    'id': block.get('id', str(uuid.uuid4())),
                    'type': 'function',
                    'function': {
                        'name': block.get('name'),
                        'arguments': json.dumps(block.get('input', {}))
                    }
                })

        # Create choice
        choice = ChatChoice(
            index=0,
            message=message,
            finish_reason=response.get('stop_reason', 'stop')
        )

        # Handle usage fields
        usage = Usage(
            prompt_tokens=response['usage'].get('input_tokens', 0),
            completion_tokens=response['usage'].get('output_tokens', 0),
            total_tokens=response['usage'].get('input_tokens', 0) + response['usage'].get('output_tokens', 0)
        )

        return ChatCompletion(
            id=response_id,
            model=model,
            choices=[choice],
            usage=usage,
            system_fingerprint=response.get('system_fingerprint')
        )

    @classmethod
    def prepare_anthropic_request(cls, model_config: Dict[str, Any], api_key: str, request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        headers = {
            "Content-Type": "application/json", 
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01"
        }

        # Extract system message if present
        messages = request.messages.copy()
        system = next((msg.content for msg in messages if msg.role == "system"), None)
        messages = [msg for msg in messages if msg.role != "system"]

        # Convert messages to Anthropic format
        anthropic_messages = []
        for msg in messages:
            if msg.role == "tool":
                # Handle tool results as separate content blocks
                content = [{
                    "type": "tool_result",
                    "tool_use_id": msg.tool_call_id,
                    "content": msg.content
                }]
            else:
                # Handle regular messages and tool calls
                content = []
                if msg.content:
                    content.append({"type": "text", "text": msg.content})
                
                if msg.role == "assistant" and msg.tool_calls:
                    for tool_call in msg.tool_calls:
                        content.append({
                            "type": "tool_use",
                            "id": tool_call.get("id", str(uuid.uuid4())),
                            "name": tool_call["function"]["name"],
                            "input": json.loads(tool_call["function"]["arguments"])
                        })

            if content:
                role = "assistant" if msg.role == "assistant" else "user"
                anthropic_messages.append({
                    "role": role,
                    "content": content
                })

        data = {
            "model": model_config['id'],
            "messages": anthropic_messages,
            "max_tokens": request.max_tokens or 4096
        }

        if system:
            data["system"] = system

        # Handle tools
        tools = request.get_effective_tools()
        if tools:
            cls.logger.debug(f"Including {len(tools)} tools in Anthropic request")
            data["tools"] = []
            for tool in tools:
                tool_def = {
                    "name": tool.function.name,
                    "description": tool.function.description,
                    "input_schema": tool.function.parameters
                }
                data["tools"].append(tool_def)
            cls.logger.debug(f"Tools in Anthropic request: {json.dumps(data['tools'])}")
            
            # Handle tool choice - only when tools are present
            tool_choice = request.get_effective_tool_choice()
            if isinstance(tool_choice, str):
                data["tool_choice"] = "none" if tool_choice == "none" else {"type": "auto"}
            elif tool_choice and tool_choice.type == "function":
                data["tool_choice"] = {
                    "type": "function",
                    "function": {"name": tool_choice.function.get("name")} if tool_choice.function else None
                }
            else:
                data["tool_choice"] = {"type": "auto"}
        else:
            cls.logger.debug("No tools to include in Anthropic request")

        # Copy other parameters
        if request.temperature is not None:
            data["temperature"] = request.temperature
        if request.top_p is not None:
            data["top_p"] = request.top_p
        if request.stream is not None:
            data["stream"] = request.stream
        if request.stop is not None:
            data["stop_sequences"] = request.stop if isinstance(request.stop, list) else [request.stop]

        logger.debug(f"Prepared Anthropic request: {data}")
        return data, headers

    @staticmethod
    def parse_openai_response(response: Dict[str, Any], model: str, response_id: str) -> ChatCompletion:
        return ChatCompletion(
            id=response_id,
            model=model,
            choices=[
                ChatChoice(
                    index=choice.get('index', 0),
                    message=Message(
                        role=choice['message']['role'],
                        content=choice['message'].get('content'),
                        tool_calls=choice['message'].get('tool_calls'),
                        function_call=choice['message'].get('function_call')
                    ),
                    finish_reason=choice.get('finish_reason')
                )
                for choice in response['choices']
            ],
            usage=Usage(
                prompt_tokens=response['usage']['prompt_tokens'],
                completion_tokens=response['usage']['completion_tokens'],
                total_tokens=response['usage']['total_tokens']
            )
        )

    @classmethod
    def prepare_openai_request(cls, model_config: Dict[str, Any], api_key: str, request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }

        data = request.dict(exclude_none=True, exclude={'request_id'})
        data['model'] = model_config['id']
        
        # Log tools information
        tools = request.get_effective_tools()
        if tools:
            cls.logger.debug(f"Including {len(tools)} tools in OpenAI request")
            for tool in tools:
                cls.logger.debug(f"Tool in OpenAI request: {tool.function.name}")
        else:
            cls.logger.debug("No tools to include in OpenAI request")
        
        return data, headers
        
    @classmethod
    def prepare_request(cls, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        api_key = endpoint_config.get('api_key')
        if not api_key:
            raise InferenceAPIError(500, "Backend authentication not configured")

        api_type = endpoint_config['api_type']
        if api_type in ('openai', 'openrouter'):
            return cls.prepare_openai_request(model_config, api_key, request)
        elif api_type == 'anthropic':
            return cls.prepare_anthropic_request(model_config, api_key, request)
        else:
            raise InferenceAPIError(500, f"Unsupported API type: {api_type}")
