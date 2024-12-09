import 'package:orchid/api/orchid_log.dart';
import 'chat_message.dart';

class ModelAPI {
  /// Default formatting of chat messages for the inference API.
  /// Messages are rendered for the perspective of the specified model.
  /// Specifically, messages from the model are rendered with the 'assistant' role and messages from
  /// other models are rendered as 'user' messages with appropriate text labeling to distinguish "speakers".
  /// Returns a list of message maps containing role and content fields.
  /// System and internal messages are skipped.
  static List<Map<String, String>> formatMessages(
    List<ChatMessage> messages,
    String forModelId,
  ) {
    return messages
        .map((msg) {
          return formatMessage(msg, forModelId);
        })
        .toList();
  }

  /// Default formatting of chat messages for the inference API.
  /// Messages are rendered for the perspective of the specified model.
  /// Specifically, messages from the model are rendered with the 'assistant' role and messages from
  /// other models are rendered as 'user' messages with appropriate text labeling to distinguish "speakers".
  /// Returns a map containing role and content fields.
  /// Note: Formatting should be done through ModelInfo to allow for model-specific overrides.
  static Map<String, String> formatMessage(
      ChatMessage msg, String forModelId) {
    // Never send system or internal messages to the model.
    if (msg.source == ChatMessageSource.system ||
        msg.source == ChatMessageSource.internal) {
      throw UnsupportedError(
          'System and internal messages should not be sent to the model');
    }

    String role;
    String content = msg.message;

    // Map conversation messages to appropriate roles
    if (msg.source == ChatMessageSource.client) {
      role = 'user';
    } else if (msg.source == ChatMessageSource.provider) {
      if (msg.modelId == forModelId) {
        role = 'assistant';
      } else {
        // Another model's message - show as user with identification
        role = 'user';
        final modelName = msg.modelName ?? msg.modelId;
        content = '[$modelName]: $content';
      }
    } else {
      // Should never hit this due to the filter above
      throw UnsupportedError('Unexpected message source: ${msg.source}');
    }

    return {
      'role': role,
      'content': content,
    };
  }
}
