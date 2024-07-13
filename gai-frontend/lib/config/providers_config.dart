import 'dart:convert';

class ProvidersConfig {
  static Map<String, Map<String, String>> getProviders() {
    final providersJson = const String.fromEnvironment('PROVIDERS', defaultValue: '{}');
    print(providersJson);
    try {
      final providers = json.decode(providersJson) as Map<String, dynamic>;
      return providers.map((key, value) => MapEntry(key, Map<String, String>.from(value)));
    } catch (e) {
      print('Error parsing providers configuration: $e');
      return {};
    }
  }
}
