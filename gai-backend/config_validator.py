import json
import sys
from typing import Dict, Any, List, Tuple, Optional
import argparse
import re
import os
from pathlib import Path

class ConfigValidationError:
    def __init__(self, path: str, message: str, fix: str = None):
        self.path = path
        self.message = message
        self.fix = fix

    def __str__(self):
        return f"{self.path}: {self.message}"

    def with_fix_suggestion(self) -> str:
        if not self.fix:
            return str(self)
        return f"{self.path}: {self.message}\n  FIX: {self.fix}"


class ConfigValidator:
    def __init__(self):
        self.errors: List[ConfigValidationError] = []
        self.warnings: List[ConfigValidationError] = []

    def add_error(self, path: str, message: str, fix: str = None):
        self.errors.append(ConfigValidationError(path, message, fix))

    def add_warning(self, path: str, message: str, fix: str = None):
        self.warnings.append(ConfigValidationError(path, message, fix))

    def is_valid(self) -> bool:
        return len(self.errors) == 0

    def validate(self, config: Dict[str, Any]) -> bool:
        """Validate the entire configuration file"""
        # Validate top-level structure
        if not isinstance(config, dict):
            self.add_error("", "Configuration must be a JSON object", 
                          "Ensure the configuration file contains a valid JSON object")
            return False

        # Make sure we have at least one of the required sections
        if "inference" not in config and "rpc" not in config and "tools" not in config:
            self.add_error("", "Configuration must contain at least one of 'inference', 'rpc', or 'tools' sections",
                          "Add at least one of 'inference', 'rpc', or 'tools' sections to your configuration")
            return False
            
        # Check for top-level api_url (required for both inference mode and tools-only mode)
        if "api_url" not in config:
            self.add_error("", "Missing required 'api_url' at top level of config",
                         "Add 'api_url' field with the inference API URL")
            
        # Validate inference section if present
        if "inference" in config:
            self._validate_inference(config["inference"])

        # Validate rpc section if present
        if "rpc" in config:
            self._validate_rpc(config["rpc"])
            
        # Return validation result
        return self.is_valid()

    def _validate_inference(self, inference: Dict[str, Any]) -> None:
        """Validate the inference section of the configuration"""
        if not isinstance(inference, dict):
            self.add_error("inference", "Inference configuration must be a JSON object",
                          "Ensure the 'inference' key contains a JSON object")
            return
            
        # api_url should be at top level but validate it here if present for backward compatibility
        if "api_url" in inference and not isinstance(inference["api_url"], str):
            self.add_error("inference.api_url", "API URL must be a string",
                          "Ensure the 'api_url' field contains a valid URL string")

        # Check if tools section is present and enabled
        tools_enabled = False
        if "tools" in inference and isinstance(inference["tools"], dict):
            tools_enabled = inference["tools"].get("enabled", False)
            
        # Only require endpoints if tools are not enabled
        if "endpoints" not in inference:
            if not tools_enabled:
                self.add_error("inference", "Missing required 'endpoints' section",
                              "Add an 'endpoints' object to the inference configuration")
            else:
                self.add_warning("inference", "Missing 'endpoints' section - running in tools-only mode",
                               "This configuration will only support tools functionality")
            # If tools are enabled, endpoints are optional, so we don't return here
            if not tools_enabled:
                return
        elif "endpoints" in inference:
            endpoints = inference["endpoints"]
            if not isinstance(endpoints, dict):
                self.add_error("inference.endpoints", "Endpoints must be a JSON object",
                              "Ensure 'endpoints' is a JSON object with endpoint configurations")
                return

            if not endpoints:
                if not tools_enabled:
                    self.add_error("inference.endpoints", "No inference endpoints configured",
                                  "Add at least one endpoint configuration")
                else:
                    self.add_warning("inference.endpoints", "Empty endpoints object - running in tools-only mode",
                                   "This configuration will only support tools functionality")
                if not tools_enabled:
                    return

            # Count total models across all endpoints
            total_models = 0
            
            # Validate each endpoint
            for endpoint_id, endpoint in endpoints.items():
                self._validate_endpoint(endpoint_id, endpoint)
                
                # Count models in valid endpoints
                if isinstance(endpoint, dict) and "models" in endpoint and isinstance(endpoint["models"], list):
                    total_models += len(endpoint["models"])
            
            # Check if there are any models configured
            if total_models == 0 and "endpoints" in inference and endpoints and not tools_enabled:
                self.add_error("inference.endpoints", "No models configured across all endpoints",
                              "Add at least one model to an endpoint configuration")

        # Validate tools section if present
        if "tools" in inference:
            self._validate_tools(inference["tools"])

    def _validate_endpoint(self, endpoint_id: str, endpoint: Dict[str, Any]) -> None:
        """Validate an individual endpoint configuration"""
        if not isinstance(endpoint, dict):
            self.add_error(f"inference.endpoints.{endpoint_id}", "Endpoint configuration must be a JSON object",
                          "Ensure the endpoint configuration is a JSON object")
            return

        # Required fields for all endpoints
        required_fields = ["api_type", "url", "models"]
        
        # Check api_key (which may be provided from environment)
        if "api_key" not in endpoint:
            required_fields.append("api_key")
            self.add_warning(f"inference.endpoints.{endpoint_id}", 
                           "No 'api_key' found - will need to be provided via environment variable",
                           f"Either add 'api_key' field or set it in {os.environ.get('ORCHID_GENAI_API_KEYS_ENV', 'ORCHID_GENAI_API_KEYS')} environment variable")
        
        # Check for required fields
        for field in required_fields:
            if field not in endpoint:
                self.add_error(f"inference.endpoints.{endpoint_id}", f"Missing required field '{field}'",
                              f"Add '{field}' to the endpoint configuration")

        # Validate models list
        if "models" in endpoint:
            models = endpoint["models"]
            if not isinstance(models, list):
                self.add_error(f"inference.endpoints.{endpoint_id}.models", "Models must be a list",
                              "Change 'models' to be a JSON array")
                return
                
            if not models:
                self.add_error(f"inference.endpoints.{endpoint_id}.models", "No models configured for this endpoint",
                              "Add at least one model configuration to the 'models' array")
                return
                
            # Validate each model
            for i, model in enumerate(models):
                self._validate_model(endpoint_id, i, model)

    def _validate_model(self, endpoint_id: str, index: int, model: Dict[str, Any]) -> None:
        """Validate an individual model configuration"""
        if not isinstance(model, dict):
            self.add_error(f"inference.endpoints.{endpoint_id}.models[{index}]", "Model configuration must be a JSON object",
                          "Ensure the model configuration is a JSON object")
            return

        # Required fields for all models
        required_fields = ["id", "pricing"]
        
        # Check for required fields
        for field in required_fields:
            if field not in model:
                self.add_error(f"inference.endpoints.{endpoint_id}.models[{index}]", f"Missing required field '{field}'",
                              f"Add '{field}' to the model configuration")
        
        # Add params if missing (not an error, will be added automatically)
        if "params" not in model:
            self.add_warning(f"inference.endpoints.{endpoint_id}.models[{index}]", "Missing 'params' field (will be added automatically)",
                           "Add a 'params' object to specify model parameters")
        
        # Validate pricing if present
        if "pricing" in model:
            self._validate_pricing(endpoint_id, index, model["pricing"])

    def _validate_pricing(self, endpoint_id: str, model_index: int, pricing: Dict[str, Any]) -> None:
        """Validate a model's pricing configuration"""
        base_path = f"inference.endpoints.{endpoint_id}.models[{model_index}].pricing"
        
        if not isinstance(pricing, dict):
            self.add_error(base_path, "Pricing configuration must be a JSON object",
                          "Ensure the pricing configuration is a JSON object")
            return
            
        # Pricing type is required
        if "type" not in pricing:
            self.add_error(base_path, "Missing required field 'type'",
                          "Add 'type' field with one of: 'fixed', 'cost_plus', or 'multiplier'")
            return
            
        pricing_type = pricing["type"]
        
        # Required fields based on pricing type
        required_pricing_fields = {
            "fixed": ["input_price", "output_price"],
            "cost_plus": ["backend_input", "backend_output", "input_markup", "output_markup"],
            "multiplier": ["backend_input", "backend_output", "input_multiplier", "output_multiplier"]
        }
        
        if pricing_type not in required_pricing_fields:
            self.add_error(f"{base_path}.type", f"Invalid pricing type: '{pricing_type}'",
                          "Change 'type' to one of: 'fixed', 'cost_plus', or 'multiplier'")
            return
            
        # Check for required fields based on pricing type
        for field in required_pricing_fields[pricing_type]:
            if field not in pricing:
                self.add_error(f"{base_path}", f"Missing required field '{field}' for pricing type '{pricing_type}'",
                              f"Add '{field}' to the pricing configuration")

    def _validate_tools(self, tools: Dict[str, Any]) -> None:
        """Validate the tools section of the configuration"""
        if not isinstance(tools, dict):
            self.add_error("inference.tools", "Tools configuration must be a JSON object",
                          "Ensure the 'tools' key contains a JSON object")
            return
            
        # Check if tools are enabled
        if "enabled" not in tools:
            self.add_warning("inference.tools", "Missing 'enabled' field (defaults to false)",
                           "Add 'enabled: true' to activate tools")
            
        if tools.get("enabled", False) == False:
            # If tools are disabled, no need to validate further
            return
            
        # Validate MCP servers if present
        if "mcp_servers" in tools:
            self._validate_mcp_servers(tools["mcp_servers"])
            
        # Validate tool registry if present
        if "registry" in tools:
            self._validate_tool_registry(tools["registry"])
        else:
            self.add_warning("inference.tools", "Tools are enabled but no 'registry' is defined",
                           "Add a 'registry' object to define available tools")

    def _validate_mcp_servers(self, servers: Dict[str, Any]) -> None:
        """Validate MCP servers configuration"""
        if not isinstance(servers, dict):
            self.add_error("inference.tools.mcp_servers", "MCP servers configuration must be a JSON object",
                          "Ensure 'mcp_servers' is a JSON object with server configurations")
            return
            
        if not servers:
            self.add_warning("inference.tools.mcp_servers", "No MCP servers configured",
                           "Add at least one MCP server configuration")
            return
            
        # Validate each server
        for server_id, server in servers.items():
            if not isinstance(server, dict):
                self.add_error(f"inference.tools.mcp_servers.{server_id}", "Server configuration must be a JSON object",
                              "Ensure the server configuration is a JSON object")
                continue
                
            # Required fields for MCP servers
            required_fields = ["command", "args"]
            for field in required_fields:
                if field not in server:
                    self.add_error(f"inference.tools.mcp_servers.{server_id}", f"Missing required field '{field}'",
                                  f"Add '{field}' to the server configuration")
                                  
            # args must be an array
            if "args" in server and not isinstance(server["args"], list):
                self.add_error(f"inference.tools.mcp_servers.{server_id}.args", "Args must be a list",
                              "Change 'args' to be a JSON array")

    def _validate_tool_registry(self, registry: Dict[str, Any]) -> None:
        """Validate the tool registry configuration"""
        if not isinstance(registry, dict):
            self.add_error("inference.tools.registry", "Tool registry must be a JSON object",
                          "Ensure 'registry' is a JSON object with tool configurations")
            return
            
        if not registry:
            self.add_warning("inference.tools.registry", "No tools configured in registry",
                           "Add at least one tool configuration")
            return
            
        # Validate each tool
        for tool_id, tool in registry.items():
            self._validate_tool_definition(tool_id, tool)

    def _validate_tool_definition(self, tool_id: str, tool: Dict[str, Any]) -> None:
        """Validate an individual tool definition"""
        base_path = f"inference.tools.registry.{tool_id}"
        
        if not isinstance(tool, dict):
            self.add_error(base_path, "Tool configuration must be a JSON object",
                          "Ensure the tool configuration is a JSON object")
            return
            
        # Check if tool is enabled
        if "enabled" in tool and not tool["enabled"]:
            # If tool is explicitly disabled, no need to validate further
            return
            
        # Tool type is required
        if "type" not in tool:
            self.add_error(base_path, "Missing required field 'type'",
                          "Add 'type' field with one of: 'python', 'mcp'")
            return
            
        tool_type = tool["type"]
        if tool_type not in ["python", "mcp"]:
            self.add_error(f"{base_path}.type", f"Invalid tool type: '{tool_type}'",
                          "Change 'type' to one of: 'python', 'mcp'")
            return
            
        # Validate based on tool type
        if tool_type == "python":
            # Python tools require a module
            if "module" not in tool:
                self.add_error(base_path, "Python tool missing required field 'module'",
                              "Add 'module' field specifying the Python module path")
        elif tool_type == "mcp":
            # MCP tools require a server
            if "server" not in tool:
                self.add_error(base_path, "MCP tool missing required field 'server'",
                              "Add 'server' field referencing an MCP server from mcp_servers")
                              
        # Parameters must be an object with JSON Schema format
        if "parameters" in tool:
            self._validate_tool_parameters(base_path, tool["parameters"])

    def _validate_tool_parameters(self, base_path: str, parameters: Dict[str, Any]) -> None:
        """Validate a tool's parameters schema"""
        if not isinstance(parameters, dict):
            self.add_error(f"{base_path}.parameters", "Parameters must be a JSON object",
                          "Ensure 'parameters' is a JSON object with JSON Schema format")
            return
            
        # Basic JSON Schema validation
        if "type" not in parameters:
            self.add_error(f"{base_path}.parameters", "Missing 'type' in parameters schema",
                          "Add 'type': 'object' to parameters schema")
            
        if parameters.get("type") != "object":
            self.add_error(f"{base_path}.parameters.type", "Parameters schema must have 'type': 'object'",
                          "Change 'type' to 'object'")
            
        if "properties" not in parameters:
            self.add_error(f"{base_path}.parameters", "Missing 'properties' in parameters schema",
                          "Add 'properties' object defining parameter fields")

    def _validate_rpc(self, rpc: Dict[str, Any]) -> None:
        """Validate the RPC section of the configuration"""
        if not isinstance(rpc, dict):
            self.add_error("rpc", "RPC configuration must be a JSON object",
                          "Ensure the 'rpc' key contains a JSON object")
            return
            
        # Required fields for RPC
        required_fields = ["provider_url", "provider_key", "prices", "pricing"]
        for field in required_fields:
            if field not in rpc:
                self.add_error("rpc", f"Missing required field '{field}'",
                              f"Add '{field}' to the RPC configuration")
                
        # Validate pricing if present
        if "pricing" in rpc:
            pricing = rpc["pricing"]
            if not isinstance(pricing, dict):
                self.add_error("rpc.pricing", "Pricing must be a JSON object",
                              "Ensure 'pricing' is a JSON object")
                return
                
            # Required pricing fields
            required_pricing = ["base_unit", "credit_to_usd", "min_usd_charge"]
            for field in required_pricing:
                if field not in pricing:
                    self.add_error("rpc.pricing", f"Missing required field '{field}'",
                                  f"Add '{field}' to the pricing configuration")


