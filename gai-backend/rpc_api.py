from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from redis.asyncio import Redis
from contextlib import asynccontextmanager
import httpx
import os

from config_manager import ConfigManager
from billing import StrictRedisBilling

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    redis_url = os.environ['ORCHID_GENAI_REDIS_URL']
    redis = Redis.from_url(redis_url, decode_responses=True)
    app.state.api = RPCAPI(redis)
    await app.state.api.init()
    yield
    # Shutdown
    await redis.close()

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RPCAPI:
    def __init__(self, redis: Redis):
        self.redis = redis
        self.config_manager = ConfigManager(redis)
        self.billing = StrictRedisBilling(redis)
        
    async def init(self):
        await self.billing.init()
        self.config = await self.config_manager.load_config()
        if 'rpc' not in self.config:
            raise ValueError("RPC config required")

    async def handle_rpc(self, request: dict, session_id: str):
        method = request.get('method')
        
        if method not in self.config['rpc']['prices']:
            raise HTTPException(400, "Method not supported")
            
        credits = self.config['rpc']['prices'][method]
        credit_to_usd = self.config['rpc']['pricing']['credit_to_usd']
        price_usd = credits * credit_to_usd
        
        print(f"Method {method}: {credits} credits = ${price_usd}")
        
        # Check balance and debit
        balance = await self.billing.balance(session_id)
        print(f"Current balance: ${balance}")
        
        if balance < price_usd:
            raise HTTPException(402, f"Insufficient balance: ${balance} < ${price_usd}")
            
        await self.billing.debit(session_id, amount=price_usd)
        
        provider_url = f"{self.config['rpc']['provider_url']}/{self.config['rpc']['provider_key']}"
        print(f"Sending request to provider: {provider_url}")
        print(f"Request body: {request}")
        
        # Create new client for each request
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                provider_url,
                json=request
            )
            print(f"Provider response status: {resp.status_code}")
            print(f"Provider response content: {resp.content}")
            if resp.content:
                return resp.json()
            else:
                raise HTTPException(502, "Empty response from provider")

@app.api_route("/", methods=["GET", "POST", "OPTIONS"])
async def rpc_endpoint(request: Request, token: str):
    if request.method == "OPTIONS":
        return {}
        
    # For GET requests (like when MetaMask checks chainId)
    if request.method == "GET":
        # Return a simple JSON-RPC response
        return {
            "jsonrpc": "2.0",
            "id": None,
            "result": {
                "chainId": "0x1"  # Mainnet
            }
        }
    
    # Existing POST handling
    body = await request.json()
    return await app.state.api.handle_rpc(body, token)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
