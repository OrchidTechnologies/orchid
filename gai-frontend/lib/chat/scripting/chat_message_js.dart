import 'dart:convert';
import 'package:orchid/chat/chat_message.dart';
import 'dart:js_interop';

// This mapping allows Dart to view the JS object as a typed Dart object.
@JS()
@staticInterop
@anonymous
class ChatMessageJS {
  // Factory constructor to initialize ChatMessageJS
  external factory ChatMessageJS({
    required String source,
    required String sourceName,
    required String msg,
    JSAny? metadata,
    String? modelId,
    String? modelName,
  });

  static ChatMessageJS fromChatMessage(ChatMessage chatMessage) {
    return ChatMessageJS(
      source: chatMessage.source.toString(),
      sourceName: chatMessage.sourceName,
      msg: chatMessage.msg,
      metadata: jsonEncode(chatMessage.metadata).toJS,
      modelId: chatMessage.modelId,
      modelName: chatMessage.modelName,
    );
  }

  // Map a list of ChatMessage to a list of ChatMessageJS
  static List<ChatMessageJS> fromChatMessages(List<ChatMessage> chatMessages) {
    return chatMessages.map((msg) => fromChatMessage(msg)).toList();
  }

  static ChatMessage toChatMessage(ChatMessageJS chatMessageJS) {
    return ChatMessage(
      ChatMessageSource.values.byName(chatMessageJS.source),
      chatMessageJS.msg,
      // TODO:
      // metadata: jsonDecode((chatMessageJS.metadata ?? "").toString()),
      metadata: {},
      // sourceName: '',
      // modelId: chatMessageJS.modelId,
      // modelName: chatMessageJS.modelName,
    );
  }

  // Map a list of ChatMessageJS to a list of ChatMessage
  static List<ChatMessage> toChatMessages(List<ChatMessageJS> chatMessagesJS) {
    return chatMessagesJS.map((msg) => toChatMessage(msg)).toList();
  }

}

extension ChatMessageJSExtension on ChatMessageJS {
  external String source;
  external String sourceName;
  external String msg;
  external JSAny? metadata; // json
  external String? modelId;
  external String? modelName;
}

