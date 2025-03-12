import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_log.dart';  // Import logWrapped
import 'chat_message.dart';
import 'inference_client.dart';
import 'tool_definition.dart';
import 'provider_manager.dart';

typedef MessageCallback = void Function(String message);
typedef VoidCallback = void Function();
typedef ErrorCallback = void Function(String error);
typedef AuthTokenCallback = void Function(String token, String inferenceUrl);
typedef PaymentConfirmedCallback = void Function();

class ChatInferenceRequest {
  final String modelId;
  final List<Map<String, dynamic>> preparedMessages;
  final Map<String, Object>? requestParams;
  final DateTime timestamp;

  ChatInferenceRequest({
    required this.modelId,
    required this.preparedMessages,
    required this.requestParams,
  }) : timestamp = DateTime.now();
}

class ChatInferenceResponse {
  // Request
  final ChatInferenceRequest request;

  // Result
  final String? message; // Now nullable to handle tool-only responses
  final Map<String, dynamic> metadata;

  ChatInferenceResponse({
    required this.request,
    this.message, // No longer required
    required this.metadata,
  });

  ChatMessage toChatMessage() {
    return ChatMessage(
      source: ChatMessageSource.provider,
      message: message ??
          "Tool response - see results below", // Provide a fallback message
      sourceName: request.modelId,
      metadata: metadata,
      modelId: request.modelId,
    );
  }
}

class ProviderConnection {
  final maxuint256 = BigInt.two.pow(256) - BigInt.one;
  final maxuint64 = BigInt.two.pow(64) - BigInt.one;
  final wei = BigInt.from(10).pow(18);
  WebSocketChannel? _providerChannel;

  // Inference client for this provider
  InferenceClient? get inferenceClient => _inferenceClient;
  InferenceClient? _inferenceClient;

  // HTTP client for tool endpoints
  // Make this non-final so we can replace it when cancelling requests
  http.Client _httpClient = http.Client();

  // Callbacks
  final MessageCallback onMessage;
  final VoidCallback onConnect;
  final ErrorCallback onError;
  final VoidCallback onDisconnect;
  final MessageCallback onSystemMessage;
  final MessageCallback onInternalMessage;
  final PaymentConfirmedCallback? onPaymentConfirmed;

  // Provider details
  final EthereumAddress? contract;
  final String wsUrl; // WebSocket URL for billing
  final String httpBaseUrl; // HTTP base URL for inference and tools
  final String? authToken; // Auth token for HTTP requests
  final AccountDetail? accountDetail;
  final AuthTokenCallback? onAuthToken;

