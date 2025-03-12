"""
Tool execution and billing integration.
"""
import logging
import uuid
import json
import asyncio
from typing import Dict, Any, List, Optional
from datetime import datetime

from tool_registry import ToolRegistry, ToolExecutionError
from billing import StrictRedisBilling
from inference_models import Message

logger = logging.getLogger(__name__)

class ToolExecutor:
    """
    Handles execution of tools with proper billing and tracking.
    """
    
    def __init__(self, billing: StrictRedisBilling, config: Dict[str, Any]):
        self.billing = billing
        self.config = config
        self.registry = ToolRegistry()
        self.default_timeout = config.get('inference', {}).get(
            'tools', {}).get('default_timeout_ms', 5000) / 1000
        
    async def get_tool_price(self, tool_name: str) -> float:
        """Get the price for executing a tool."""
        # Check if this is a registered tool first
        tool = self.registry.get_tool(tool_name)
        
        # Special handling for dynamically discovered MCP tools (not in registry)
        if not tool and tool_name.startswith("mcp__"):
            # For dynamically discovered tools, use default pricing
            billing_prices = self.config.get('billing', {}).get('prices', {})
            
            # Use the 'mcp_tool' billing type if exists, otherwise fallback to 'function_call'
            default_billing_type = 'mcp_tool'
            if default_billing_type not in billing_prices:
                default_billing_type = 'function_call'
                
            # Get price from billing config
            price = billing_prices.get(default_billing_type, 0.0)
            
            # For tools-only mode, reduce price to avoid balance issues
            tools_enabled = self.config.get('tools', {}).get('enabled', False) or self.config.get('inference', {}).get('tools', {}).get('enabled', False)
            endpoints_exist = bool(self.config.get('inference', {}).get('endpoints'))
            
            if tools_enabled and not endpoints_exist:
                # In tools-only mode, use minimal pricing to avoid balance issues
                price = min(price, 0.0001)
                
            logger.info(f"Using default price {price} for dynamically discovered tool: {tool_name}")
            return price
        
        # No tool found in registry or dynamic discovery
        if not tool:
            logger.warning(f"No tool found for pricing: {tool_name}, using zero price")
            return 0.0
            
        # For registered tools, get pricing from tool config
        billing_type = tool.config.get('billing_type', 'function_call')
        billing_prices = self.config.get('billing', {}).get('prices', {})
        
        # Get price from billing config
        price = billing_prices.get(billing_type, 0.0)
        
        # For tools-only mode, reduce price to avoid balance issues
        tools_enabled = self.config.get('tools', {}).get('enabled', False) or self.config.get('inference', {}).get('tools', {}).get('enabled', False)
        endpoints_exist = bool(self.config.get('inference', {}).get('endpoints'))
        
        if tools_enabled and not endpoints_exist:
            # In tools-only mode, use minimal pricing to avoid balance issues
            price = min(price, 0.0001)
            
        return price
        
    async def execute_tool_with_billing(
        self, 
        session_id: str, 
        tool_call_id: str, 
        tool_name: str, 
        arguments: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Execute a tool with proper billing and error handling.
        
        Args:
            session_id: Client session ID for billing
            tool_call_id: Unique ID for this tool call
            tool_name: Name of the tool to execute
            arguments: Arguments to pass to the tool
            context: Optional execution context
            
        Returns:
            The result of the tool execution as a string
        """
        if not context:
            context = {}
            
        # Add execution metadata to context
        context.update({
            'session_id': session_id,
            'tool_call_id': tool_call_id,
            'timestamp': datetime.now().isoformat(),
            'request_id': context.get('request_id', str(uuid.uuid4()))
        })
        
        # For dynamically discovered tools, we don't need to try to get the tool here
        # since it will be dynamically created during execution
        
        # Calculate and pre-authorize the cost
        price = await self.get_tool_price(tool_name)
        
        if price > 0:
            # Debit the account
            await self.billing.debit(session_id, amount=price)
            logger.info(f"Debited {price} from session {session_id} for tool {tool_name}")
            
        try:
            # Execute the tool with timeout
            result = await asyncio.wait_for(
                self.registry.execute_tool(tool_name, arguments, context),
                timeout=self.default_timeout
            )
            return result
            
        except asyncio.TimeoutError:
            # Get tool for display name if it exists
            tool = self.registry.get_tool(tool_name)
            display_name = tool.display_name if tool else tool_name
            
            logger.error(f"Tool execution timed out: {display_name}")
            # Refund on timeout if configured
            if price > 0 and self.config.get('inference', {}).get('tools', {}).get('refund_on_timeout', True):
                await self.billing.credit(session_id, amount=price)
                logger.info(f"Refunded {price} to session {session_id} for timed out tool {display_name}")
            return "Error: Tool execution timed out"
            
        except ToolExecutionError as e:
            # Get tool for display name if it exists
            tool = self.registry.get_tool(tool_name)
            display_name = tool.display_name if tool else tool_name
            
            logger.error(f"Tool execution error for {display_name}: {e}")
            # Refund on error if configured
            if price > 0 and self.config.get('inference', {}).get('tools', {}).get('refund_on_error', True):
                await self.billing.credit(session_id, amount=price)
                logger.info(f"Refunded {price} to session {session_id} for failed tool {display_name}")
            return f"Error: {str(e)}"
            
        except Exception as e:
            # Get tool for display name if it exists
            tool = self.registry.get_tool(tool_name)
            display_name = tool.display_name if tool else tool_name
            
            logger.error(f"Unexpected error in tool execution for {display_name}: {e}")
            # Refund on error if configured
            if price > 0 and self.config.get('inference', {}).get('tools', {}).get('refund_on_error', True):
                await self.billing.credit(session_id, amount=price)
                logger.info(f"Refunded {price} to session {session_id} for failed tool {display_name}")
            return f"Error: Unexpected error during tool execution"
            
    async def execute_all_tools(
        self, 
        session_id: str, 
        tool_calls: List[Dict[str, Any]], 
        context: Optional[Dict[str, Any]] = None
    ) -> List[Message]:
        """
        Execute multiple tool calls and construct tool response messages.
        
        Args:
            session_id: Client session ID for billing
            tool_calls: List of tool calls from the model
            context: Optional execution context
            
        Returns:
            List of tool response messages
        """
        if not context:
            context = {}
            
        # Run all tool calls in parallel
        tasks = []
        for tool_call in tool_calls:
            if tool_call["type"] == "function":
                function_call = tool_call["function"]
                try:
                    arguments = json.loads(function_call.get("arguments", "{}"))
                except json.JSONDecodeError:
                    arguments = {}
                    
                tasks.append(
                    self.execute_tool_with_billing(
                        session_id=session_id,
                        tool_call_id=tool_call["id"],
                        tool_name=function_call["name"],
                        arguments=arguments,
                        context=context
                    )
                )
                
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Construct tool response messages
        messages = []
        for tool_call, result in zip(tool_calls, results):
            # Handle exceptions
            if isinstance(result, Exception):
                content = f"Error: {str(result)}"
            else:
                content = result
                
            messages.append(Message(
                role="tool",
                content=content,
                tool_call_id=tool_call["id"]
            ))
            
        return messages