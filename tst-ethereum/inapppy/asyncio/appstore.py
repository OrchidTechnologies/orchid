from aiohttp import ClientError, ClientSession, ClientTimeout

from ..appstore import AppStoreValidator, api_result_errors, api_result_ok
from ..errors import InAppPyValidationError


class AppStoreValidator(AppStoreValidator):
    """The asyncio version of the app store validator."""

    def __init__(
        self,
        bundle_id: str,
        sandbox: bool = False,
        auto_retry_wrong_env_request: bool = False,
        http_timeout: int = None,
    ):
        super().__init__(bundle_id, sandbox, auto_retry_wrong_env_request, http_timeout)
        self._session = None

    async def __aenter__(self):
        self._session = ClientSession()

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self._session.close()
        self._session = None

    async def post_json(self, request_json: dict) -> dict:
        self._change_url_by_sandbox()
        try:
            async with self._session.post(
                self.url, json=request_json, timeout=ClientTimeout(total=self.http_timeout)
            ) as resp:
                return await resp.json(content_type=None)
        except (ValueError, ClientError):
            raise InAppPyValidationError("HTTP error")

    async def validate(self, receipt: str, shared_secret: str = None, exclude_old_transactions: bool = False) -> dict:
        """ Validates receipt against apple services.

        :param receipt: receipt
        :param shared_secret: optional shared secret.
        :param exclude_old_transactions: optional to include only the latest renewal transaction
        :return: validation result or exception.
        """
        receipt_json = self._prepare_receipt(receipt, shared_secret, exclude_old_transactions)

        api_response = await self.post_json(receipt_json)
        status = api_response["status"]

        # Check retry case.
        if self.auto_retry_wrong_env_request and status in [21007, 21008]:
            # switch environment
            self.sandbox = not self.sandbox

            api_response = await self.post_json(receipt_json)
            status = api_response["status"]

        if status != api_result_ok:
            error = api_result_errors.get(status, InAppPyValidationError("Unknown API status"))
            error.raw_response = api_response

            raise error

        return api_response
