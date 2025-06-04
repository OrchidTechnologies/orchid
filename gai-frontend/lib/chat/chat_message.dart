import 'dart:convert';
import 'package:orchid/orchid/orchid.dart';
import 'tool_definition.dart';

enum ChatMessageSource {
  client, // Message from the user
  provider, // Message from an LLM provider
  notice, // Notice message displayed to user (formerly "system")
  internal, // Internal message (not shown to user or model)
  tool, // Tool call message
  toolResult, // Tool result message
  system, // Actual system instruction message for the LLM
}

class ChatMessage {
  final ChatMessageSource source;
  final String sourceName;
  final String
      message; // Keep as non-nullable, but handle null values when creating
  final Map<String, dynamic>? metadata;

  // The modelId of the model that generated this message
  final String? modelId;

  // The name of the model that generated this message
  final String? modelName;

  // Tool-related fields
  final String? toolName;
  final String? providerId;
  final Map<String, dynamic>? toolArguments;
  final ToolResult? toolResult;

  ChatMessage({
    required this.source,
    required this.message, // Keep as required
    this.metadata,
    this.sourceName = '',
    this.modelId,
    this.modelName,
    this.toolName,
    this.providerId,
    this.toolArguments,
    this.toolResult,
  });

  String? get displayName {
    // For tool messages
    if (source == ChatMessageSource.tool && toolName != null) {
      return 'Tool: $toolName';
    }

    // For tool result messages
    if (source == ChatMessageSource.toolResult && toolName != null) {
      return 'Result: $toolName';
    }

    // For provider messages
    if (source == ChatMessageSource.provider && modelName != null) {
      return modelName;
    }

    // For other messages with a source name
    if (sourceName.isNotEmpty) {
      return sourceName;
    }

    log('Returning null displayName'); // See when we hit this case
    return null;
  }

  String formatUsage() {
    if (metadata == null || !metadata!.containsKey('usage')) {
      return '';
    }

    final usage = metadata!['usage'];
    if (usage == null) {
      return '';
    }

    final prompt = usage['prompt_tokens'] ?? 0;
    final completion = usage['completion_tokens'] ?? 0;

    if (prompt == 0 && completion == 0) {
      return '';
    }

    return 'tokens: $prompt in, $completion out';
  }

  // Create a tool call message
  factory ChatMessage.toolCall({
    required String toolName,
    required Map<String, dynamic> arguments,
    required String providerId,
    String providerName = '',
  }) {
    // Special handling for sequentialthinking tool to format it nicely
    String formattedMessage;

    if (toolName == 'mcp__sequentialthinking__sequentialthinking') {
      // Get the thought content for sequential thinking
      final thought = arguments['thought'] ?? '';
      final thoughtNumber = arguments['thoughtNumber'] ?? 1;
      final totalThoughts = arguments['totalThoughts'] ?? 1;

      formattedMessage =
          'Sequential Thinking: Thought ${thoughtNumber}/${totalThoughts}\n\n$thought';
    } else {
      // Default formatting for other tools - with parameters
      String argsStr;
      
      if (arguments.entries.isEmpty) {
        argsStr = "(no parameters)";
      } else {
        // Format each parameter on a new line with proper indentation
        argsStr = arguments.entries.map((e) {
          var valueStr = jsonEncode(e.value);
          // Make complex objects more readable with newlines and indentation
          if (valueStr.startsWith('{') && valueStr.length > 20) {
            valueStr = valueStr.replaceAll(',"', ',\n    "')
                               .replaceAll('{"', '{\n    "')
                               .replaceAll('"}', '"\n  }');
          }
          return '  ${e.key}: $valueStr';
        }).join('\n');
      }

      formattedMessage = 'Calling tool: $toolName\n$argsStr';
    }

    // Create source name with tool info
    final String displaySourceName =
        toolName.contains('__') ? toolName.split('__').last : toolName;

    return ChatMessage(
      source: ChatMessageSource.tool,
      message: formattedMessage,
      metadata: {
        'tool_name': toolName,
        'arguments': arguments,
        'provider_id': providerId,
        'provider_name': providerName,
      },
      sourceName: displaySourceName,
      toolName: toolName,
      providerId: providerId,
      toolArguments: arguments,
    );
  }

  // Create a system instruction message for the LLM
  factory ChatMessage.systemInstruction({
    required String instruction,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      source: ChatMessageSource.system,
      message: instruction,
      metadata: metadata,
      sourceName: "System",
    );
  }
  
  // Create a notice message (user-visible notification)
  factory ChatMessage.notice({
    required String message,
    Map<String, dynamic>? metadata,
    String sourceName = "Notice",
  }) {
    return ChatMessage(
      source: ChatMessageSource.notice,
      message: message,
      metadata: metadata,
      sourceName: sourceName,
    );
  }

