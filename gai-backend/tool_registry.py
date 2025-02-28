from typing import Dict, Any, List, Optional, Callable, Awaitable, Union, Type
import importlib
import inspect
import json
import logging
from mcp import ClientSession
from inference_models import FunctionDefinition, Tool

logger = logging.getLogger(__name__)

class ToolExecutionError(Exception):
    """Error occurred during tool execution"""
    pass

class ToolDefinitionError(Exception):
    """Error in tool definition"""
    pass

class BaseTool:
    """Base class for all tools"""
    
    def __init__(self, name: str, config: Dict[str, Any]):
        self.name = name
        self.config = config
        self.original_name = getattr(self, 'original_name', name)
        
    def get_definition(self) -> FunctionDefinition:
        """Return the tool definition to be exposed to the LLM"""
        raise NotImplementedError()
        
    async def execute(self, arguments: Dict[str, Any], context: Dict[str, Any]) -> str:
        """Execute the tool with the given arguments"""
        raise NotImplementedError()
        
    @property
    def is_available(self) -> bool:
        """Check if the tool is currently available"""
        return True
        
    @property
    def display_name(self) -> str:
        """
        Return the preferred name to be displayed in logs and debugging.
        This helps to identify the tool with its namespaced identifier
        and original name (if different).
        """
        if self.original_name != self.name:
            return f"{self.name} (original: {self.original_name})"
        return self.name

class PythonTool(BaseTool):
    """Tool implemented as a Python function"""
    
    def __init__(self, name: str, config: Dict[str, Any], func: Callable):
        # Generate namespaced name for internal use: python__<module_name>__<tool_name>
        module_path = config.get("module", "unknown")
        module_name = module_path.split(".")[-1]  # Use last part of module path
        namespaced_name = f"python__{module_name}__{name}"
        
        # Store original name for debugging/logging
        self.original_name = name
        
        super().__init__(namespaced_name, config)
        self.func = func
        self.description = config.get("description") or inspect.getdoc(func)
        self.parameters = config.get("parameters")
        
    def get_definition(self) -> FunctionDefinition:
        return FunctionDefinition(
            name=self.name,
            description=self.description,
            parameters=self.parameters or {
                "type": "object",
                "properties": {},
                "required": []
            }
        )
        
    async def execute(self, arguments: Dict[str, Any], context: Dict[str, Any]) -> str:
        try:
            result = self.func(arguments, context)
            if inspect.isawaitable(result):
                result = await result
            return str(result)
        except Exception as e:
            logger.error(f"Error executing Python tool {self.name} (original: {self.original_name}): {str(e)}")
            raise ToolExecutionError(f"Tool execution failed: {str(e)}")

