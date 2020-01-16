class InAppPyValidationError(Exception):
    """ Base class for all validation errors """

    raw_response = None
    message = None

    def __init__(self, message: str = None, raw_response: dict = None, *args, **kwargs):
        self.raw_response = raw_response
        self.message = message

        super().__init__(message, *args, **kwargs)

    def __str__(self):
        return f"{self.__class__.__name__} {self.message} {self.raw_response}"

    def __repr__(self):
        return f"{self.__class__.__name__}(message={self.message!r}, raw_response={self.raw_response!r})"


class GoogleError(InAppPyValidationError):
    pass
