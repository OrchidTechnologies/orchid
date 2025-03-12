import pytest
import json
import os
from unittest.mock import patch, MagicMock, AsyncMock
from redis.asyncio import Redis
from config_manager import ConfigManager, ConfigError, ORCHID_GENAI_API_KEYS_ENV

@pytest.fixture
def mock_redis():
    return AsyncMock(spec=Redis)

@pytest.fixture
def config_manager(mock_redis):
    return ConfigManager(mock_redis)

@pytest.fixture
def sample_config():
    return {
        "api_url": "https://api.example.com/v1",
        "inference": {
            "endpoints": {
                "anthropic": {
                    "api_type": "anthropic",
                    "url": "https://api.anthropic.com/v1",
                    "api_key": "original_anthropic_key",
                    "models": [
                        {
                            "id": "claude-3-sonnet-20240229",
                            "pricing": {
                                "type": "fixed",
                                "input_price": 0.01,
                                "output_price": 0.03
                            }
                        }
                    ]
                },
                "openai": {
                    "api_type": "openai",
                    "url": "https://api.openai.com/v1",
                    "api_key": "original_openai_key",
                    "models": [
                        {
                            "id": "gpt-4",
                            "pricing": {
                                "type": "fixed",
                                "input_price": 0.03,
                                "output_price": 0.06
                            }
                        }
                    ]
                }
            }
        }
    }

class TestApiKeysFromEnvironment:
    @patch.dict(os.environ, {ORCHID_GENAI_API_KEYS_ENV: '{"anthropic": "env_anthropic_key", "openai": "env_openai_key"}'})
    def test_load_api_keys_from_env(self, config_manager):
        api_keys = config_manager._load_api_keys_from_env()
        assert api_keys == {"anthropic": "env_anthropic_key", "openai": "env_openai_key"}

    @patch.dict(os.environ, {ORCHID_GENAI_API_KEYS_ENV: '{"anthropic": "env_anthropic_key"}'})
    def test_apply_api_keys_to_config(self, config_manager, sample_config):
        api_keys = config_manager._load_api_keys_from_env()
        config_manager._apply_api_keys_to_config(sample_config, api_keys)
        
        # Check that anthropic key is updated but openai key is untouched
        assert sample_config["inference"]["endpoints"]["anthropic"]["api_key"] == "env_anthropic_key"
        assert sample_config["inference"]["endpoints"]["openai"]["api_key"] == "original_openai_key"

    @patch.dict(os.environ, {ORCHID_GENAI_API_KEYS_ENV: '{"anthropic": "env_anthropic_key", "openai": "env_openai_key"}'})
    def test_process_config_applies_env_keys(self, config_manager, sample_config):
        processed_config = config_manager.process_config(sample_config)
        
        # Check both keys are updated
        assert processed_config["inference"]["endpoints"]["anthropic"]["api_key"] == "env_anthropic_key"
        assert processed_config["inference"]["endpoints"]["openai"]["api_key"] == "env_openai_key"

    @patch.dict(os.environ, {ORCHID_GENAI_API_KEYS_ENV: 'invalid_json'})
    def test_invalid_env_json(self, config_manager, sample_config):
        processed_config = config_manager.process_config(sample_config)
        
        # Keys should remain unchanged with invalid JSON
        assert processed_config["inference"]["endpoints"]["anthropic"]["api_key"] == "original_anthropic_key"
        assert processed_config["inference"]["endpoints"]["openai"]["api_key"] == "original_openai_key"
        
    @patch.dict(os.environ, {ORCHID_GENAI_API_KEYS_ENV: '{"missing_key_endpoint": "env_api_key"}'})
    def test_missing_api_key_with_env(self, config_manager):
        # Create config with missing api_key
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "endpoints": {
                    "missing_key_endpoint": {
                        "api_type": "test",
                        "url": "https://test.com",
                        "models": [
                            {
                                "id": "model1",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 0.01,
                                    "output_price": 0.03
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        # Should not raise error since key is in environment
        processed_config = config_manager.process_config(config)
        assert processed_config["inference"]["endpoints"]["missing_key_endpoint"]["api_key"] == "env_api_key"
        
    @patch.dict(os.environ, {})
    def test_missing_api_key_without_env(self, config_manager):
        # Create config with missing api_key
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "endpoints": {
                    "missing_key_endpoint": {
                        "api_type": "test",
                        "url": "https://test.com",
                        "models": [
                            {
                                "id": "model1",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 0.01,
                                    "output_price": 0.03
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        # Should raise error since key is neither in config nor environment
        with pytest.raises(ConfigError) as excinfo:
            config_manager.process_config(config)
        assert "missing required fields: api_key" in str(excinfo.value)

class TestToolsOnlyMode:
    def test_tools_only_mode_without_endpoints(self, config_manager):
        """Test that tools-only mode works with no endpoints section"""
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "tools": {
                    "enabled": True,
                    "registry": {
                        "web_search": {
                            "type": "python",
                            "module": "some_module",
                            "enabled": True
                        }
                    }
                }
            }
        }
        
        # Should not raise error since tools are enabled
        processed_config = config_manager.process_config(config)
        # Should create empty endpoints object
        assert "endpoints" in processed_config["inference"]
        assert processed_config["inference"]["endpoints"] == {}
        
    def test_tools_only_mode_with_empty_endpoints(self, config_manager):
        """Test that tools-only mode works with empty endpoints section"""
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "endpoints": {},
                "tools": {
                    "enabled": True,
                    "registry": {
                        "web_search": {
                            "type": "python",
                            "module": "some_module",
                            "enabled": True
                        }
                    }
                }
            }
        }
        
        # Should not raise error since tools are enabled
        processed_config = config_manager.process_config(config)
        assert processed_config["inference"]["endpoints"] == {}

    def test_missing_top_level_api_url(self, config_manager):
        """Test that missing top-level api_url is rejected"""
        config = {
            "inference": {
                "api_url": "https://api.example.com/v1",  # In the wrong location
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1",
                        "api_key": "original_anthropic_key",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 0.01,
                                    "output_price": 0.03
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        # Should raise error about missing top-level api_url
        with pytest.raises(ConfigError) as excinfo:
            config_manager.process_config(config)
        assert "api_url" in str(excinfo.value)
        assert "top level" in str(excinfo.value).lower()

    def test_top_level_tools(self, config_manager):
        """Test that top-level tools configuration works"""
        config = {
            "api_url": "https://api.example.com/v1",
            "tools": {
                "enabled": True,
                "registry": {
                    "web_search": {
                        "type": "python",
                        "module": "some_module",
                        "enabled": True
                    }
                }
            }
        }
        
        # Should move tools into inference section
        processed_config = config_manager.process_config(config)
        
        # Should have created an inference section
        assert "inference" in processed_config
        # The tools should be moved to inference section
        assert "tools" in processed_config["inference"]
        assert "tools" not in processed_config  # Should be removed from top level
        # Should have empty endpoints
        assert "endpoints" in processed_config["inference"]
        assert processed_config["inference"]["endpoints"] == {}

if __name__ == "__main__":
    pytest.main(["-xvs", __file__])