class MCPTool(BaseTool):
    """Tool implemented via MCP protocol"""
    
    def __init__(self, name: str, config: Dict[str, Any], session):
        """
        Initialize an MCP tool
        
        Args:
            name: Tool name
            config: Tool configuration
            session: MCPSession or ClientSession instance
        """
        # Generate namespaced name for internal use: mcp__<server_name>__<tool_name>
        server = config.get("server", "unknown")
        namespaced_name = f"mcp__{server}__{name}"
        
        # Store original name for debugging/logging
        self.original_name = name
        
        super().__init__(namespaced_name, config)
        self.session = session
        self.description = config.get("description", f"Execute the {name} tool")
        self.parameters = config.get("parameters", {
            "type": "object",
            "properties": {},
            "required": []
        })
        
    def get_definition(self) -> FunctionDefinition:
        return FunctionDefinition(
            name=self.name,
            description=self.description,
            parameters=self.parameters
        )
        
    async def execute(self, arguments: Dict[str, Any], context: Dict[str, Any]) -> str:
        try:
            # Check if we have our wrapper or direct ClientSession
            logger.debug(f"Executing MCP tool {self.name} (original: {self.original_name}) with arguments: {arguments}")
            
            # For MCP tool calls, we need to use the original tool name when calling the MCP server
            tool_name = self.original_name
            
            # Handle both MCPSession and ClientSession
            from mcp_wrapper import MCPSession
            if isinstance(self.session, MCPSession):
                # Use our wrapper
                result = await self.session.call_tool(tool_name, arguments)
                
                # Extract text from content array
                if result and "content" in result:
                    text_contents = []
                    for content in result["content"]:
                        if content.get("type") == "text":
                            text_contents.append(content.get("text", ""))
                    return "\n".join(text_contents)
            elif hasattr(self.session, 'tools') and hasattr(self.session.tools, 'call'):
                # Use standard ClientSession
                response = await self.session.tools.call(tool_name, arguments)
                
                if response and hasattr(response, 'result') and hasattr(response.result, 'content'):
                    # Extract text content from MCP response
                    text_contents = []
                    for content in response.result.content:
                        if hasattr(content, 'type') and content.type == "text" and hasattr(content, 'text'):
                            text_contents.append(content.text)
                    return "\n".join(text_contents)
            elif hasattr(self.session, 'call_tool'):
                # Direct subprocess wrapper
                result = await self.session.call_tool(tool_name, arguments)
                
                # Extract text from content array
                if result and "content" in result:
                    text_contents = []
                    for content in result["content"]:
                        if content.get("type") == "text":
                            text_contents.append(content.get("text", ""))
                    return "\n".join(text_contents)
            
            return "No results found"
                
        except Exception as e:
            logger.error(f"Error executing MCP tool {self.name} (original: {self.original_name}): {str(e)}")
            raise ToolExecutionError(f"Tool execution failed: {str(e)}")

