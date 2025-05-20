import 'package:orchid/api/orchid_log.dart';
import 'chat_message.dart';

// Use the log function from orchid_log.dart
import 'package:orchid/api/orchid_log.dart' show log;

class ModelAPI {
  /// Format a list of chat messages for the inference API.
  /// Messages are transformed based on their source types to appropriate roles.
  /// - Notice and internal messages are filtered out
  /// - Client messages → 'user' role
  /// - Provider messages → 'assistant' role (or 'user' if from another model)
  /// - System messages → 'system' role 
  /// - Tool result messages → 'tool' role with tool_call_id
  /// 
  /// Returns a list of formatted message maps ready for sending to the API.
  static List<Map<String, dynamic>> formatMessages(
    List<ChatMessage> messages,
    String forModelId,
  ) {
    final result = <Map<String, dynamic>>[];
    
    // First validate that we have all required tool_call_ids for any tool results
    Map<String, bool> toolCallIds = {};
    
    // First pass - collect all tool call IDs from assistant messages
    for (final msg in messages) {
      if (msg.source == ChatMessageSource.provider && 
          msg.metadata != null && 
          msg.metadata!.containsKey('tool_calls')) {
        
        final toolCalls = msg.metadata!['tool_calls'] as List;
        for (final toolCall in toolCalls) {
          if (toolCall['id'] != null) {
            toolCallIds[toolCall['id']] = true;
          }
        }
      }
    }
    
    // Log all known tool call IDs
    if (toolCallIds.isNotEmpty) {
      log('Known tool call IDs: ${toolCallIds.keys.join(", ")}');
    }
    
    // Second pass - process all messages in order
    for (final msg in messages) {
      try {
        // Filter notice and internal messages
        if (msg.source == ChatMessageSource.notice || 
            msg.source == ChatMessageSource.internal) {
          continue;
        }
        
        // For tool results, verify the tool_call_id exists
        if (msg.source == ChatMessageSource.toolResult && 
            msg.metadata != null && 
            msg.metadata!.containsKey('tool_call_id')) {
          
          final tcId = msg.metadata!['tool_call_id'];
          if (!toolCallIds.containsKey(tcId)) {
            log('Warning: Tool result with id $tcId has no matching tool call in the conversation');
          }
        }
        
        // Format the message and add to result
        result.add(formatMessage(msg, forModelId));
      } catch (e) {
        // Log warning but don't fail the entire operation
        log('Warning: Skipping message that couldn\'t be formatted: ${msg.source}, error: $e');
      }
    }
    
    // Final validation and correction - remove tool results without matching tool calls
    List<Map<String, dynamic>> validatedResult = [];
    Map<String, bool> toolCallsSeen = {};
    
    // First collect all tool call IDs from assistant messages
    for (final msg in result) {
      if (msg['role'] == 'assistant' && 
          msg.containsKey('tool_calls')) {
        for (final tc in msg['tool_calls'] as List) {
          if (tc['id'] != null) {
            toolCallsSeen[tc['id']] = true;
          }
        }
      }
    }
    
    // Keep track of which tool call IDs we've already added results for
    Map<String, bool> toolResultsSeen = {};
    
    // Now we go through the sequence and validate message by message
    for (int i = 0; i < result.length; i++) {
      final msg = result[i];
      bool shouldInclude = true;
      
      // Special handling for tool results
      if (msg['role'] == 'tool' && msg.containsKey('tool_call_id')) {
        final tcId = msg['tool_call_id'];
        
        // 1. Check if this tool_call_id exists in any assistant message
        if (!toolCallsSeen.containsKey(tcId)) {
          log('Warning: Removing tool result with ID $tcId - no matching tool call in any assistant message');
          shouldInclude = false;
        } 
        // 2. Check if we've already seen a result for this tool_call_id
        else if (toolResultsSeen.containsKey(tcId)) {
          log('Warning: Removing duplicate tool result for ID $tcId');
          shouldInclude = false;
        }
        // 3. Check if there's an assistant message with this tool call before this result
        else {
          bool foundAssistant = false;
          for (int j = 0; j < i; j++) {
            final prevMsg = result[j];
            if (prevMsg['role'] == 'assistant' && 
                prevMsg.containsKey('tool_calls')) {
              for (final tc in prevMsg['tool_calls'] as List) {
                if (tc['id'] == tcId) {
                  foundAssistant = true;
                  break;
                }
              }
            }
            if (foundAssistant) break;
          }
          
          if (!foundAssistant) {
            log('Warning: Removing tool result with ID $tcId - no matching tool call in assistant messages before it');
            shouldInclude = false;
          } else {
            // Record that we've seen a result for this tool call
            toolResultsSeen[tcId] = true;
          }
        }
      }
      
      if (shouldInclude) {
        validatedResult.add(msg);
      }
    }
    
    // Log the final sequence
    if (validatedResult.length != result.length) {
      log('Removed ${result.length - validatedResult.length} invalid messages from the sequence');
      log('Final message sequence: ${validatedResult.map((m) => m['role']).join(' -> ')}');
    }
    
    return validatedResult;
  }

