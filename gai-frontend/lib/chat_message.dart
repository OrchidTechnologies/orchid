
enum ChatMessageSource { client, provider, system, internal }

class ChatMessage {
  final ChatMessageSource source;
  final String msg;
  final Map<String, dynamic>? metadata;

  ChatMessage(this.source, this.msg, {this.metadata});

  String get message {
    return msg;
  }
}

