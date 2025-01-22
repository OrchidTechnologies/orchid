from typing import Dict, Any, Tuple, Optional
import uuid
import logging
from inference_models import ChatCompletionRequest, ChatCompletion, ChatChoice, Message, Usage, InferenceAPIError
from datetime import datetime

logger = logging.getLogger(__name__)

class ModelAdapter:
    @staticmethod
    def parse_openai_response(response: Dict[str, Any], model: str, response_id: str) -> ChatCompletion:
        choice = response['choices'][0]
        return ChatCompletion(
            id=response_id,
            model=model,
            choices=[
                ChatChoice(
                    index=0,
                    message=Message(
                        role="assistant",
                        content=choice['message']['content'],
                        function_call=choice['message'].get('function_call')
                    ),
                    finish_reason=choice.get('finish_reason')
                )
            ],
            usage=Usage(
                prompt_tokens=response['usage']['prompt_tokens'],
                completion_tokens=response['usage']['completion_tokens'],
                total_tokens=response['usage']['total_tokens']
            )
        )

    @staticmethod
    def parse_anthropic_response(response: Dict[str, Any], model: str, response_id: str) -> ChatCompletion:
        stop_reason_map = {
            "max_tokens": "length",
            "stop_sequence": "stop"
        }
        
        # Add debug logging
        logger.info(f"Parsing Anthropic response: {response}")
        
        chat_completion = ChatCompletion(
            id=response_id,
            model=model,
            choices=[
                ChatChoice(
                    index=0,
                    message=Message(
                        role="assistant",
                        content=response['content'][0]['text']
                    ),
                    finish_reason=stop_reason_map.get(response.get('stop_reason'), "stop")
                )
            ],
            usage=Usage(
                prompt_tokens=response['usage']['input_tokens'],
                completion_tokens=response['usage']['output_tokens'],
                total_tokens=response['usage']['input_tokens'] + response['usage']['output_tokens']
            )
        )
        
        # Log the parsed response
        logger.info(f"Parsed Anthropic response: {chat_completion.dict()}")
        return chat_completion

    @classmethod 
    def parse_response(cls, api_type: str, response: Dict[str, Any], model: str, request_id: Optional[str] = None) -> ChatCompletion:
        try:
            # Generate a request ID if none was provided
            rid = request_id or str(uuid.uuid4())
            response_id = f"chatcmpl-{rid}"
            
            if api_type == 'openai':
                return cls.parse_openai_response(response, model, response_id)
            elif api_type == 'anthropic':
                return cls.parse_anthropic_response(response, model, response_id)
            elif api_type == 'openrouter':
                return cls.parse_openai_response(response, model, response_id)
            else:
                raise InferenceAPIError(500, f"Unsupported API type: {api_type}")
        except KeyError as e:
            logger.error(f"Failed to parse {api_type} response: {e}")
            logger.debug(f"Raw response: {response}")
            raise InferenceAPIError(502, f"Invalid {api_type} response format")

    @staticmethod
    def prepare_openai_request(model_config: Dict[str, Any], api_key: str, request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        
        data = {
            'model': model_config['id'],
            'messages': [msg.dict(exclude_none=True) for msg in request.messages]
        }
        
        # Add OpenAI parameters
        for param in ['temperature', 'top_p', 'frequency_penalty', 'presence_penalty', 'max_tokens']:
            if (value := getattr(request, param)) is not None:
                data[param] = value
                
        return data, headers
        
    @staticmethod
    def prepare_anthropic_request(model_config: Dict[str, Any], api_key: str, request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        headers = {
            "Content-Type": "application/json",
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01"
        }
        
        system_message = next((msg.content for msg in request.messages if msg.role == "system"), None)
        conversation = [msg for msg in request.messages if msg.role != "system"]
        
        data = {
            'model': model_config['id'],
            'messages': [{'role': msg.role, 'content': msg.content} for msg in conversation],
            'max_tokens': request.max_tokens or 4096
        }
        
        if system_message:
            data['system'] = system_message
            
        return data, headers

    @classmethod
    def prepare_request(cls, endpoint_config: Dict[str, Any], model_config: Dict[str, Any], request: ChatCompletionRequest) -> Tuple[Dict[str, Any], Dict[str, str]]:
        api_key = endpoint_config.get('api_key')
        if not api_key:
            raise InferenceAPIError(500, "Backend authentication not configured")

        api_type = endpoint_config['api_type']
        if api_type == 'openai':
            return cls.prepare_openai_request(model_config, api_key, request)
        elif api_type == 'anthropic':
            return cls.prepare_anthropic_request(model_config, api_key, request)
        elif api_type == 'openrouter':
            return cls.prepare_openai_request(model_config, api_key, request)
        else:
            raise InferenceAPIError(500, f"Unsupported API type: {api_type}")
