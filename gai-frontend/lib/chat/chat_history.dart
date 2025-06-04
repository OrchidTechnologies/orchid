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
  
  void setMessages(List<ChatMessage> messages) {
    _messages.clear();
    _messages.addAll(messages);
  }

  // Return all messages that should be included in an inference request,
  // optionally limited to the specified model id.
  // Notice and internal messages are always excluded as they are UI notifications only.
  List<ChatMessage> getConversation({String? withModelId}) {
    return _messages
        .where((msg) {
          // Always exclude notice and internal messages
          if (msg.source == ChatMessageSource.notice || 
              msg.source == ChatMessageSource.internal) {
            return false;
          }
          
          // Always include system messages (instructions)
          if (msg.source == ChatMessageSource.system) {
            return true;
          }
          
          // Always include client messages
          if (msg.source == ChatMessageSource.client) {
            return true;
          }
          
          // Always include tool calls and tool results
          if (msg.source == ChatMessageSource.tool || 
              msg.source == ChatMessageSource.toolResult) {
            return true;
          }
          
          // For provider messages, filter by model ID if specified
          if (msg.source == ChatMessageSource.provider) {
            return (withModelId == null || msg.modelId == withModelId);
          }
          
          return false; // Default case, should not be reached
        })
        .toList();
  }
}
