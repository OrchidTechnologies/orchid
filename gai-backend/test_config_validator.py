import unittest
import json
import tempfile
import os
import copy
from config_validator import ConfigValidator

# Helper function to add api_url to test configs
def add_api_url(config):
    """Add api_url to config if not present"""
    if isinstance(config, dict) and "api_url" not in config:
        config_copy = copy.deepcopy(config)
        config_copy["api_url"] = "https://api.example.com/v1"
        return config_copy
    return config

class TestConfigValidator(unittest.TestCase):
    def test_valid_config(self):
        # A minimal valid config with top-level api_url
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertTrue(is_valid)
        self.assertEqual(len(validator.errors), 0)
        
    def test_missing_endpoints(self):
        # Missing endpoints section
        config = add_api_url({
            "inference": {}
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertEqual(len(validator.errors), 1)
        self.assertIn("endpoints", validator.errors[0].message)
        
    def test_empty_endpoints(self):
        # Empty endpoints object
        config = add_api_url({
            "inference": {
                "endpoints": {}
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertEqual(len(validator.errors), 1)
        self.assertIn("No inference endpoints configured", validator.errors[0].message)
        
    def test_missing_required_endpoint_fields(self):
        # Missing required fields in endpoint
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "missing_fields": {}
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        # Should have errors for api_type, url, models, and maybe api_key
        self.assertGreaterEqual(len(validator.errors), 3)
        
    def test_invalid_model_format(self):
        # Invalid models format (not a list)
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": "not-a-list"
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Models must be a list", validator.errors[0].message)
        
    def test_empty_models(self):
        # Empty models list
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": []
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("No models configured", validator.errors[0].message)
        
    def test_missing_model_required_fields(self):
        # Missing required fields in model
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                # Missing id and pricing
                            }
                        ]
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        # Should have errors for id and pricing
        self.assertGreaterEqual(len(validator.errors), 2)
        
    def test_invalid_pricing_type(self):
        # Invalid pricing type
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "invalid-type",
                                }
                            }
                        ]
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Invalid pricing type", validator.errors[0].message)
        
    def test_missing_pricing_fields(self):
        # Missing required pricing fields
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    # Missing input_price and output_price
                                }
                            }
                        ]
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        # Should have errors for missing input_price and output_price
        self.assertGreaterEqual(len(validator.errors), 1)
        
    def test_tools_validation(self):
        # Test tools validation
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                },
                "tools": {
                    "enabled": True,
                    "registry": {
                        "missing_type_tool": {
                            # Missing type field
                        }
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Missing required field 'type'", validator.errors[0].message)
        
    def test_invalid_tool_type(self):
        # Test invalid tool type
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                },
                "tools": {
                    "enabled": True,
                    "registry": {
                        "invalid_type_tool": {
                            "type": "invalid-type"
                        }
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Invalid tool type", validator.errors[0].message)
        
    def test_missing_module_for_python_tool(self):
        # Test missing module for Python tool
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                },
                "tools": {
                    "enabled": True,
                    "registry": {
                        "missing_module_tool": {
                            "type": "python"
                            # Missing module field
                        }
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Python tool missing required field 'module'", validator.errors[0].message)
        
    def test_missing_server_for_mcp_tool(self):
        # Test missing server for MCP tool
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                },
                "tools": {
                    "enabled": True,
                    "registry": {
                        "missing_server_tool": {
                            "type": "mcp"
                            # Missing server field
                        }
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("MCP tool missing required field 'server'", validator.errors[0].message)
        
    def test_invalid_tool_parameters(self):
        # Test invalid tool parameters
        config = add_api_url({
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                },
                "tools": {
                    "enabled": True,
                    "registry": {
                        "invalid_params_tool": {
                            "type": "python",
                            "module": "some_module",
                            "parameters": {
                                "type": "string"  # Should be "object"
                            }
                        }
                    }
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        self.assertIn("Parameters schema must have 'type': 'object'", validator.errors[0].message)
        
    def test_rpc_validation(self):
        # Test RPC validation
        config = add_api_url({
            "rpc": {
                # Missing required fields
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        # Should have errors for missing provider_url, provider_key, prices, pricing
        self.assertGreaterEqual(len(validator.errors), 4)
        
    def test_rpc_pricing_validation(self):
        # Test RPC pricing validation
        config = add_api_url({
            "rpc": {
                "provider_url": "https://example.com",
                "provider_key": "key123",
                "prices": {},
                "pricing": {
                    # Missing required fields
                }
            }
        })
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        self.assertFalse(is_valid)
        # Should have errors for missing base_unit, credit_to_usd, min_usd_charge
        self.assertGreaterEqual(len(validator.errors), 3)
        
    def test_from_file(self):
        # Test validation from a file
        config = {
            "api_url": "https://api.example.com/v1",
            "inference": {
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        # Write config to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, mode='w', suffix='.json') as temp:
            json.dump(config, temp)
            temp_path = temp.name
            
        try:
            # Test validation using config_validator.py script
            exit_code = os.system(f"python config_validator.py {temp_path}")
            self.assertEqual(exit_code, 0)  # Should exit with code 0 for valid config
            
            # Corrupt the file to make it invalid JSON
            with open(temp_path, 'a') as f:
                f.write("This is not valid JSON")
                
            # Test validation of invalid JSON
            exit_code = os.system(f"python config_validator.py {temp_path}")
            self.assertNotEqual(exit_code, 0)  # Should exit with non-zero code for invalid config
            
        finally:
            # Clean up
            if os.path.exists(temp_path):
                os.unlink(temp_path)


    def test_tools_only_mode(self):
        # Test configuration with tools but no endpoints (tools-only mode)
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
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        # Should be valid with a warning
        self.assertTrue(is_valid)
        self.assertEqual(len(validator.errors), 0)
        self.assertGreaterEqual(len(validator.warnings), 1)
        
    def test_tools_only_with_empty_endpoints(self):
        # Test configuration with tools and empty endpoints (tools-only mode)
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
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        # Should be valid with a warning
        self.assertTrue(is_valid)
        self.assertEqual(len(validator.errors), 0)
        self.assertGreaterEqual(len(validator.warnings), 1)

    def test_missing_top_level_api_url(self):
        # Test configuration missing top-level api_url
        config = {
            "inference": {
                "api_url": "https://api.example.com/v1",  # This is in the wrong place per new format
                "endpoints": {
                    "anthropic": {
                        "api_type": "anthropic",
                        "url": "https://api.anthropic.com/v1/messages",
                        "api_key": "sk-ant-key123",
                        "models": [
                            {
                                "id": "claude-3-sonnet-20240229",
                                "pricing": {
                                    "type": "fixed",
                                    "input_price": 3000,
                                    "output_price": 15000
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        # Should be invalid due to missing top-level api_url
        self.assertFalse(is_valid)
        self.assertGreaterEqual(len(validator.errors), 1)
        api_url_error = False
        for error in validator.errors:
            if "api_url" in error.message and "top level" in error.message:
                api_url_error = True
        self.assertTrue(api_url_error, "Should have an error about missing top-level api_url")

    def test_top_level_tools(self):
        # Test configuration with tools at top level (not in inference section)
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
        
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        # Should be valid with a warning
        self.assertTrue(is_valid)
        self.assertEqual(len(validator.errors), 0)

if __name__ == '__main__':
    unittest.main()
