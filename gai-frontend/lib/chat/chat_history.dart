import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/chat/chat_message.dart';

/// Manages chat history and prepares messages for model inference requests.
/// Supports different modes of history preparation and will eventually support
/// user-supplied preparation scripts.
class ChatHistory {
  final List<ChatMessage> _messages = [];
  
  // Built-in preparation functions
  static const String isolatedMode = 'isolated';
  static const String partyMode = 'party-mode';

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void clear() {
    _messages.clear();
  }

  /// Prepare messages for a specific model's inference request.
  /// Returns messages formatted for the chat completions API.
  List<Map<String, dynamic>> prepareForModel({
    required String modelId,
    required String preparationFunction,
  }) {
    switch (preparationFunction) {
      case isolatedMode:
        return _prepareIsolated(modelId);
      case partyMode:
        return _preparePartyMode(modelId);
      default:
        // TODO: Hook up JS engine dispatch
        throw UnimplementedError('Custom preparation functions not yet supported');
    }
  }

  /// Default preparation mode where models only see their own history
  List<Map<String, dynamic>> _prepareIsolated(String modelId) {
    final relevantMessages = _messages.where((msg) =>
      // Only include client messages and this model's responses
      (msg.source == ChatMessageSource.client) ||
      (msg.source == ChatMessageSource.provider && msg.modelId == modelId)
    );

    return _formatMessages(relevantMessages.toList(), modelId);
  }

  /// Party mode where models can see and respond to each other
  List<Map<String, dynamic>> _preparePartyMode(String modelId) {
    // Filter to only include actual conversation messages
    final relevantMessages = _messages.where((msg) =>
      msg.source == ChatMessageSource.client ||
      msg.source == ChatMessageSource.provider
    ).toList();
    
    return _formatMessages(relevantMessages, modelId);
  }

  /// Format a single message from the perspective of the target model
  List<Map<String, dynamic>> _formatMessages(List<ChatMessage> messages, String modelId) {
    return messages.map((msg) {
      // Skip internal messages entirely
      if (msg.source == ChatMessageSource.system || 
          msg.source == ChatMessageSource.internal) {
        return null;
      }

      String role;
      String content = msg.message;

      // Map conversation messages to appropriate roles
      if (msg.source == ChatMessageSource.client) {
        role = 'user';
      } else if (msg.source == ChatMessageSource.provider) {
        if (msg.modelId == modelId) {
          role = 'assistant';
        } else {
          // Another model's message - show as user with identification
          role = 'user';
          final modelName = msg.modelName ?? msg.modelId;
          content = '[$modelName]: $content';
        }
      } else {
        // Should never hit this due to the filter above
        log('Error: Unexpected message source: ${msg.source}');
        return null;
      }

      return {
        'role': role,
        'content': content,
      };
    }).whereType<Map<String, dynamic>>().toList(); // Remove any nulls from skipped messages
  }
}
