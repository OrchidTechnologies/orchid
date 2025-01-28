import 'dart:convert';
import 'package:http/http.dart' as http;

class InferenceError implements Exception {
  final int statusCode;
  final String message;
  
  InferenceError(this.statusCode, this.message);
  
  @override
  String toString() => 'InferenceError($statusCode): $message';
}

class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      promptTokens: json['prompt_tokens'],
      completionTokens: json['completion_tokens'],
      totalTokens: json['total_tokens'],
    );
  }

  Map<String, dynamic> toJson() => {
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens': totalTokens,
  };
}

class ModelInfo {
  final String id;
  final String name;
  final String apiType;

  ModelInfo({
    required this.id,
    required this.name,
    required this.apiType,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'],
      name: json['name'],
      apiType: json['api_type'],
    );
  }
}

class InferenceResponse {
  final String response;
  final TokenUsage usage;

  InferenceResponse({
    required this.response,
    required this.usage,
  });

  factory InferenceResponse.fromJson(Map<String, dynamic> json) {
    return InferenceResponse(
      response: json['response'],
      usage: TokenUsage.fromJson(json['usage']),
    );
  }

  Map<String, dynamic> toMetadata() => {
    'usage': usage.toJson(),
  };
}

class InferenceClient {
  final String baseUrl;
  String? _authToken;
  
  InferenceClient({required String baseUrl}) 
    : baseUrl = _normalizeBaseUrl(baseUrl);
  
  static String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    if (url.endsWith('/v1/inference')) {
      url = url.substring(0, url.length - '/v1/inference'.length);
    }
    
    return url;
  }
  
  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Map<String, ModelInfo>> listModels() async {
    if (_authToken == null) {
      throw InferenceError(401, 'No auth token');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/v1/inference/models'),
      headers: {'Authorization': 'Bearer $_authToken'},
    );
    
    if (response.statusCode != 200) {
      throw InferenceError(response.statusCode, response.body);
    }
    
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
      key,
      ModelInfo.fromJson(value as Map<String, dynamic>),
    ));
  }

  // Simple token estimation
  int _estimateTokenCount(String text) {
    // Average English word is ~4 characters + space
    // Average token is ~4 characters
    return (text.length / 4).ceil();
  }

  Future<Map<String, dynamic>> inference({
    required List<Map<String, dynamic>> messages,
    String? model,
    Map<String, Object>? params,
  }) async {
    if (_authToken == null) {
      throw InferenceError(401, 'No auth token');
    }

    if (messages.isEmpty) {
      throw InferenceError(400, 'No messages provided');
    }

    final estimatedTokens = messages.fold<int>(
      0, (sum, msg) => sum + _estimateTokenCount(msg['content'] as String)
    );
    
    final Map<String, Object> payload = {
      'messages': messages,
      'estimated_prompt_tokens': estimatedTokens,
    };
    
    if (model != null) {
      payload['model'] = model;
    }
    
    if (params != null) {
      payload.addAll(params);
    }
    
    print('InferenceClient: Preparing request to $baseUrl/v1/inference');
    print('Payload: ${const JsonEncoder.withIndent('  ').convert(payload)}');

    final response = await http.post(
      Uri.parse('$baseUrl/v1/inference'),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    print('InferenceClient: Received response status ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 402) {
      throw InferenceError(402, 'Insufficient balance');
    }
    
    if (response.statusCode != 200) {
      throw InferenceError(response.statusCode, response.body);
    }
    
    final inferenceResponse = InferenceResponse.fromJson(
      json.decode(response.body)
    );
    
    return {
      'response': inferenceResponse.response,
      'usage': inferenceResponse.usage.toJson(),
      'estimated_prompt_tokens': estimatedTokens,
    };
  }
}