class ToolRegistry:
    """Registry for all available tools"""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ToolRegistry, cls).__new__(cls)
            cls._instance._tools = {}
            cls._instance._mcp_sessions = {}
        return cls._instance
    
    def register_tool(self, tool: BaseTool) -> None:
        """Register a new tool"""
        if tool.name in self._tools:
            logger.warning(f"Tool {tool.display_name} already registered, replacing")
        self._tools[tool.name] = tool
        logger.info(f"Registered tool: {tool.display_name}")
        
    def unregister_tool(self, name: str) -> None:
        """Unregister a tool"""
        if name in self._tools:
            logger.info(f"Unregistered tool: {self._tools[name].display_name}")
            del self._tools[name]
        
    def get_tool(self, name: str) -> Optional[BaseTool]:
        """Get a tool by name"""
        return self._tools.get(name)
        
    def list_tools(self) -> List[str]:
        """List all registered tools with their namespaced names"""
        return list(self._tools.keys())
        
    def list_tools_with_details(self) -> List[Dict[str, Any]]:
        """List all registered tools with detailed information"""
        return [
            {
                "namespaced_name": t.name,
                "original_name": getattr(t, "original_name", t.name),
                "type": t.__class__.__name__,
                "server": t.config.get("server") if hasattr(t, "config") else None,
                "module": t.config.get("module") if hasattr(t, "config") else None,
                "description": t.description if hasattr(t, "description") else None,
                "available": t.is_available,
            }
            for t in self._tools.values()
        ]
        
    def get_available_tools(self) -> List[Tool]:
        """Get all available tools in the format expected by the LLM"""
        available_tools = []
        for name, tool in self._tools.items():
            if tool.is_available:
                available_tools.append(Tool(
                    type="function",
                    function=tool.get_definition()
                ))
        return available_tools
    
    def register_mcp_session(self, name: str, session: ClientSession) -> None:
        """Register an MCP session for tool providers"""
        self._mcp_sessions[name] = session
        
    def get_mcp_session(self, name: str) -> Optional[ClientSession]:
        """Get an MCP session by name"""
        return self._mcp_sessions.get(name)
    
    async def init_from_config(self, config: Dict[str, Any]) -> None:
        """Initialize tools from configuration"""
        if not config or 'tools' not in config.get('inference', {}):
            logger.warning("No tool configuration found")
            return
            
        tool_config = config['inference']['tools']
        if not tool_config.get('enabled', False):
            logger.info("Tools are disabled in configuration")
            return
        
        logger.info(f"Initializing tools from config, enabled: {tool_config.get('enabled')}")
            
        registry = tool_config.get('registry', {})
        logger.info(f"Found {len(registry)} tools in registry configuration")
        
        # Track successfully registered tools
        successful_tools = 0
        
        for name, tool_def in registry.items():
            if not tool_def.get('enabled', True):
                logger.info(f"Tool {name} is disabled in configuration")
                continue
                
            logger.info(f"Registering tool {name} of type {tool_def.get('type')}")
                
            try:
                if tool_def.get('type') == 'python':
                    # Python tool
                    module_path = tool_def.get('module')
                    if not module_path:
                        logger.error(f"Missing module path for Python tool {name}")
                        continue
                    
                    logger.info(f"Loading Python module {module_path} for tool {name}")
                        
                    module = importlib.import_module(module_path)
                    func = getattr(module, 'execute', None)
                    if not func:
                        logger.error(f"Module {module_path} does not have an execute function")
                        continue
                        
                    self.register_tool(PythonTool(name, tool_def, func))
                    logger.info(f"Successfully registered Python tool: {name}")
                    successful_tools += 1
                    
                elif tool_def.get('type') == 'mcp':
                    # MCP tool - requires session
                    server = tool_def.get('server')
                    if not server:
                        logger.error(f"No server specified for MCP tool {name}")
                        continue
                        
                    # Detailed logging about MCP sessions
                    logger.debug(f"Available MCP sessions: {list(self._mcp_sessions.keys())}")
                    
                    # Check if we have a session for this server
                    if server not in self._mcp_sessions:
                        logger.error(f"MCP server '{server}' not found for tool {name}. Available servers: {list(self._mcp_sessions.keys())}")
                        continue
                        
                    logger.debug(f"Creating MCP tool {name} using server {server}")
                        
                    # Get session and verify it
                    session = self._mcp_sessions.get(server)
                    if not session:
                        logger.error(f"MCP session for server '{server}' is None")
                        continue
                    
                    logger.debug(f"MCP session for {server} obtained")
                    
                    # Verify the session is active before registering
                    try:
                        # Try to list tools to verify the session is working correctly
                        import asyncio
                        logger.debug(f"Testing MCP session responsiveness for {server}")
                        
                        max_retries = 2
                        retry_count = 0
                        tool_listing_success = False
                        server_tool_names = []
                        
                        while retry_count <= max_retries and not tool_listing_success:
                            try:
                                # Use a reasonable timeout to prevent hanging
                                async with asyncio.timeout(10):
                                    try:
                                        # Check what type of session we have
                                        from mcp_wrapper import MCPSession
                                        if isinstance(session, MCPSession):
                                            logger.debug(f"Using MCPSession list_tools method for {server} (attempt {retry_count+1})")
                                            tools_response = await session.list_tools()
                                        elif hasattr(session, 'tools') and hasattr(session.tools, 'list'):
                                            logger.debug(f"Using standard tools.list method for {server} (attempt {retry_count+1})")
                                            tools_response = await session.tools.list()
                                        
                                        # Check if we have tools in the response
                                        if tools_response:
                                            # Handle both object and list responses (our wrapper returns an object)
                                            if hasattr(tools_response, "tools"):
                                                tool_count = len(tools_response.tools)
                                                tool_names = [t.name for t in tools_response.tools]
                                                server_tool_names = tool_names  # Save for validation later
                                                logger.info(f"MCP server {server} has {tool_count} tools: {tool_names}")
                                                
                                                # Check for mismatches between server tools and registry
                                                registry_tools = [name for name, tool in registry.items() 
                                                                if tool.get('type') == 'mcp' and tool.get('server') == server]
                                                
                                                # Find tools in registry but not in server
                                                missing_tools = set(registry_tools) - set(tool_names)
                                                if missing_tools:
                                                    logger.error(f"MCP server {server} is missing tools defined in registry: {missing_tools}")
                                                    logger.error(f"Please update Redis config to remove these tools or fix the MCP server")
                                                
                                                # Find tools in server but not in registry
                                                unknown_tools = set(tool_names) - set(registry_tools)
                                                if unknown_tools:
                                                    logger.error(f"MCP server {server} has tools not defined in registry: {unknown_tools}")
                                                    logger.error(f"Please update Redis config to add these tools")
                                                
                                                tool_listing_success = True
                                            elif isinstance(tools_response, list) and len(tools_response) > 0:
                                                tool_count = len(tools_response)
                                                tool_names = [t.get('name', 'unnamed') for t in tools_response]
                                                server_tool_names = tool_names  # Save for validation later
                                                logger.info(f"MCP server {server} has {tool_count} tools: {tool_names}")
                                                
                                                # Process registry mismatch as above
                                                registry_tools = [name for name, tool in registry.items() 
                                                                if tool.get('type') == 'mcp' and tool.get('server') == server]
                                                
                                                missing_tools = set(registry_tools) - set(tool_names)
                                                if missing_tools:
                                                    logger.error(f"MCP server {server} is missing tools defined in registry: {missing_tools}")
                                                
                                                unknown_tools = set(tool_names) - set(registry_tools)
                                                if unknown_tools:
                                                    logger.error(f"MCP server {server} has tools not defined in registry: {unknown_tools}")
                                                
                                                tool_listing_success = True
                                            else:
                                                logger.warning(f"MCP server {server} returned unexpected tools format: {type(tools_response)}")
                                        else:
                                            logger.warning(f"MCP server {server} returned empty or invalid tools list")
                                            
                                    except Exception as e:
                                        logger.warning(f"Error listing tools for {server} (attempt {retry_count+1}): {e}")
                                
                                # If we failed but have retries left, wait a bit before trying again
                                if not tool_listing_success:
                                    retry_count += 1
                                    if retry_count <= max_retries:
                                        logger.debug(f"Waiting before retry {retry_count} for {server}")
                                        await asyncio.sleep(1.5)
                                        
                            except asyncio.TimeoutError:
                                retry_count += 1
                                logger.warning(f"Timeout listing tools for {server} (attempt {retry_count})")
                                if retry_count <= max_retries:
                                    await asyncio.sleep(1.5)
                        
                        # Verify the tool exists in the MCP server before registering
                        if name not in server_tool_names:
                            logger.error(f"Tool {name} defined in registry but not found in MCP server {server}")
                            logger.error(f"Available tools from server: {server_tool_names}")
                            logger.error(f"Skipping registration of tool {name}")
                            continue
                        
                        # Create and register the tool
                        self.register_tool(MCPTool(name, tool_def, session))
                        logger.info(f"Successfully registered MCP tool: {name}")
                        successful_tools += 1
                        
                    except Exception as e:
                        logger.error(f"Error verifying MCP session for {server}: {e}", exc_info=True)
                        continue
                    
                else:
                    logger.warning(f"Unknown tool type for {name}: {tool_def.get('type')}")
                    
            except Exception as e:
                logger.error(f"Error registering tool {name}: {str(e)}", exc_info=True)
        
        # Log summary
        logger.info(f"Tool initialization complete. Registered {successful_tools}/{len(registry)} tools")
        
        # Log a summary of registered tools
        all_tools = self.list_tools_with_details()
        tool_summary = [f"{t['namespaced_name']} (original: {t['original_name']})" for t in all_tools]
        logger.info(f"Registered tools: {', '.join(tool_summary)}")
                
    async def execute_tool(self, name: str, arguments: Dict[str, Any], 
                           context: Dict[str, Any]) -> str:
        """Execute a tool by name"""
        tool = self.get_tool(name)
        if not tool:
            # Try lookup by original name for backward compatibility
            original_name_matches = [t for t in self._tools.values() 
                                      if getattr(t, 'original_name', None) == name]
            if original_name_matches:
                tool = original_name_matches[0]
                logger.info(f"Found tool by original name {name}, mapped to namespaced name {tool.name}")
            else:
                raise ToolExecutionError(f"Tool not found: {name}")
            
        if not tool.is_available:
            raise ToolExecutionError(f"Tool is not available: {tool.display_name}")
            
        return await tool.execute(arguments, context)