  /// Format chat messages for the inference API.
  /// Messages are rendered based on their source type and transformed to appropriate roles:
  /// - client → 'user'
  /// - provider → 'assistant' (or 'user' if from a different model)
  /// - system → 'system'
  /// - tool/toolResult → appropriate tool format
  /// - notice/internal → filtered out (not sent to model)
  /// 
  /// Returns a map containing role and content fields, with additional fields for tool calls.
  /// Note: Formatting should be done through ModelInfo to allow for model-specific overrides.
  static Map<String, dynamic> formatMessage(
      ChatMessage msg, String forModelId) {
    // Filter out notice and internal messages - these should never be sent to the model
    if (msg.source == ChatMessageSource.notice ||
        msg.source == ChatMessageSource.internal) {
      throw UnsupportedError(
          'Notice and internal messages should not be sent to the model');
    }

    String role;
    String content = msg.message;
    Map<String, dynamic> result = {};

    // Map messages to appropriate roles based on source
    switch (msg.source) {
      case ChatMessageSource.client:
        role = 'user';
        result = {'role': role, 'content': content};
        break;

      case ChatMessageSource.provider:
        if (msg.modelId == forModelId) {
          role = 'assistant';
          
          // Start with the basic message
          result = {'role': role, 'content': content};
          
          // CRITICAL: Include tool_calls if present in metadata
          if (msg.metadata != null && msg.metadata!.containsKey('tool_calls')) {
            // Add tool calls to the message
            result['tool_calls'] = msg.metadata!['tool_calls'];
            log('Including ${(msg.metadata!['tool_calls'] as List).length} tool calls in assistant message');
          }
        } else {
          // Another model's message - show as user with identification
          role = 'user';
          final modelName = msg.modelName ?? msg.modelId;
          content = '[$modelName]: $content';
          result = {'role': role, 'content': content};
        }
        break;

      case ChatMessageSource.system:
        // Actual system instructions for the model
        role = 'system';
        result = {'role': role, 'content': content};
        break;

      case ChatMessageSource.tool:
        // Skip tool messages - these should be handled separately
        // Their presence in the conversation is usually as part of the 
        // assistant response, not as standalone messages
        throw UnsupportedError(
            'Tool messages should be part of assistant responses, not sent directly');
        break;

      case ChatMessageSource.toolResult:
        // Tool results need special handling with the tool_call_id
        role = 'tool';
        
        // Ensure we have a tool_call_id in the metadata
        if (msg.metadata != null && msg.metadata!.containsKey('tool_call_id')) {
          result = {
            'role': role,
            'content': content,
            'tool_call_id': msg.metadata!['tool_call_id'],
            'name': msg.toolName,  // Add the tool name which is required by some models
          };
          log('Formatting tool result with tool_call_id: ${msg.metadata!['tool_call_id']}');
        } else {
          log('Warning: Tool result message missing tool_call_id: $msg');
          result = {
            'role': role,
            'content': content,
            'name': msg.toolName,
          };
        }
        break;

      default:
        throw UnsupportedError('Unexpected message source: ${msg.source}');
    }

    return result;
  }
}
