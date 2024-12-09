import 'package:orchid/orchid/orchid.dart';
import 'chat_message.dart';
import 'model_api.dart';

// Core model information for the chat system.
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final String apiType;

  ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiType,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json, String providerId) {
    return ModelInfo(
      id: json['id'],
      name: json['name'],
      provider: providerId,
      apiType: json['api_type'],
    );
  }

  // Format a chat message for this model.
  Map<String, String> formatMessage(ChatMessage message) {
    return ModelAPI.formatMessage(message, id);
  }

  // Format chat messages for this model.
  List<Map<String, String>> formatMessages(List<ChatMessage> messages) {
    return ModelAPI.formatMessages(messages, id);
  }

  @override
  String toString() => 'ModelInfo(id: $id, name: $name, provider: $provider)';
}
