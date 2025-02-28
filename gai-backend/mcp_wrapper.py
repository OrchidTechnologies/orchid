"""
Simplified MCP implementation for direct subprocess communication.
This bypasses the SDK and uses direct JSON-RPC communication.
"""
import json
import logging
import asyncio
import subprocess
from typing import Dict, Any, Optional, List
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)

@asynccontextmanager
async def create_mcp_server(command, args, env=None):
    """
    Start an MCP server and manage its lifecycle.
    
    Args:
        command: Server command (e.g., 'node')
        args: Command arguments
        env: Environment variables
        
    Yields:
        A connected server process
    """
    logger.info(f"Starting MCP server process: {command} {' '.join(args)}")
    
    # Start the server process
    process = subprocess.Popen(
        [command] + args,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env
    )
    
    try:
        # Wait for startup message with a short timeout using both stdout and stderr
        logger.info("Waiting for server startup")
        import select
        
        # Set a timeout for the startup message
        timeout_seconds = 5
        start_time = asyncio.get_event_loop().time()
        startup_msg = None
        
        # Non-blocking check for output
        readable, _, _ = select.select([process.stdout, process.stderr], [], [], 0.1)
        
        # Check stderr for any messages
        if process.stderr in readable:
            stderr_msg = process.stderr.readline().strip()
            if stderr_msg:
                # Look for startup indicators in the stderr message
                if "MCP server running" in stderr_msg or "running on stdio" in stderr_msg:
                    logger.info(f"Server startup message (from stderr): {stderr_msg}")
                    startup_msg = stderr_msg
                else:
                    logger.warning(f"Server stderr: {stderr_msg}")
        
        # Also check stdout for startup messages
        if process.stdout in readable:
            stdout_msg = process.stdout.readline().strip()
            if stdout_msg:
                logger.info(f"Server startup message (from stdout): {stdout_msg}")
                startup_msg = stdout_msg
        
        # If we got a message, note that startup was successful
        if startup_msg:
            logger.info("Server startup successful")
        else:
            logger.info("No explicit startup message detected, but proceeding anyway")
        
        # Yield the process for use
        yield process
    finally:
        # Clean up the process
        logger.info("Terminating MCP server process")
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            logger.warning("MCP server process did not terminate gracefully, killing")
            process.kill()

