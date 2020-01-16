import requests
from requests.exceptions import RequestException

from inapppy.errors import InAppPyValidationError

# https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html
# `Table 2-1  Status codes`
api_result_ok = 0
api_result_errors = {
    21000: InAppPyValidationError("Bad json"),
    21002: InAppPyValidationError("Bad data"),
    21003: InAppPyValidationError("Receipt authentication"),
    21004: InAppPyValidationError("Shared secret mismatch"),
    21005: InAppPyValidationError("Server is unavailable"),
    21006: InAppPyValidationError("Subscription has expired"),
    # two following errors can use auto_retry_wrong_env_request.
    21007: InAppPyValidationError("Sandbox receipt was sent to the production env"),
    21008: InAppPyValidationError("Production receipt was sent to the sandbox env"),
}


class AppStoreValidator:
    def __init__(
        self,
        bundle_id: str,
        sandbox: bool = False,
        auto_retry_wrong_env_request: bool = False,
        http_timeout: int = None,
    ):
        print("AppStoreValidator()");
        """ Constructor for AppStoreValidator

        :param bundle_id: apple bundle id
        :param sandbox: sandbox mode ?
        :param auto_retry_wrong_env_request: auto retry on wrong env ?
        """
        if not bundle_id:
            raise InAppPyValidationError("bundle_id cannot be empty")

        self.bundle_id = bundle_id
        self.sandbox = sandbox
        self.http_timeout = http_timeout
        self.auto_retry_wrong_env_request = auto_retry_wrong_env_request

        self._change_url_by_sandbox()

    def _change_url_by_sandbox(self):
        self.url = (
            "https://sandbox.itunes.apple.com/verifyReceipt"
            if self.sandbox
            else "https://buy.itunes.apple.com/verifyReceipt"
        )
        print(f"self.url = {self.url}");

    def _prepare_receipt(self, receipt: str, shared_secret: str, exclude_old_transactions: bool) -> dict:
        receipt_json = {"receipt-data": receipt}

        if shared_secret:
            receipt_json["password"] = shared_secret

        if exclude_old_transactions:
            receipt_json["exclude-old-transactions"] = True

        return receipt_json

    def post_json(self, request_json: dict) -> dict:
        self._change_url_by_sandbox()

        try:
            response = requests.post(self.url, json=request_json, timeout=self.http_timeout).json()
            print(f"post {self.url} : "); print(request_json);
            print("response: "); print(response);
            return response;
        except (ValueError, RequestException):
            raise InAppPyValidationError("HTTP error")

    def validate(self, receipt: str, shared_secret: str = None, exclude_old_transactions: bool = False) -> dict:
        """ Validates receipt against apple services.

        :param receipt: receipt
        :param shared_secret: optional shared secret.
        :param exclude_old_transactions: optional to include only the latest renewal transaction
        :return: validation result or exception.
        """
        receipt_json = self._prepare_receipt(receipt, shared_secret, exclude_old_transactions)

        api_response = self.post_json(receipt_json)
        status = api_response.get("status", "unknown")

        # Check retry case.
        if self.auto_retry_wrong_env_request and status in [21007, 21008]:
            # switch environment
            self.sandbox = not self.sandbox

            api_response = self.post_json(receipt_json)
            status = api_response["status"]

        if status != api_result_ok:
            error = api_result_errors.get(status, InAppPyValidationError("Unknown API status"))
            error.raw_response = api_response

            raise error

        return api_response