def print_validation_results(validator: ConfigValidator, json_file: str, format_json: bool = False) -> None:
    """Print validation results with error locations and suggested fixes"""
    print(f"\nValidation results for {json_file}:\n")
    
    if validator.is_valid() and not validator.warnings:
        print("✅ Configuration is valid! No errors or warnings found.")
        return
        
    if validator.is_valid():
        print("✅ Configuration is valid, but has warnings:")
    else:
        print("❌ Configuration is invalid. Please fix the following errors:")
        
    # Print errors
    if validator.errors:
        print("\nERRORS:")
        for error in validator.errors:
            print(f"  ❌ {error.with_fix_suggestion()}")
            
    # Print warnings
    if validator.warnings:
        print("\nWARNINGS:")
        for warning in validator.warnings:
            print(f"  ⚠️ {warning.with_fix_suggestion()}")
            
    # Print next steps
    if not validator.is_valid():
        if format_json:
            print("\nAfter fixing errors, you can format your JSON with:")
            print(f"  python {sys.argv[0]} {json_file} --format")
            
        print("\nRun this validator again after making changes to ensure all issues are resolved.")


def format_json_file(file_path: str) -> None:
    """Format a JSON file with consistent indentation and sorting"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2, sort_keys=True)
            
        print(f"✅ Successfully formatted {file_path}")
    except Exception as e:
        print(f"❌ Error formatting {file_path}: {str(e)}")


def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Validate GAI-Backend configuration files')
    parser.add_argument('config_file', help='Path to the configuration file')
    parser.add_argument('--format', action='store_true', help='Format the JSON file after validation')
    args = parser.parse_args()
    
    try:
        # Load the config file
        with open(args.config_file, 'r') as f:
            config = json.load(f)
        
        # Create validator and validate config
        validator = ConfigValidator()
        is_valid = validator.validate(config)
        
        # Print validation results
        print_validation_results(validator, args.config_file, args.format)
        
        # Format the JSON file if requested and valid
        if args.format and is_valid:
            format_json_file(args.config_file)
            
        # Return appropriate exit code
        sys.exit(0 if is_valid else 1)
        
    except json.JSONDecodeError as e:
        line_no = e.lineno
        column = e.colno
        print(f"\n❌ Invalid JSON in {args.config_file}:")
        print(f"  Error at line {line_no}, column {column}: {e.msg}")
        
        # Try to show the problematic line for context
        try:
            with open(args.config_file, 'r') as f:
                lines = f.readlines()
                if 0 <= line_no - 1 < len(lines):
                    print("\nProblematic line:")
                    line = lines[line_no - 1]
                    print(f"  {line.rstrip()}")
                    print(f"  {' ' * (column - 1)}^")
                    
                    # Suggest fix
                    print("\nFIX: Correct the JSON syntax error at the indicated position.")
                    print("Common issues include:")
                    print("  - Missing or extra commas")
                    print("  - Missing quotes around property names")
                    print("  - Unmatched brackets or braces")
                    print("  - Trailing commas in arrays or objects")
        except Exception:
            pass
            
        sys.exit(1)
        
    except FileNotFoundError:
        print(f"\n❌ File not found: {args.config_file}")
        sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ Error validating {args.config_file}: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()