  // Create a tool result message
  factory ChatMessage.toolResult({
    required ToolResult result,
    String providerName = '',
    String? toolCallId,
    Map<String, dynamic>? metadata,
  }) {
    // Get the formatted text content from the tool result
    final String displayContent = result.textContent;

    // Create source name with tool info
    final String displaySourceName = result.toolName.contains('__')
        ? result.toolName.split('__').last
        : result.toolName;
        
    // For sequential thinking tool, extract and format the thought directly from raw content 
    // without modifying the metadata or raw content structure
    String displayMessage = displayContent;
    if (result.toolName == 'mcp__sequentialthinking__sequentialthinking' && 
        result.content.isNotEmpty && 
        result.content.first.text != null) {
      try {
        // Try to parse the JSON but use it only for display
        Map<String, dynamic> parsed = json.decode(result.content.first.text!);
        
        // Extract thought number and content
        final thoughtNumber = parsed['thoughtNumber'] ?? 1;
        final totalThoughts = parsed['totalThoughts'] ?? 1;
        final thought = parsed['thought'] ?? '';
        final nextNeeded = parsed['nextThoughtNeeded'] ?? false;
        
        // Format for display only
        displayMessage = 'Thought ${thoughtNumber}/${totalThoughts}:\n\n${thought}\n\n${nextNeeded ? "(continuing...)" : "(complete)"}';
        log('Sequential thinking formatted for display: Thought $thoughtNumber/$totalThoughts');
      } catch (e) {
        // If parsing fails, fallback to default
        log('Error parsing sequential thinking for display: $e');
      }
    }

    // VERY IMPORTANT: Ensure we have a valid tool_call_id for the API
    // Use the provided toolCallId first, then check the result's toolCallId
    final effectiveToolCallId = toolCallId ?? result.toolCallId;
    
    if (effectiveToolCallId == null) {
      log('WARNING: Creating ChatMessage.toolResult without tool_call_id for tool: ${result.toolName}');
    } else {
      log('Creating ChatMessage.toolResult with tool_call_id: $effectiveToolCallId');
    }
    
    // Create base metadata map
    final baseMetadata = {
      'tool_name': result.toolName,
      'arguments': result.arguments,
      'provider_id': result.providerId,
      'provider_name': providerName,
      'status_code': result.statusCode,
      'error': result.error,
      'content': result.content.map((c) => c.toJson()).toList(),
      if (effectiveToolCallId != null) 'tool_call_id': effectiveToolCallId,
    };
    
    // Merge with provided metadata if any
    final mergedMetadata = metadata != null 
        ? {...baseMetadata, ...metadata}
        : baseMetadata;
    
    return ChatMessage(
      // IMPORTANT: Make sure we use toolResult as the message source to ensure proper message formatting
      source: ChatMessageSource.toolResult,
      message: displayMessage,
      metadata: mergedMetadata,
      sourceName: "$displaySourceName Result",
      toolName: result.toolName,
      providerId: result.providerId,
      toolArguments: result.arguments,
      toolResult: result,
    );
  }

  // Clone this immutable object with new values for some fields
  ChatMessage copyWith({
    ChatMessageSource? source,
    String? message,
    Map<String, dynamic>? metadata,
    String? sourceName,
    String? modelId,
    String? modelName,
    String? toolName,
    String? providerId,
    Map<String, dynamic>? toolArguments,
    ToolResult? toolResult,
  }) {
    return ChatMessage(
      source: source ?? this.source,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      sourceName: sourceName ?? this.sourceName,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      toolName: toolName ?? this.toolName,
      providerId: providerId ?? this.providerId,
      toolArguments: toolArguments ?? this.toolArguments,
      toolResult: toolResult ?? this.toolResult,
    );
  }

  @override
  String toString() {
    final srcType = switch (source) {
      ChatMessageSource.client => 'user',
      ChatMessageSource.provider => 'provider',
      ChatMessageSource.notice => 'notice',
      ChatMessageSource.internal => 'internal',
      ChatMessageSource.tool => 'tool',
      ChatMessageSource.toolResult => 'result',
      ChatMessageSource.system => 'system',
    };

    final msgPrefix = message.substring(0, message.length.clamp(0, 50));

    if (source == ChatMessageSource.tool ||
        source == ChatMessageSource.toolResult) {
      return 'ChatMessage($srcType, tool: $toolName, msg: $msgPrefix...)';
    } else {
      return 'ChatMessage($srcType, modelId: $modelId, model: $modelName, msg: $msgPrefix...)';
    }
  }
  
  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'source': source.index,
      'sourceName': sourceName,
      'message': message,
      if (metadata != null) 'metadata': metadata,
      if (modelId != null) 'modelId': modelId,
      if (modelName != null) 'modelName': modelName,
      if (toolName != null) 'toolName': toolName,
      if (providerId != null) 'providerId': providerId,
      if (toolArguments != null) 'toolArguments': toolArguments,
      if (toolResult != null) 'toolResult': {
        'toolName': toolResult!.toolName,
        'arguments': toolResult!.arguments,
        'content': toolResult!.content.map((c) => c.toJson()).toList(),
        'statusCode': toolResult!.statusCode,
        if (toolResult!.error != null) 'error': toolResult!.error,
        'providerId': toolResult!.providerId,
        if (toolResult!.toolCallId != null) 'toolCallId': toolResult!.toolCallId,
      },
    };
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      source: ChatMessageSource.values[json['source'] as int],
      sourceName: json['sourceName'] ?? '',
      message: json['message'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      modelId: json['modelId'] as String?,
      modelName: json['modelName'] as String?,
      toolName: json['toolName'] as String?,
      providerId: json['providerId'] as String?,
      toolArguments: json['toolArguments'] as Map<String, dynamic>?,
      toolResult: json['toolResult'] != null
          ? ToolResult(
              toolName: json['toolResult']['toolName'] as String,
              arguments: json['toolResult']['arguments'] as Map<String, dynamic>,
              content: (json['toolResult']['content'] as List)
                  .map((c) => ToolResultContent.fromJson(c as Map<String, dynamic>))
                  .toList(),
              statusCode: json['toolResult']['statusCode'] as int? ?? 200,
              error: json['toolResult']['error'] as Map<String, dynamic>?,
              providerId: json['toolResult']['providerId'] as String,
              toolCallId: json['toolResult']['toolCallId'] as String?,
            )
          : null,
    );
  }
}
