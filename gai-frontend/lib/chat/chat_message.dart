enum ChatMessageSource { client, provider, system, internal }

class ChatMessage {
  final ChatMessageSource source;
  final String sourceName;
  final String msg;
  final Map<String, dynamic>? metadata;
  final String? modelId;
  final String? modelName;

  ChatMessage(
    this.source,
    this.msg, {
    this.metadata,
    this.sourceName = '',
    this.modelId,
    this.modelName,
  });

  String get message => msg;

  String? get displayName {
    print('Getting displayName. source: $source, modelName: $modelName, sourceName: $sourceName'); // Debug what we have
    if (source == ChatMessageSource.provider && modelName != null) {
      return modelName;
    }
    if (sourceName.isNotEmpty) {
      return sourceName;
    }
    print('Returning null displayName'); // See when we hit this case
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

  @override
  String toString() {
    return 'ChatMessage(source: $source, model: $modelName, msg: ${msg.substring(0, msg.length.clamp(0, 50))}...)';
  }
}

