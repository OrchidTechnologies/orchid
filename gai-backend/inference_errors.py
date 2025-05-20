from typing import Optional, Any, Dict

class InferenceError(Exception):
    """Base class for inference API errors"""
    def __init__(self, status_code: int, message: str, details: Optional[Dict[str, Any]] = None):
        self.status_code = status_code
        self.message = message
        self.details = details or {}
        super().__init__(message)

    def to_dict(self) -> Dict[str, Any]:
        error_response = {
            "error": {
                "message": self.message,
                "type": self.__class__.__name__,
                "code": str(self.status_code)
            }
        }
        if self.details:
            error_response["error"]["details"] = self.details
        return error_response

class ValidationError(InferenceError):
    """Error raised for validation failures"""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(400, message, details)

class AuthenticationError(InferenceError):
    """Error raised for authentication failures"""
    def __init__(self, message: str = "Invalid session"):
        super().__init__(401, message)

class InsufficientBalanceError(InferenceError):
    """Error raised when account balance is too low"""
    def __init__(self, message: str = "Insufficient balance"):
        super().__init__(402, message)

class ProviderError(InferenceError):
    """Base class for provider-related errors"""
    def __init__(self, message: str, status_code: int = 500):
        super().__init__(status_code, message)

class BackendServiceError(ProviderError):
    """Error raised when provider service fails"""
    def __init__(self, message: str = "Backend service error"):
        super().__init__(message, 502)

class ModelNotFoundError(ValidationError):
    """Error raised when requested model is not found"""
    def __init__(self, model: str):
        super().__init__(f"Unknown model: {model}")

class ConfigurationError(ProviderError):
    """Error raised for configuration-related issues"""
    def __init__(self, message: str = "Service configuration error"):
        super().__init__(message, 500)

class StreamingError(InferenceError):
    """Error raised during streaming operations"""
    def __init__(self, message: str):
        super().__init__(500, message)
