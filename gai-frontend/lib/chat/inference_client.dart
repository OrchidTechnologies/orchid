import 'dart:convert';
import 'package:http/http.dart' as http;
import 'provider_manager.dart'; // For ProviderManager.instance

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

class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatCompletionChoice> choices;
  final TokenUsage usage;

  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'],
      object: json['object'],
      created: json['created'],
      model: json['model'],
      choices: (json['choices'] as List)
          .map((x) => ChatCompletionChoice.fromJson(x))
          .toList(),
      usage: TokenUsage.fromJson(json['usage']),
    );
  }
}

class ChatCompletionChoice {
  final int index;
  final Map<String, dynamic> message;
  final String? finishReason;

  ChatCompletionChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory ChatCompletionChoice.fromJson(Map<String, dynamic> json) {
    return ChatCompletionChoice(
      index: json['index'],
      message: json['message'],
      finishReason: json['finish_reason'],
    );
  }
}

class InferenceClient {
  final String baseUrl;
  String? _authToken;
  
  // HTTP client to handle requests, made non-final for cancellation
  http.Client _httpClient = http.Client();
  
  String? get authToken => _authToken;
  
  InferenceClient({required String baseUrl}) 
    : baseUrl = _normalizeBaseUrl(baseUrl);
    
  // Cancel ongoing requests by closing and recreating the HTTP client
  void cancelRequests() {
    print('InferenceClient: Cancelling ongoing requests');
    try {
      // Close the current client which cancels all ongoing requests
      _httpClient.close();
      
      // Create a new client for future requests
      _httpClient = http.Client();
      print('InferenceClient: Created new HTTP client');
    } catch (e) {
      print('Error cancelling inference requests: $e');
    }
  }
  
  static String _normalizeBaseUrl(String url) {
    // Remove trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    // Remove any v1/inference suffix as we'll add the correct paths for each endpoint
    final v1Suffix = '/v1/inference';
    if (url.endsWith(v1Suffix)) {
      url = url.substring(0, url.length - v1Suffix.length);
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
    
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/inference/models'),
      headers: {'Authorization': 'Bearer $_authToken'},
    );
    
    if (response.statusCode != 200) {
      throw InferenceError(response.statusCode, response.body);
    }
    
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
      key,
      ModelInfo.fromJson(value as Map<String, dynamic>),
    ));
  }

  int _estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }

  Future<Map<String, dynamic>> inference({
    required List<Map<String, dynamic>> messages,
    String? model,
    Map<String, Object>? params,
    List<Map<String, dynamic>>? tools,
  }) async {
    if (_authToken == null) {
      throw InferenceError(401, 'No auth token');
    }

    if (messages.isEmpty) {
      throw InferenceError(400, 'No messages provided');
    }

    final estimatedTokens = messages.fold<int>(
      0, (sum, msg) => sum + _estimateTokenCount(msg['content'] as String? ?? "")
    );
    
    final Map<String, Object> payload = {
      'messages': messages,
      'model': model ?? 'gpt-3.5-turbo',
      'estimated_prompt_tokens': estimatedTokens,
    };
    
      // Add tools if provided - IMPORTANT: Keep tool definitions clean
    // We want to provide the raw tool definitions to the inference API
    // and let the backend handle routing
    if (tools != null && tools.isNotEmpty) {
      // Simply add the tools to the payload without modifying them
      // Tool routing information should be provided separately in params
      payload['tools'] = tools;
      
      // Enable tool routing flag if not already set
      if (params == null || !params.containsKey('route_tool_calls')) {
        payload['route_tool_calls'] = true;
      }
    }
    
    // Add other parameters - these should include tool provider routing info if needed
    if (params != null) {
      payload.addAll(params);
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 402) {
      throw InferenceError(402, 'Insufficient balance');
    }
    
    if (response.statusCode != 200) {
      throw InferenceError(response.statusCode, response.body);
    }
    
    // Parse the response with tool calls if present
    // IMPORTANT: Use utf8.decode to ensure proper UTF-8 decoding
    final responseBody = json.decode(utf8.decode(response.bodyBytes));
    final completionResponse = ChatCompletionResponse.fromJson(responseBody);
    
    // Extract any tool calls for processing
    Map<String, dynamic> toolCalls = {};
    try {
      if (completionResponse.choices.isNotEmpty &&
          completionResponse.choices[0].message.containsKey('tool_calls')) {
        toolCalls = {'tool_calls': completionResponse.choices[0].message['tool_calls']};
      }
    } catch (e) {
      print('Error extracting tool calls: $e');
    }
    
    // Convert to the format expected by the existing code
    return {
      'response': completionResponse.choices[0].message['content'],
      'usage': completionResponse.usage.toJson(),
      'estimated_prompt_tokens': estimatedTokens,
      ...toolCalls, // Include tool calls if present
    };
  }
}