class MCPSession:
    """
    A direct implementation of MCP using subprocess.
    This works directly with the JSON-RPC protocol without the SDK.
    """
    
    def __init__(self, process):
        """Initialize with a running MCP server process"""
        self.process = process
        self.request_id = 1
        
    @classmethod
    async def create(cls, process):
        """
        Create and initialize an MCP session
        
        Args:
            process: A running MCP server process
            
        Returns:
            An initialized MCPSession
        """
        try:
            logger.debug("Creating direct MCP session")
            session = cls(process)
            
            # Initialize the session
            await session._initialize()
            
            return session
                
        except Exception as e:
            logger.error(f"Error initializing MCP session: {e}", exc_info=True)
            raise
            
    async def _initialize(self):
        """Initialize the MCP session with direct JSON-RPC"""
        logger.debug("Initializing MCP session")
        
        # Send initialization request
        init_request = {
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "clientInfo": {
                    "name": "orchid-client",
                    "version": "1.0.0"
                },
                "capabilities": {
                    "tools": {}
                }
            },
            "id": self.request_id
        }
        self.request_id += 1
        
        logger.debug("Sending initialize request")
        self.process.stdin.write(json.dumps(init_request) + "\n")
        self.process.stdin.flush()
        
        # Read response
        logger.debug("Waiting for initialize response")
        init_response = self.process.stdout.readline()
        logger.debug(f"Got initialize response: {init_response}")
        
        # Send initialized notification
        init_notification = {
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }
        logger.debug("Sending initialized notification")
        self.process.stdin.write(json.dumps(init_notification) + "\n")
        self.process.stdin.flush()
        
        # Give server a moment to process
        await asyncio.sleep(0.5)
        
        logger.debug("MCP session initialized successfully")
    
    async def list_tools(self) -> List[Dict[str, Any]]:
        """
        List available tools from the MCP server
        
        Returns:
            List of tool definitions
        """
        try:
            logger.debug("Listing MCP tools")
            
            # Create list request
            list_request = {
                "jsonrpc": "2.0",
                "method": "tools/list",
                "params": {},
                "id": self.request_id
            }
            self.request_id += 1
            
            # Send request
            logger.debug("Sending tools/list request")
            self.process.stdin.write(json.dumps(list_request) + "\n")
            self.process.stdin.flush()
            
            # Read response
            logger.debug("Waiting for tools/list response")
            list_response = self.process.stdout.readline()
            logger.debug(f"Got tools/list response: {list_response}")
            
            # Parse response
            try:
                if not list_response.strip():
                    logger.error("Empty response from MCP server when listing tools")
                    return []
                    
                response_data = json.loads(list_response)
                if "error" in response_data:
                    logger.error(f"Error listing tools: {response_data['error']}")
                    return []
                    
                if "result" in response_data and "tools" in response_data["result"]:
                    tools = response_data["result"]["tools"]
                    tool_names = [tool.get('name', 'unnamed') for tool in tools]
                    logger.info(f"Found {len(tools)} tools: {tool_names}")
                    
                    # Convert to the expected structure for tool_registry
                    # The tool registry expects objects with a name attribute, not dictionaries
                    class ToolObj:
                        def __init__(self, name, description):
                            self.name = name
                            self.description = description
                    
                    # Create proper tool objects
                    tool_objects = []
                    for tool in tools:
                        tool_obj = ToolObj(
                            name=tool.get('name', 'unnamed'),
                            description=tool.get('description', '')
                        )
                        tool_objects.append(tool_obj)
                    
                    # We return this for tool_registry compatibility
                    class ToolsResponse:
                        def __init__(self, tools):
                            self.tools = tools
                    
                    return ToolsResponse(tool_objects)
                    
                logger.warning("No tools found in MCP server response")
                return []
                
            except json.JSONDecodeError:
                logger.error("Could not parse tools response as JSON")
                return []
                
        except Exception as e:
            logger.error(f"Error listing MCP tools: {e}", exc_info=True)
            return []
            
    async def call_tool(self, name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """
        Call a tool with the given arguments
        
        Args:
            name: Name of the tool to call
            arguments: Arguments to pass to the tool
            
        Returns:
            Tool execution result
        """
        try:
            # Log tool arguments at a higher level for debugging
            logger.info(f"Tool call to {name} with arguments: {json.dumps(arguments)}")
            
            logger.debug(f"Calling MCP tool {name} with arguments: {arguments}")
            
            # Create call request
            call_request = {
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": {
                    "name": name,
                    "arguments": arguments
                },
                "id": self.request_id
            }
            self.request_id += 1
            
            # Send request
            logger.debug("Sending tools/call request")
            self.process.stdin.write(json.dumps(call_request) + "\n")
            self.process.stdin.flush()
            
            # Read response
            logger.debug("Waiting for tools/call response")
            call_response = self.process.stdout.readline()
            
            # Truncate long responses in logs
            log_response = call_response[:1000] + "..." if len(call_response) > 1000 else call_response
            logger.debug(f"Got tools/call response (truncated): {log_response}")
            
            # Parse response
            try:
                response_data = json.loads(call_response)
                if "error" in response_data:
                    error_msg = response_data.get("error", {}).get("message", "Unknown error")
                    logger.error(f"Error calling tool {name}: {error_msg}")
                    return {"content": [{"type": "text", "text": f"Error: {error_msg}"}]}
                    
                if "result" in response_data:
                    result = response_data["result"]
                    
                    # Check for any content truncation and log it
                    if "content" in result:
                        for content in result["content"]:
                            if content.get("type") == "text":
                                text = content.get("text", "")
                                
                                # Look for any truncation indicators
                                if "<e>Content truncated" in text:
                                    logger.info(f"Detected content truncation in tool result for {name}")
                    
                    return result
                    
                logger.warning(f"No result found in tool call response for {name}")
                return {"content": [{"type": "text", "text": "No result returned from tool"}]}
                
            except json.JSONDecodeError:
                logger.error("Could not parse tool call response as JSON")
                return {"content": [{"type": "text", "text": "Error: Invalid response format"}]}
                
        except Exception as e:
            logger.error(f"Error calling MCP tool {name}: {e}", exc_info=True)
            return {"content": [{"type": "text", "text": f"Error: {str(e)}"}]}