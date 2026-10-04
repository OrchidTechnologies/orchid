"""Tests for the async query_backend conversion (Tier-1 #5).

Verifies query_backend is a coroutine (no longer blocks the event loop), still
parses upstream responses, maps provider errors, and — the new safety property —
enforces a hard wall-clock deadline regardless of httpx's per-chunk read timeout.
Injects a fake httpx client; no network. unittest, no new deps.
"""

import asyncio
import unittest

import httpx

import inference_core
from inference_core import InferenceAPI, BACKEND_WALL_CLOCK
from inference_errors import BackendServiceError
from inference_models import ChatCompletionRequest, Message


class _FakeResponse:
    def __init__(self, status_code=200, payload=None):
        self.status_code = status_code
        self._payload = payload or {}

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPStatusError(
                "error", request=httpx.Request("POST", "http://x"),
                response=httpx.Response(self.status_code),
            )

    def json(self):
        return self._payload


class _FakeHttpClient:
    """Stands in for httpx.AsyncClient; `behavior(url, headers, json)` is an
    async callable returning a response or raising."""
    def __init__(self, behavior):
        self._behavior = behavior

    async def post(self, url, headers=None, json=None):
        return await self._behavior(url, headers, json)


def _api(behavior):
    api = InferenceAPI.__new__(InferenceAPI)   # bypass __init__ (needs real redis)
    api._http_client = _FakeHttpClient(behavior)
    return api


_ENDPOINT = {"api_type": "openai", "url": "http://backend/v1/chat", "api_key": "k"}
_MODEL = {"id": "test-model"}


def _request():
    return ChatCompletionRequest(model="test-model",
                                 messages=[Message(role="user", content="hi")])


_OPENAI_OK = {
    "choices": [{"index": 0, "message": {"role": "assistant", "content": "hello"},
                 "finish_reason": "stop"}],
    "usage": {"prompt_tokens": 7, "completion_tokens": 3, "total_tokens": 10},
}


class TestQueryBackendAsync(unittest.TestCase):
    def _run(self, coro):
        return asyncio.run(coro)

    def test_is_coroutine(self):
        # the whole point of the PR: it no longer blocks the loop
        self.assertTrue(asyncio.iscoroutinefunction(InferenceAPI.query_backend))

    def test_happy_path_parses_usage(self):
        async def behavior(url, headers, json):
            return _FakeResponse(200, _OPENAI_OK)

        async def scenario():
            api = _api(behavior)
            out = await api.query_backend(_ENDPOINT, _MODEL, _request())
            self.assertEqual(out.usage.prompt_tokens, 7)
            self.assertEqual(out.usage.completion_tokens, 3)
            self.assertEqual(out.choices[0].message.content, "hello")
        self._run(scenario())

    def test_wall_clock_deadline(self):
        """A hung upstream must be bounded by the wall-clock, not hang forever."""
        async def behavior(url, headers, json):
            await asyncio.sleep(5)   # longer than the patched deadline
            return _FakeResponse(200, _OPENAI_OK)

        async def scenario():
            api = _api(behavior)
            inference_core.BACKEND_WALL_CLOCK = 0.05   # patch for a fast test
            try:
                with self.assertRaises(BackendServiceError) as ctx:
                    await api.query_backend(_ENDPOINT, _MODEL, _request())
                self.assertIn("timed out", str(ctx.exception))
            finally:
                inference_core.BACKEND_WALL_CLOCK = BACKEND_WALL_CLOCK  # restore
        self._run(scenario())

    def test_http_400_surfaces_provider_message(self):
        async def behavior(url, headers, json):
            return _FakeResponse(400, {"error": {"message": "unknown model: test-model"}})

        async def scenario():
            api = _api(behavior)
            with self.assertRaises(BackendServiceError) as ctx:
                await api.query_backend(_ENDPOINT, _MODEL, _request())
            self.assertIn("unknown model", str(ctx.exception))
        self._run(scenario())

    def test_connection_error_maps_to_backend_error(self):
        async def behavior(url, headers, json):
            raise httpx.ConnectError("connection refused")

        async def scenario():
            api = _api(behavior)
            with self.assertRaises(BackendServiceError):
                await api.query_backend(_ENDPOINT, _MODEL, _request())
        self._run(scenario())


if __name__ == "__main__":
    unittest.main()
