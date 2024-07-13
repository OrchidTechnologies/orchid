
enum ChatMessageSource { client, provider, system, internal }

class ChatMessage {
  final ChatMessageSource source;
  final String sourceName;
  final String msg;
  final Map<String, dynamic>? metadata;

  ChatMessage(this.source, this.msg, {this.metadata, this.sourceName = ''});

  String get message {
    return msg;
  }
}