  bool _usingDirectAuth = false;

  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(10000)}';
  }

  ProviderConnection({
    required this.onMessage,
    required this.onConnect,
    required this.onDisconnect,
    required this.onError,
    required this.onSystemMessage,
    required this.onInternalMessage,
    this.onPaymentConfirmed,
    this.contract,
    required String url, // This is the WS URL
    required String httpUrl, // This is the HTTP URL
    this.accountDetail,
    this.authToken,
    this.onAuthToken,
  })  : wsUrl = url,
        httpBaseUrl = httpUrl {
    _usingDirectAuth = authToken != null;

    if (!_usingDirectAuth) {
      try {
        _providerChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _providerChannel?.ready;
      } catch (e) {
        onError('Failed on provider connection: $e');
        return;
      }
      _providerChannel?.stream.listen(
        receiveProviderMessage,
        onDone: () => onDisconnect(),
        onError: (error) => onError('ws error: $error'),
      );
      onInternalMessage('WebSocket connecting to $wsUrl');
      // Do not call onConnect() here - we'll wait for auth token to be received
    } else {
      // Set up inference client directly with auth token
      _inferenceClient = InferenceClient(baseUrl: httpBaseUrl);
      _inferenceClient!.setAuthToken(authToken!);
      onInternalMessage('Using direct auth token');
      // For direct auth, we can call onConnect immediately
      onConnect();
    }
  }

  static Future<ProviderConnection> connect({
    required String billingUrl,
    required String inferenceUrl,
    EthereumAddress? contract,
    AccountDetail? accountDetail,
    String? authToken,
    required MessageCallback onMessage,
    required VoidCallback onConnect,
    required ErrorCallback onError,
    required VoidCallback onDisconnect,
    required MessageCallback onSystemMessage,
    required MessageCallback onInternalMessage,
    AuthTokenCallback? onAuthToken,
    PaymentConfirmedCallback? onPaymentConfirmed,
  }) async {
    if (authToken == null && accountDetail == null) {
      throw Exception('Either authToken or accountDetail must be provided');
    }

    final connection = ProviderConnection(
      onMessage: onMessage,
      onConnect: onConnect,
      onDisconnect: onDisconnect,
      onError: onError,
      onSystemMessage: onSystemMessage,
      onInternalMessage: onInternalMessage,
      onPaymentConfirmed: onPaymentConfirmed,
      contract: contract,
      url: authToken != null ? inferenceUrl : billingUrl,
      httpUrl: inferenceUrl,
      accountDetail: accountDetail,
      authToken: authToken,
      onAuthToken: onAuthToken,
    );

    return connection;
  }

  // Track if we've tried fetching tools
  bool _toolsFetchAttempted = false;

  void _handleAuthToken(Map<String, dynamic> data) {
    final token = data['session_id'];
    final inferenceUrl = data['inference_url'];
    if (token == null || inferenceUrl == null) {
      onError('Invalid auth token response');
      return;
    }

    _inferenceClient = InferenceClient(baseUrl: inferenceUrl);
    _inferenceClient!.setAuthToken(token);
    onInternalMessage('Auth token received and inference client initialized');

    // Now that we have the auth token, we can consider the connection fully established
    onConnect();

    // Call the auth token callback - this will trigger model fetching in the provider manager
    onAuthToken?.call(token, inferenceUrl);

    // We'll fetch tools when we get payment confirmation, not immediately
    // If this is direct auth (not using WebSocket), attempt tool fetch immediately
    if (_usingDirectAuth) {
      _fetchToolsIfReady();
    }
  }

  // This method will be called when we get payment confirmation
  void _fetchToolsIfReady() {
    // Only try once
    if (_toolsFetchAttempted) return;
    _toolsFetchAttempted = true;

    // Check if we can fetch tools
    if (_inferenceClient?.authToken == null) {
      onInternalMessage('Not fetching tools: no auth token available yet');
      return;
    }

    onInternalMessage(
        'Attempting to fetch tools now that payment is confirmed');

    // Try to fetch available tools
    fetchAvailableTools().then((tools) {
      if (tools.isNotEmpty) {
        onInternalMessage('Fetched ${tools.length} tools from provider');
      } else {
        onInternalMessage('No tools available from this provider');
      }
    }).catchError((e) {
      onError('Failed to fetch tools: $e');
      // If we get insufficient funds, we might need to wait longer
      if (e.toString().contains('402') ||
          e.toString().contains('insufficient')) {
        onInternalMessage(
            'Insufficient funds for tool fetching, will retry later');
        _toolsFetchAttempted = false; // Allow retry
      }
    });
  }

  bool validInvoice(invoice) {
    return invoice.containsKey('amount') &&
        invoice.containsKey('commit') &&
        invoice.containsKey('recipient');
  }

  void payInvoice(Map<String, dynamic> invoice) {
    if (_usingDirectAuth) {
      onError('Unexpected invoice received while using direct auth token');
      return;
    }

    var payment;
    if (!validInvoice(invoice)) {
      onError('Invalid invoice ${invoice}');
      return;
    }

    assert(accountDetail?.funder != null);
    final balance = accountDetail?.lotteryPot?.balance.intValue ?? BigInt.zero;
    final deposit = accountDetail?.lotteryPot?.deposit.intValue ?? BigInt.zero;

    if (balance <= BigInt.zero || deposit <= BigInt.zero) {
      onError('Insufficient funds: balance=$balance, deposit=$deposit');
      return;
    }

    final faceval = _bigIntMin(balance, (wei * deposit) ~/ (wei * BigInt.two));
    if (faceval <= BigInt.zero) {
      onError('Invalid face value: $faceval');
      return;
    }

    final data = BigInt.zero;
    final due = BigInt.from(invoice['amount']);
    final lotaddr = contract;
    final token = EthereumAddress.zero;

    BigInt ratio;
    try {
      ratio = maxuint64 & (maxuint64 * due ~/ faceval);
    } catch (e) {
      onError('Failed to calculate ratio: $e (due=$due, faceval=$faceval)');
      return;
    }

    final commit = BigInt.parse(invoice['commit'] ?? '0x0');
    final recipient = invoice['recipient'];

    final ticket = OrchidTicket(
      data: data,
      lotaddr: lotaddr!,
      token: token,
      amount: faceval,
      ratio: ratio,
      funder: accountDetail!.account.funder,
      recipient: EthereumAddress.from(recipient),
      commitment: commit,
      privateKey: accountDetail!.account.signerKey.private,
      millisecondsSinceEpoch: DateTime.now().millisecondsSinceEpoch,
    );

    payment = '{"type": "payment", "tickets": ["${ticket.serializeTicket()}"]}';
    onInternalMessage('Client: $payment');
    _sendProviderMessage(payment);

    // Also try to fetch tools shortly after making a payment,
    // which should establish balance with the server
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchToolsIfReady();
    });
  }

  void receiveProviderMessage(dynamic message) {
    final data = jsonDecode(message) as Map<String, dynamic>;
    print(message);
    onMessage('Provider: $message');

    switch (data['type']) {
      case 'invoice':
        payInvoice(data);
        break;
      case 'payment_confirmed':
        // The server has confirmed it received our payment
        onInternalMessage('Payment confirmed by server');
        onPaymentConfirmed?.call();
        break;
      case 'balance_updated':
        // The server has updated our balance
        final balance = data['balance'];
        onInternalMessage('Balance updated: $balance');
        onPaymentConfirmed?.call();
        break;
      case 'bid_low':
        onSystemMessage("Bid below provider's reserve price.");
        break;
      case 'auth_token':
        _handleAuthToken(data);
        break;
    }
  }

  Future<void> requestAuthToken() async {
    if (_usingDirectAuth) {
      onError('Cannot request auth token when using direct auth');
      return;
    }

    const message = '{"type": "request_token"}';
    onInternalMessage('Requesting auth token');
    _sendProviderMessage(message);
  }

  Future<ChatInferenceResponse?> requestInference(
    String modelId,
    List<Map<String, dynamic>> preparedMessages, {
    Map<String, Object>? params,
    bool includeTools = true,
  }) async {
    final requestId = _generateRequestId();
    _activeRequestIds.add(requestId);
    
    var request = ChatInferenceRequest(
      modelId: modelId,
      preparedMessages: preparedMessages,
      requestParams: params,
    );

    // Check if we're using direct auth or have an inference client
    if (!_usingDirectAuth && _inferenceClient == null) {
      await requestAuthToken();
      await Future.delayed(const Duration(milliseconds: 100));

      // Import ProviderManager directly to check for tools-only mode
      final providerManager = ProviderManager.instance;

      // In tools-only mode, we can still send requests even without an inference client
      final isToolsOnlyMode = providerManager.toolProviders.isNotEmpty &&
          !providerManager.hasInferenceClient;

      if (_inferenceClient == null && !isToolsOnlyMode) {
        onError('No inference connection available');
        return null;
      }
    }

    try {
      // Use the previously generated requestId
      final allParams = {
        ...?params,
        'request_id': requestId,
      };

      // Always add tool routing settings
      allParams['route_tool_calls'] = true;

      // Fetch available tools if requested
      List<Map<String, dynamic>>? toolsJson;
      Map<String, Map<String, dynamic>> toolProviderInfo = {};

      if (includeTools) {
        try {
          // Import ProviderManager directly to get enabled tools
          final providerManager = ProviderManager.instance;

          // Get all enabled tools from ALL providers - this is critical for cross-provider tool usage
          final enabledTools = providerManager.getEnabledTools();

          if (enabledTools.isNotEmpty) {
            // Wrap each tool definition in the format expected by the backend
            toolsJson = [];

            // Track tool providers for debugging and inclusion in the request
            final toolProviderMap = <String, String>{};

            for (var tool in enabledTools) {
              // Find this tool's provider
              final provider = providerManager.getToolProvider(tool.name);
              if (provider != null) {
                // Add provider info to the tool routing map
                toolProviderMap[tool.name] = provider.name;

                // Add more detailed provider info for the backend to use for routing
                toolProviderInfo[tool.name] = {
                  'provider_id': provider.id,
                  'provider_name': provider.name,
                  'provider_url': provider.httpUrl,
                };

                // Create the tool definition with additional provider routing information
                final toolJson = {
                  "type": "function",
                  "function": tool.toJson(),
                  "provider_id": provider.id,
                  "provider_name": provider.name,
                };

                toolsJson.add(toolJson);
              } else {
                // If no provider found, just add the basic tool definition
                toolProviderMap[tool.name] = 'unknown';
                toolsJson.add({
                  "type": "function",
                  "function": tool.toJson(),
                });
              }
            }

            // Add the tool provider routing map to the params
            if (toolProviderInfo.isNotEmpty) {
              allParams['tool_providers'] = toolProviderInfo;
            }

            // Log only the count of enabled tools without the verbose provider mapping
            onInternalMessage(
                'Including ${enabledTools.length} enabled tools from all providers in inference request');
          } else {
            onInternalMessage(
                'No enabled tools to include in inference request');
          }
        } catch (e) {
          // Don't fail the inference request if tool fetching fails
          onError('Failed to prepare tools for inference request: $e');
        }
      }

      // Log basic request info to internal message channel
      onInternalMessage('Sending inference request:\nModel: $modelId');
      
      // Log detailed content using direct log output for better visibility
      
      // Log params
      log('Request params, full content below:');
      logWrapped(jsonEncode(allParams));
      
      // Log tools
      if (toolsJson != null && toolsJson.isNotEmpty) {
        log('Request tools (${toolsJson.length}), full content below:');
        logWrapped(jsonEncode(toolsJson));
      }
      
      // Log messages
      if (preparedMessages.isNotEmpty) {
        log('Request messages, full content below:');
        logWrapped(jsonEncode(preparedMessages));
      }

      // Import ProviderManager to check for tools-only mode
      final providerManager = ProviderManager.instance;
      final isToolsOnlyMode =
          providerManager.toolProviders.isNotEmpty && _inferenceClient == null;

      Map<String, dynamic> result;

      if (isToolsOnlyMode) {
        // In tools-only mode, create a synthetic response
        // This will be processed by the backend to execute tools directly
        result = {
          'response': "Using tools-only mode",
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 10,
            'total_tokens': 20
          }
        };
        onInternalMessage(
            'Using tools-only mode - request will be processed by tool providers');
      } else {
        // Normal inference path - with enhanced tool routing
        result = await _inferenceClient!.inference(
          messages: preparedMessages,
          model: modelId,
          params: allParams,
          tools: toolsJson,
        );

        // Check if the response contains tool calls that need routing
        if (result.containsKey('tool_calls') && result['tool_calls'] is List) {
          // Process any tool calls in the response to ensure they are routed correctly
          final toolCalls = result['tool_calls'] as List;
          
          // Only log once for the entire batch of tool calls
          if (toolCalls.isNotEmpty) {
            onInternalMessage('Response contains ${toolCalls.length} tool calls to process');
          }
          
          for (final toolCall in toolCalls) {
            // Extract tool info
            if (toolCall is Map && toolCall.containsKey('function')) {
              final function = toolCall['function'] as Map?;
              if (function != null && function.containsKey('name')) {
                final toolName = function['name'];
                final arguments = function.containsKey('arguments')
                    ? json.decode(function['arguments'] as String)
                    : {};

                // Add provider routing information
                final provider = providerManager.getToolProvider(toolName);
                if (provider != null) {
                  toolCall['provider_id'] = provider.id;
                  toolCall['provider_name'] = provider.name;
                  // Avoid individual log messages for each tool
                  // onInternalMessage('Added provider routing for tool $toolName: ${provider.name}');
                }
              }
            }
          }
        }
      }

      // Remove the request ID from active requests as it's complete
      _activeRequestIds.remove(requestId);
      
      // Create a rich metadata object that includes tool routing info
      final metadata = {
        'type': 'job_complete',
        'output': result['response'],
        'usage': result['usage'],
        'model_id': modelId,
        'request_id': requestId,
        'estimated_prompt_tokens': result['estimated_prompt_tokens'],
        'tools_included': toolsJson != null ? toolsJson.length : 0,
      };

      // Include tool calls and provider routing if present
      if (result.containsKey('tool_calls')) {
        metadata['tool_calls'] = result['tool_calls'];
        
        // Log detailed tool calls for debugging, showing actual parameters
        final toolCalls = result['tool_calls'] as List;
        if (toolCalls.isNotEmpty) {
          onInternalMessage('Response contains ${toolCalls.length} tool calls:');
          
          // Log each tool call with its parameters
          for (var i = 0; i < toolCalls.length; i++) {
            final toolCall = toolCalls[i] as Map;
            final function = toolCall['function'] as Map?;
            
            if (function != null && function.containsKey('name') && function.containsKey('arguments')) {
              final toolName = function['name'];
              final arguments = function['arguments'];
              
              // Log detailed tool call info
              onInternalMessage('Tool call ${i+1}/${toolCalls.length}: $toolName');
              onInternalMessage('Arguments:');
              logWrapped(arguments);
            }
          }
        }
      }

      // Include tool provider mapping for future reference
      if (toolProviderInfo.isNotEmpty) {
        metadata['tool_providers'] = toolProviderInfo;
      }

      final chatResult = ChatInferenceResponse(
        request: request,
        message: result['response'] as String?, // Cast to nullable String
        metadata: metadata,
      );

      return chatResult;
    } catch (e, stack) {
      // Clean up the request ID on error
      _activeRequestIds.remove(requestId);
      onError('Failed to send inference request: $e\n$stack');
      return null;
    }
  }

  // Track tool fetch attempts
  int _toolFetchRetries = 0;

  // Fetch available tools from this provider
  Future<List<ToolDefinition>> fetchAvailableTools() async {
    if (_inferenceClient?.authToken == null) {
      // Log the error but don't throw an exception
      // This allows tool-only providers to still function
      onInternalMessage(
          'Note: No auth token available for tool fetch, using minimal tools');
      return []; // Return empty list instead of throwing
    }

    // Store the inference URL to use throughout this method
    final String inferenceBaseUrl = _inferenceClient!.baseUrl;

    try {
      // If we've tried more than 3 times, wait longer between attempts
      if (_toolFetchRetries > 3) {
        final delayMs =
            1000 * _toolFetchRetries; // Calculate delay based on retry count
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      _toolFetchRetries++;

      final toolsUrl = '$inferenceBaseUrl/v1/tools/list';
      onInternalMessage(
          'Fetching tools from: $toolsUrl with auth token: ${_inferenceClient!.authToken!.substring(0, math.min(10, _inferenceClient!.authToken!.length))}...');

      // Extra logging for diagnosing provider connection issues
      try {
        final providerManager = ProviderManager.instance;
        var providerId = providerManager.findProviderIdForConnection(this);
        if (providerId != null) {
          // Use public methods to get provider info instead of accessing private fields
          final providerList = providerManager.allProviders;
          ProviderState? provider;
          try {
            provider = providerList.firstWhere((p) => p.id == providerId);
          } catch (e) {
            // No matching provider found
            provider = null;
          }
          if (provider != null) {
            log('Fetching tools for provider: ${provider.name} (${providerId})');
            log('Provider URL: ${provider.httpUrl}');
            log('Provider connected: ${provider.connected}');
            log('Provider supports inference: ${provider.supportsInference}');
          }
        } else {
          log('Could not find provider ID for this connection');
        }
      } catch (e) {
        log('Error getting provider info: $e');
      }

      final response = await _httpClient.post(
        Uri.parse(toolsUrl),
        headers: {
          'Authorization': 'Bearer ${_inferenceClient!.authToken}',
          'Content-Type': 'application/json',
        },
      );

      onInternalMessage('Tools list response: HTTP ${response.statusCode}');

      if (response.statusCode != 200) {
        if (response.statusCode == 402) {
          onSystemMessage('Insufficient balance to fetch tools');

          // If we get insufficient funds (402), our payment might not have been processed yet
          // Try to trigger the payment and tool fetch process again
          if (!_usingDirectAuth && _toolFetchRetries < 5) {
            onInternalMessage(
                'Will retry tool fetch after establishing balance');

            // Reset the tool fetch attempt flag to allow retrying later
            _toolsFetchAttempted = false;

            throw Exception('Insufficient balance to fetch tools: HTTP 402');
          }
        } else if (response.statusCode == 404) {
          onSystemMessage(
              'Tool listing endpoint not found - provider may not support Tool Node Protocol');
        }

        onError(
            'Failed to fetch tools: HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
            'Failed to fetch tools: HTTP ${response.statusCode}: ${response.body}');
      }

      // Reset retry count on success
      _toolFetchRetries = 0;

      // Handle the successful response
      try {
        // Log the complete tool definitions using log (not onInternalMessage) to avoid truncation
        log('Tools response body, full content below:');
        logWrapped(response.body);

        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!data.containsKey('tools') || data['tools'] is! List) {
          onError('Invalid tools response: ${response.body}');
          throw Exception('Invalid tools response format');
        }

        final tools = (data['tools'] as List)
            .map((toolJson) => ToolDefinition.fromJson(toolJson))
            .toList();

        onInternalMessage('Fetched ${tools.length} tools from provider');

        // Update the ProviderManager tool list and trigger UI update
        try {
          final providerManager = ProviderManager.instance;

          // Find which provider this connection belongs to
          var providerId = providerManager.findProviderIdForConnection(this);
          if (providerId != null) {
            // Update the provider state's available tools
            providerManager.updateProviderTools(providerId, tools);
          } else {
            // If we can't find the provider, at least notify listeners
            providerManager.availableToolsNotifier.notifyListeners();
          }
        } catch (e) {
          onError('Error updating provider manager tools: $e');
        }

        return tools;
      } catch (e) {
        onError('Error parsing tools response: $e');
        throw e;
      }
    } catch (e, stack) {
      onError('Error fetching tools: $e');
      print('Error fetching tools: $e\n$stack');
      return [];
    }
  }

  // Call a tool by name with arguments
  Future<ToolResult> callTool(
      String toolName, Map<String, dynamic> arguments, {
      String? toolCallId, // Add toolCallId parameter
  }) async {
    // SIMPLIFIED APPROACH: This method should directly call the tool without complicated routing
    // The routing should be handled at a higher level (in ProviderManager) before reaching here
    
    // Generate unique request ID to track this tool call
    final requestId = _generateRequestId();
    _activeRequestIds.add(requestId);

    // Make sure we have an auth token before proceeding
    if (_inferenceClient?.authToken == null) {
      onError(
          "No auth token available for tool: $toolName on provider ${this.httpBaseUrl}");
      return ToolResult.error(
        toolName,
        arguments,
        'No auth token available',
        401,
        this.httpBaseUrl,
      );
    }

    // Store the inference URL to use throughout this method
    final String inferenceBaseUrl = _inferenceClient!.baseUrl;

    try {
      // Log this direct call with extra detail
      onInternalMessage(
          "Directly executing tool $toolName on this provider (${this.httpBaseUrl})");
      onInternalMessage(
          "Auth token available and has length: ${_inferenceClient!.authToken!.length}");

      final requestBody = {
        'name': toolName,
        'arguments': arguments,
      };
      
      // Include tool_call_id if provided
      if (toolCallId != null) {
        requestBody['tool_call_id'] = toolCallId;
      }

      // CRITICAL FIX: Make sure we're using the correct tool endpoint
      final toolUrl = '$inferenceBaseUrl/v1/tools/call';
      onInternalMessage(
          'Calling tool: $toolName at $toolUrl with auth token: ${_inferenceClient!.authToken!.substring(0, math.min(10, _inferenceClient!.authToken!.length))}...');

      // Added explicit debug logging for the complete request
      final tokenPreview = _inferenceClient!.authToken!
          .substring(0, math.min(15, _inferenceClient!.authToken!.length));
      log('Tool request details:');
      log('- URL: $toolUrl');
      log('- Auth token prefix: ${tokenPreview}...');
      log('- Auth token length: ${_inferenceClient!.authToken!.length}');
      log('- Request body: ${json.encode(requestBody)}');

      try {
        // Double-check that the request hasn't been cancelled before sending
        if (!_activeRequestIds.contains(requestId)) {
          log('Tool request was cancelled before sending');
          return ToolResult.error(
            toolName,
            arguments,
            'Request cancelled by user',
            499, // Custom status code for cancellation
            inferenceBaseUrl,
          );
        }
        
        // Create a future that will complete when the HTTP request finishes
        final responseFuture = _httpClient.post(
          Uri.parse(toolUrl),
          headers: {
            'Authorization': 'Bearer ${_inferenceClient!.authToken}',
            'Content-Type': 'application/json',
            'X-Request-ID': requestId,
          },
          body: json.encode(requestBody),
        );
        
        // Create a future that will complete if the request is cancelled
        // This works by checking if the request ID is still in the active set
        final cancelCheckFuture = Future(() async {
          // Check every 100ms if the request has been cancelled
          while (_activeRequestIds.contains(requestId)) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          // If we get here, the request ID was removed - meaning it was cancelled
          return ToolResult.error(
            toolName,
            arguments,
            'Request cancelled by user',
            499, // Custom status code for cancellation
            inferenceBaseUrl,
          );
        });
        
        // Wait for either the response or cancellation, whichever comes first
        final result = await Future.any([responseFuture, cancelCheckFuture]);
        
        // If the result is already a ToolResult, it means cancellation won
        if (result is ToolResult) {
          log('Tool request for $toolName was cancelled during execution');
          return result;
        }
        
        // Otherwise, we got an HTTP response
        final response = result as http.Response;
        
        // Check once more if the request was cancelled before processing the response
        if (!_activeRequestIds.contains(requestId)) {
          log('Tool request was cancelled after receiving response but before processing');
          return ToolResult.error(
            toolName,
            arguments,
            'Request cancelled by user',
            499,
            inferenceBaseUrl,
          );
        }

        // Log full response for debugging
        log('Tool response: HTTP ${response.statusCode}');
        log('Response body, full content below:');
        logWrapped(response.body);

        // Handle common error cases
        if (response.statusCode == 402) {
          onError('Tool execution failed: Insufficient balance (HTTP 402)');
          return ToolResult.error(
            toolName,
            arguments,
            'Insufficient balance to execute tool',
            402,
            inferenceBaseUrl,
          );
        }

        if (response.statusCode == 404) {
          onError('Tool execution failed: Tool not found (HTTP 404)');
          return ToolResult.error(
            toolName,
            arguments,
            'Tool not found',
            404,
            inferenceBaseUrl,
          );
        }

        if (response.statusCode != 200) {
          String errorMessage;
          try {
            final errorData =
                json.decode(response.body) as Map<String, dynamic>;
            errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          } catch (e) {
            errorMessage = 'Error: ${response.body}';
          }

          onError(
              'Tool execution failed: HTTP ${response.statusCode}: $errorMessage');
          return ToolResult.error(
            toolName,
            arguments,
            errorMessage,
            response.statusCode,
            inferenceBaseUrl,
          );
        }

        // Parse the successful response
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Clean up the request ID as it's completed
        _activeRequestIds.remove(requestId);
        
        // Try to find which provider this is to properly attribute the tool result
        String providerId = inferenceBaseUrl;
        try {
          final providerManager = ProviderManager.instance;

          // First try to use the provider ID from the server response if present
          if (data.containsKey('provider_id') && data['provider_id'] != null) {
            providerId = data['provider_id'].toString();
          }
          // Next, try to find this provider in the provider manager
          else {
            for (final provider in providerManager.allProviders) {
              if (provider.connection == this) {
                providerId = provider.id;
                break;
              }
            }
          }
        } catch (e) {
          // Ignore errors in provider lookup, just use the URL
          onError("Error getting provider info: $e");
        }

        log('Tool execution succeeded');
        
        // Get the toolCallId from the API response or from the original tool call
        String? finalToolCallId = null;
        
        // Check if we have a tool_call_id in the original request data
        // This variable is in scope from the surrounding function
        if (data.containsKey('tool_call_id')) {
          finalToolCallId = data['tool_call_id']?.toString();
        } 
        
        // If tool_call_id was in the request metadata, include it
        if (finalToolCallId == null) {
          try {
            // Try to get the tool call ID from the metadata of the existing request
            final Map<String, dynamic>? requestMetadata = requestBody;
            if (requestMetadata != null && requestMetadata.containsKey('tool_call_id')) {
              finalToolCallId = requestMetadata['tool_call_id']?.toString();
            }
          } catch (e) {
            log('Error extracting tool_call_id from request: $e');
          }
        }
        
        // If we found a tool_call_id, include it in the data
        if (finalToolCallId != null && !data.containsKey('tool_call_id')) {
          // Create a copy of data with the tool_call_id added
          final dataWithToolCallId = Map<String, dynamic>.from(data);
          dataWithToolCallId['tool_call_id'] = finalToolCallId;
          return ToolResult.fromJson(dataWithToolCallId, toolName, arguments, providerId);
        } else {
          return ToolResult.fromJson(data, toolName, arguments, providerId);
        }
      } catch (e) {
        // If this is a http.ClientException, it might be due to cancellation
        if (e.toString().contains('Client closed') || 
            e.toString().contains('Connection closed')) {
          log('Tool request for $toolName was cancelled via HTTP client closure');
          return ToolResult.error(
            toolName,
            arguments,
            'Request cancelled by user',
            499,
            inferenceBaseUrl,
          );
        }
        
        // Clean up request ID on error
        _activeRequestIds.remove(requestId);
        
        // Capture network errors separately for better diagnostics
        onError('Network error calling tool $toolName: $e');
        return ToolResult.error(
          toolName,
          arguments,
          'Network error: $e',
          500,
          inferenceBaseUrl,
        );
      }
    } catch (e, stack) {
      // Clean up request ID on error in outer try block
      _activeRequestIds.remove(requestId);
      
      onError('Error calling tool $toolName: $e');
      log(stack.toString());
      return ToolResult.error(
        toolName,
        arguments,
        'Error: $e',
        500,
        inferenceBaseUrl,
      );
    }
  }

  void _sendProviderMessage(String message) {
    if (_usingDirectAuth) {
      onError('Cannot send provider message when using direct auth');
      return;
    }
    print('Sending message to provider $message');
    _providerChannel?.sink.add(message);
  }

  // Track active requests that can be cancelled
  final Set<String> _activeRequestIds = {};
  
  // HTTP client to replace as needed
  http.Client? _replacementClient;
  
  // Cancel all active requests
  void cancelRequests() {
    final count = _activeRequestIds.length;
    final requestIdsList = _activeRequestIds.join(', ');
    log('ProviderConnection: Cancelling $count active requests: $requestIdsList');
    
    // 1. Cancel the inference client's requests
    if (_inferenceClient != null) {
      _inferenceClient!.cancelRequests();
      log('Cancelled inference client requests');
    }
    
    // 2. Cancel HTTP requests for tools
    try {
      // Close the current HTTP client which will abort all ongoing requests
      _httpClient.close();
      log('Closed HTTP client to abort all in-flight tool requests');
      
      // Create a new client for future requests
      _replacementClient = http.Client();
      
      // Replace the current client with the new one
      Future.microtask(() {
        // This is done in a microtask to avoid any race conditions
        if (_replacementClient != null) {
          log('Replacing HTTP client with a new instance');
          // Store reference to old client so we can ensure it's closed
          final oldClient = _httpClient;
          _httpClient = _replacementClient!;
          _replacementClient = null;
          
          // Try to close the old client again just to be safe
          try { 
            oldClient.close(); 
          } catch (e) { 
            // Ignore errors from closing again 
          }
        }
      });
    } catch (e) {
      log('Error while closing/replacing HTTP client: $e');
    }
    
    // 3. Mark all active requests as cancelled so we can ignore their results if they do arrive
    _activeRequestIds.clear();
    
    // Log information for debugging
    log('Inference client status: ${_inferenceClient != null ? 'available' : 'null'}');
    if (_inferenceClient != null) {
      log('Inference URL: ${_inferenceClient!.baseUrl}');
      log('Auth token available: ${_inferenceClient!.authToken != null}');
    }
    
    // Don't send a message from here - UI will handle messaging
  }
  
  void dispose() {
    _providerChannel?.sink.close();
    _httpClient.close();
    _activeRequestIds.clear();
    onDisconnect();
  }

  BigInt _bigIntMin(BigInt a, BigInt b) {
    if (a > b) {
      return b;
    }
    return a;
  }
  
  // Helper method to format JSON for better readability
  String _formatJson(String jsonString) {
    if (jsonString.contains('{') && jsonString.contains('}')) {
      return jsonString
          .replaceAll(',"', ',\n  "')
          .replaceAll('{"', '{\n  "')
          .replaceAll('"}', '"\n}');
    }
    return jsonString;
  }
}
