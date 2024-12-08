from typing import Dict, Any, Optional
from redis.asyncio import Redis
import json
import time
import os

class ConfigError(Exception):
    """Raised when config operations fail"""
    pass

class ConfigManager:
    def __init__(self, redis: Redis):
        self.redis = redis
        self.last_load_time = 0
        self.current_config = {}
        
    async def load_from_file(self, config_path: str) -> Dict[str, Any]:
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            raise ConfigError(f"Config file not found: {config_path}")
        except json.JSONDecodeError as e:
            raise ConfigError(f"Invalid JSON in config file: {e}")
        except Exception as e:
            raise ConfigError(f"Failed to load config file: {e}")

    def process_config(self, config: Dict[str, Any]) -> Dict[str, Any]:
       if 'inference' not in config and 'rpc' not in config:
           raise ConfigError("Config must contain either 'inference' or 'rpc' section")
               
       if 'inference' in config:
           if 'endpoints' not in config['inference']:
               raise ConfigError("Missing required 'endpoints' in inference config")
           
           endpoints = config['inference']['endpoints']
           if not endpoints:
               raise ConfigError("No inference endpoints configured")
           
           total_models = 0
           
           for endpoint_id, endpoint in endpoints.items():
               required_fields = ['api_type', 'url', 'api_key', 'models']
               missing = [field for field in required_fields if field not in endpoint]
               if missing:
                   raise ConfigError(f"Endpoint {endpoint_id} missing required fields: {', '.join(missing)}")
               if not isinstance(endpoint['models'], list):
                   raise ConfigError(f"Endpoint {endpoint_id} 'models' must be a list")
               if not endpoint['models']:
                   raise ConfigError(f"Endpoint {endpoint_id} has no models configured")
               
               total_models += len(endpoint['models'])
               
               for model in endpoint['models']:
                   required_model_fields = ['id', 'pricing']
                   missing = [field for field in required_model_fields if field not in model]
                   if missing:
                       raise ConfigError(f"Model in endpoint {endpoint_id} missing required fields: {', '.join(missing)}")
                   if 'params' not in model:
                       model['params'] = {}
                       
                   pricing = model['pricing']
                   if 'type' not in pricing:
                       raise ConfigError(f"Model {model['id']} missing required pricing type")
                       
                   required_pricing_fields = {
                       'fixed': ['input_price', 'output_price'],
                       'cost_plus': ['backend_input', 'backend_output', 'input_markup', 'output_markup'],
                       'multiplier': ['backend_input', 'backend_output', 'input_multiplier', 'output_multiplier']
                   }
                   
                   if pricing['type'] not in required_pricing_fields:
                       raise ConfigError(f"Invalid pricing type for model {model['id']}: {pricing['type']}")
                       
                   missing = [field for field in required_pricing_fields[pricing['type']]
                             if field not in pricing]
                   if missing:
                       raise ConfigError(f"Model {model['id']} pricing missing required fields: {', '.join(missing)}")
           
           if total_models == 0:
               raise ConfigError("No models configured across all endpoints")

       if 'rpc' in config:
           rpc = config['rpc']
           required_fields = ['provider_url', 'provider_key', 'prices', 'pricing']
           missing = [f for f in required_fields if f not in rpc]
           if missing:
               raise ConfigError(f"RPC config missing required fields: {', '.join(missing)}")
               
           pricing = rpc['pricing']
           required_pricing = ['base_unit', 'credit_to_usd', 'min_usd_charge']
           missing = [f for f in required_pricing if f not in pricing]
           if missing:
               raise ConfigError(f"RPC pricing missing required fields: {', '.join(missing)}")
               
       return config

    async def write_config(self, config: Dict[str, Any], force: bool = False):
        try:
            config = self.process_config(config)
            
            async with self.redis.pipeline() as pipe:
                if not force:
                    current_time = await self.redis.get("config:last_update")
                    if current_time and float(current_time) > self.last_load_time:
                        raise ValueError("Config was updated more recently by another server")
                
                timestamp = time.time()
                await pipe.set("config:data", json.dumps(config))
                await pipe.set("config:last_update", str(timestamp))
                await pipe.execute()
                
                self.current_config = config
                self.last_load_time = timestamp
                
        except Exception as e:
            raise ConfigError(f"Failed to write config: {e}")

    async def load_config(self, config_path: Optional[str] = None, force_reload: bool = False) -> Dict[str, Any]:
        try:
            if config_path:
                config = await self.load_from_file(config_path)
                await self.write_config(config, force=True)
                return config
            
            timestamp = await self.redis.get("config:last_update")
            
            if not force_reload and timestamp and self.last_load_time >= float(timestamp):
                return self.current_config
            
            config_data = await self.redis.get("config:data")
            if not config_data:
                raise ConfigError("No configuration found in Redis")
                
            config = json.loads(config_data)
            config = self.process_config(config)
            
            self.current_config = config
            self.last_load_time = float(timestamp) if timestamp else time.time()
            return config
            
        except Exception as e:
            raise ConfigError(f"Failed to load config: {e}")

    async def check_for_updates(self) -> bool:
        try:
            timestamp = await self.redis.get("config:last_update")
            if timestamp and float(timestamp) > self.last_load_time:
                await self.load_config(force_reload=True)
                return True
            return False
            
        except Exception as e:
            raise ConfigError(f"Failed to check for updates: {e}")
