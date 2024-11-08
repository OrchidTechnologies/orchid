import json
from redis.asyncio import Redis
import redis
from decimal import Decimal
from typing import Optional, Dict
import asyncio

class BillingError(Exception):
    """Base class for billing errors that should terminate the connection"""
    pass

class RedisConnectionError(BillingError):
    """Redis connection or operation failed"""
    pass

class InconsistentStateError(BillingError):
    """Billing state became inconsistent"""
    pass

class StrictRedisBilling:
    def __init__(self, redis: Redis):
        self.redis = redis
        
    async def init(self):
        try:
            await self.redis.ping()
        except Exception as e:
            raise RedisConnectionError(f"Failed to connect to Redis: {e}")
            
    def _get_client_key(self, client_id: str) -> str:
        return f"billing:balance:{client_id}"
        
    def _get_update_channel(self, client_id: str) -> str:
        return f"billing:balance:updates:{client_id}"
        
    async def credit(self, id: str, type: Optional[str] = None, amount: float = 0):
        await self.adjust(id, type, amount, 1)
        
    async def debit(self, id: str, type: Optional[str] = None, amount: float = 0):
        await self.adjust(id, type, amount, -1)
        
    async def adjust(self, id: str, type: Optional[str], amount: float, sign: int):
        key = self._get_client_key(id)
        channel = self._get_update_channel(id)
        
        # Get amount from pricing if type is provided
        amount_ = amount
        if type is not None:
            # Get price from config
            config_data = await self.redis.get("config:data")
            if not config_data:
                raise BillingError("No configuration found")
            config = json.loads(config_data)
            price = config['billing']['prices'].get(type)
            if price is None:
                raise BillingError(f"Unknown price type: {type}")
            amount_ = price
        
        try:
            async with self.redis.pipeline() as pipe:
                while True:
                    try:
                        await pipe.watch(key)
                        current = await self.redis.get(key)
                        try:
                            current_balance = Decimal(current) if current else Decimal('0')
                        except (TypeError, ValueError) as e:
                            raise InconsistentStateError(f"Invalid balance format in Redis: {e}")
                        
                        new_balance = current_balance + Decimal(str(sign * amount_))
                        
                        pipe.multi()
                        await pipe.set(key, str(new_balance))
                        await pipe.publish(channel, str(new_balance))
                        await pipe.execute()
                        return
                        
                    except redis.WatchError:
                        continue
                    
                    except Exception as e:
                        raise RedisConnectionError(f"Redis transaction failed: {e}")
                        
        except BillingError:
            raise
        except Exception as e:
            raise RedisConnectionError(f"Unexpected Redis error: {e}")
            
    async def balance(self, id: str) -> float:
        try:
            key = self._get_client_key(id)
            balance = await self.redis.get(key)
            
            if balance is None:
                return 0
                
            try:
                return float(Decimal(balance))
            except (TypeError, ValueError) as e:
                raise InconsistentStateError(f"Invalid balance format: {e}")
                
        except BillingError:
            raise
        except Exception as e:
            raise RedisConnectionError(f"Failed to get balance: {e}")
            
    async def min_balance(self) -> float:
        try:
            config_data = await self.redis.get("config:data")
            if not config_data:
                raise BillingError("No configuration found")
            config = json.loads(config_data)
            prices = config['billing']['prices']
            return 2 * (prices['invoice'] + prices['payment'])
        except Exception as e:
            raise BillingError(f"Failed to calculate minimum balance: {e}")
