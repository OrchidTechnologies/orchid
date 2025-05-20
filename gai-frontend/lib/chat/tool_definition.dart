import 'dart:convert';

/// Represents a tool parameter schema
class ToolParameterProperty {
  final String type;
  final String description;
  final bool required;

  ToolParameterProperty({
    required this.type,
    required this.description,
    this.required = false,
  });

  factory ToolParameterProperty.fromJson(
      Map<String, dynamic> json, String name, List<String> required) {
    return ToolParameterProperty(
      type: json['type'] ?? 'string',
      description: json['description'] ?? 'No description',
      required: required.contains(name),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
      };
}

/// Represents a tool parameter schema
class ToolParameters {
  final Map<String, ToolParameterProperty> properties;
  final List<String> required;

  ToolParameters({
    required this.properties,
    this.required = const [],
  });

  factory ToolParameters.fromJson(Map<String, dynamic> json) {
    final required = (json['required'] as List?)?.cast<String>() ?? [];

    final propertiesMap = <String, ToolParameterProperty>{};
    if (json['properties'] != null) {
      (json['properties'] as Map<String, dynamic>).forEach((key, value) {
        propertiesMap[key] = ToolParameterProperty.fromJson(
          value as Map<String, dynamic>,
          key,
          required,
        );
      });
    }

    return ToolParameters(
      properties: propertiesMap,
      required: required,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'object',
        'properties': properties.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'required': required,
      };
}

/// Represents a tool result content block
class ToolResultContent {
  final String type;
  final String? text;
  final String? url;
  final String? mimeType;

  ToolResultContent({
    required this.type,
    this.text,
    this.url,
    this.mimeType,
  });

  factory ToolResultContent.fromJson(Map<String, dynamic> json) {
    return ToolResultContent(
      type: json['type'] ?? 'text',
      text: json['text'],
      url: json['url'],
      mimeType: json['mime_type'],
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'type': type,
    };

    if (text != null) result['text'] = text;
    if (url != null) result['url'] = url;
    if (mimeType != null) result['mime_type'] = mimeType;

    return result;
  }
}

/// Represents a tool result from a tool call
class ToolResult {
  final String toolName;
  final Map<String, dynamic> arguments;
  final List<ToolResultContent> content;
  final int statusCode;
  final Map<String, dynamic>? error;
  final String providerId;
  final String? toolCallId; // Add tool_call_id for linking results to calls

  ToolResult({
    required this.toolName,
    required this.arguments,
    required this.content,
    this.statusCode = 200,
    this.error,
    required this.providerId,
    this.toolCallId, // Allow passing the tool_call_id
  });

  factory ToolResult.fromJson(
    Map<String, dynamic> json,
    String toolName,
    Map<String, dynamic> arguments,
    String providerId,
  ) {
    // Extract tool_call_id if present - this is critical for proper linking
    String? toolCallId;
    if (json.containsKey('tool_call_id')) {
      toolCallId = json['tool_call_id']?.toString();
    }

    // If there's an error field, create an error result
    if (json.containsKey('error')) {
      return ToolResult(
        toolName: toolName,
        arguments: arguments,
        content: [],
        statusCode: json['error']?['code'] ?? 500,
        error: json['error'],
        providerId: providerId,
        toolCallId: toolCallId, // Include tool_call_id
      );
    }

    // Otherwise create a success result
    return ToolResult(
      toolName: toolName,
      arguments: arguments,
      content: (json['content'] as List? ?? [])
          .map((content) => ToolResultContent.fromJson(content))
          .toList(),
      statusCode: 200,
      providerId: providerId,
      toolCallId: toolCallId, // Include tool_call_id
    );
  }

  factory ToolResult.error(
    String toolName,
    Map<String, dynamic> arguments,
    String errorMessage,
    int statusCode,
    String providerId, {
    String? toolCallId, // Add optional toolCallId parameter
  }) {
    return ToolResult(
      toolName: toolName,
      arguments: arguments,
      content: [],
      statusCode: statusCode,
      error: {
        'type': 'error',
        'message': errorMessage,
        'code': statusCode,
      },
      providerId: providerId,
      toolCallId: toolCallId, // Include tool_call_id
    );
  }

  bool get isSuccess => statusCode == 200 && error == null;

  String get textContent {
    if (!isSuccess) {
      return 'Error: ${error?['message'] ?? 'Unknown error'}';
    }

    // Get all text content parts
    final textParts = content
        .where((c) => c.type == 'text' && c.text != null)
        .map((c) => c.text!)
        .toList();

    // Default formatting for all tools - no special handling
    return textParts.join('\n');
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'tool_name': toolName,
      'arguments': arguments,
      'status_code': statusCode,
      'provider_id': providerId,
    };

    // Include tool_call_id if available - critical for proper linking
    if (toolCallId != null) {
      result['tool_call_id'] = toolCallId;
    }

    if (error != null) {
      result['error'] = error;
    } else {
      result['content'] = content.map((c) => c.toJson()).toList();
    }

    return result;
  }
}

/// Definition of a tool provided by a server
class ToolDefinition {
  final String name;
  final String description;
  final ToolParameters parameters;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  factory ToolDefinition.fromJson(Map<String, dynamic> json) {
    return ToolDefinition(
      name: json['name'] ?? '',
      description: json['description'] ?? 'No description',
      parameters: json['parameters'] != null
          ? ToolParameters.fromJson(json['parameters'])
          : ToolParameters(properties: {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters.toJson(),
      };

  @override
  String toString() => 'Tool: $name - $description';
}
