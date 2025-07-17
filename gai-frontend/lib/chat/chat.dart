import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
// Conditionally import JS only when compiling for web
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_log.dart';  // Import logWrapped
import 'package:orchid/chat/api/user_preferences_chat.dart';
import 'package:orchid/chat/model.dart';
import 'package:orchid/chat/provider_connection.dart';
import 'package:orchid/chat/scripting/chat_scripting.dart';
import 'package:orchid/chat/scripting/code_viewer/user_script_dialog.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/chat/chat_settings_button.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:url_launcher/url_launcher.dart';
import 'callout_painter.dart';
import 'chat_bubble.dart';
import 'chat_button.dart';
import 'chat_message.dart';
import 'chat_prompt.dart';
import 'chat_model_button.dart';
import 'auth_dialog.dart';
import 'chat_history.dart';
import 'model_manager.dart';
import 'provider_manager.dart';
import 'state_manager.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  // Platform detection helper
  bool get _isMobilePlatform {
    // On web, check the target platform
    if (kIsWeb) {
      // Web on mobile browsers
      return defaultTargetPlatform == TargetPlatform.iOS || 
             defaultTargetPlatform == TargetPlatform.android;
    }
    // Native mobile apps
    return defaultTargetPlatform == TargetPlatform.iOS || 
           defaultTargetPlatform == TargetPlatform.android;
  }
  
  // UI state
  bool _debugMode = false;
  bool _multiSelectMode = false;
  bool _partyMode = false;
  bool _isProcessingRequest = false; // Track if we're processing a request
  bool _calloutDismissed = false; // Track if the account callout has been dismissed
  int? _maxTokens;
  Chain _selectedChain = Chains.Gnosis;
  final ScrollController messageListController = ScrollController();
  final _promptTextController = TextEditingController();
  final _maxTokensController = NumericValueFieldController();
  
  // Focus node to detect key events
  final FocusNode _keyboardFocusNode = FocusNode();

  // Chat
  final ChatHistory _chatHistory = ChatHistory();

  // Providers
  late final ProviderManager _providerManager;

  // Models
  final ModelManager _modelManager = ModelManager();
  List<String> _userSelectedModelIds = [];

  List<ModelInfo> get _userSelectedModels =>
      _modelManager.getModelsOrDefault(_userSelectedModelIds);

  // Account
  EthereumAddress? _funder;
  BigInt? _signerKey;
  AccountDetailPoller? _accountDetail;
  final _accountDetailNotifier = ValueNotifier<AccountDetail?>(null);

  // Auth
  String? _authToken;
  String? _inferenceUrl;
  String? _scriptURLParam;

  @override
  void initState() {
    super.initState();

    // Init the provider manager
    _providerManager = ProviderManager(
      modelsState: _modelManager,
      onProviderConnected: providerConnected,
      onProviderDisconnected: providerDisconnected,
      onChatMessage: _addChatMessage,
    );

    // Get account details from parameters if provided
    // Use Future to initialize params without blocking initState
    Future(() async {
      try {
        await _initFromParams();
        // Account is now initialized, provider connections will be made by _accountChanged
      } catch (e, stack) {
        log('Error initializing from params: $e, $stack');
      }
    });

    // Initialize the scripting extension mechanism
    _initScripting();
    
    // Initialize keyboard listener only on non-mobile platforms
    if (!_isMobilePlatform) {
      _initKeyboardListener();
      
      // Register a browser-level event listener if we're running on the web
      if (kIsWeb) {
        _initBrowserKeyboardListeners();
      }
    }
    
    // Initialize state manager
    StateManager().init(
      captureState: _captureCurrentState,
      applyState: _applyState,
      getMessages: () => _chatHistory.messages,
      setMessages: (messages) {
        setState(() {
          _chatHistory.setMessages(messages);
        });
      },
    );
  }
  
  // For web only: directly hook into browser events
  void _initBrowserKeyboardListeners() {
    log('Setting up browser keyboard listener for web');
    
    // Use HardwareKeyboard for listening to key events
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    log('Browser keyboard listener initialized');
  }
  
  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isProcessingRequest) {
          _cancelOngoingRequests();
          return true; // Handled
        }
      }
    }
    return false; // Not handled
  }
  
  void _initKeyboardListener() {
    // Add callback for key events on our focus node
    _keyboardFocusNode.onKeyEvent = (node, event) {
      // Only respond to key down events to avoid handling the same press twice
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isProcessingRequest) {
          _cancelOngoingRequests();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }
  
  // Flag to prevent duplicate cancellation
  bool _isCancelling = false;
  
  void _cancelOngoingRequests() {
    // Prevent multiple cancellations
    if (_isCancelling || !_isProcessingRequest) {
      return;
    }
    
    // Set flag to prevent duplicate cancellation messages
    _isCancelling = true;
    
    // Add message to indicate cancellation
    _addMessage(
      ChatMessageSource.system,
      'Request interrupted by user',
    );
    
    // Tell provider manager to cancel ongoing requests
    _providerManager.cancelActiveRequests();
    
    // Reset processing state
    setState(() {
      _isProcessingRequest = false;
    });
    
    // Force a notification to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request cancelled'), 
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red[800],
      ),
    );
    
    // Reset cancellation flag after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _isCancelling = false;
    });
  }

  void _initScripting() {
    ChatScripting.init(
      // If a script URL is provided, it will be loaded.
      url: _scriptURLParam,
      script: _scriptURLParam == null
          ? UserPreferencesScripts().userScript.get()
          : null,
      providerManager: _providerManager,
      modelManager: _modelManager,
      getUserSelectedModels: () => _userSelectedModels,
      chatHistory: _chatHistory,
      addChatMessageToUI: _addChatMessage,
      onScriptError: (error) {
        _addMessage(ChatMessageSource.internal,
            'User Script error: ${error.truncate(128)}');
        _addMessage(ChatMessageSource.system, 'User Script error (see logs).');
      },
      onScriptLoaded: (msg) {
        _addMessage(ChatMessageSource.system, msg);
      },
    );
  }

  bool get _connected {
    return _providerManager.connected;
  }

  bool _emptyState() {
    if (_account != null || _connected) {
      return false;
    }
    return true;
  }

  void _setMaxTokens(int? value) {
    setState(() {
      _maxTokens = value;
    });
    StateManager().onStateChanged();
  }

  // Get an account view of the funder/signer pair
  Account? get _account {
    if (_funder == null || _signerKey == null) {
      return null;
    }
    return Account.fromSignerKey(
      version: 1,
      signerKey: TransientEthereumKey(imported: true, private: _signerKey!),
      funder: _funder!,
      chainId: _selectedChain.chainId,
    );
  }

  Future<void> _accountChanged() async {
    log("chat: accountChanged: $_account");
    _accountDetail?.cancel();
    _accountDetail = null;

    if (_account != null) {
      _accountDetail = AccountDetailPoller(account: _account!);
      await _accountDetail?.pollOnce();

      // IMPORTANT: Set account detail BEFORE trying to connect
      _providerManager.setAccountDetail(_accountDetail);

      // Now connect to provider with new account - the account detail is already set
      await _providerManager.connectToInitialProvider();
    } else {
      // Disconnects any existing provider connection
      _providerManager.setAccountDetail(null);
      _modelManager.clear();
    }

    _accountDetailNotifier.value =
        _accountDetail; // This notifies the listeners
    setState(() {});
  }

  // Init from user parameters (for web)
  Future<void> _initFromParams() async {
    final params = OrchidUserParams();
    _funder = params.getEthereumAddress('funder');
    _signerKey = params.getBigInt('signer');
    
    // Wait for account to be fully initialized before proceeding
    await _accountChanged();

    String? provider = params.get('provider');
    if (provider != null) {
      _providerManager.setUserProvider(provider);
    }

    _scriptURLParam = params.getURL('script');
  }

  void providerConnected([name = '']) {
    // Only show connection message in debug mode
    _addMessage(
      ChatMessageSource.internal,
      'Connected to provider${name.isEmpty ? '' : ' $name'}.',
    );
  }

  void providerDisconnected() {
    // Only show disconnection in debug mode
    _addMessage(
      ChatMessageSource.internal,
      'Provider disconnected',
    );
  }

  void _addMessage(
    ChatMessageSource source,
    String msg, {
    Map<String, dynamic>? metadata,
    String sourceName = '',
    String? modelId,
    String? modelName,
    String? toolName,
    String? providerId,
    Map<String, dynamic>? toolArguments,
  }) {
    // Use factory methods for specific types
    ChatMessage message;
    
    switch (source) {
      case ChatMessageSource.notice:
        message = ChatMessage.notice(
          message: msg,
          metadata: metadata,
          sourceName: sourceName.isNotEmpty ? sourceName : 'Notice',
        );
        break;
        
      case ChatMessageSource.system:
        message = ChatMessage.systemInstruction(
          instruction: msg,
          metadata: metadata,
        );
        break;
        
      default:
        // Use the default constructor for other types
        message = ChatMessage(
          source: source,
          message: msg,
          metadata: metadata,
          sourceName: sourceName,
          modelId: modelId,
          modelName: modelName,
          toolName: toolName,
          providerId: providerId,
          toolArguments: toolArguments,
        );
    }
    
    _addChatMessage(message);
  }

  // Helper method to log chat responses with proper chunking
  void _logResponseDetails(String label, Object data) {
    final jsonString = json.encode(data);
    
    // First log the label with clear indication this is full content 
    log('$label, full content below:');
    
    // Then use logWrapped for the content which will show in the browser console
    logWrapped(jsonString);
  }

  // Add a message to the chat history and update the UI
  void _addChatMessage(ChatMessage message) {
    log('Adding message: ${message.message.truncate(64)}');

    // Log complete metadata for tool calls and responses to help with debugging
    if (message.source == ChatMessageSource.provider && message.metadata != null) {
      _logResponseDetails('Handle response: ${message.message.truncate(64)}', message.metadata!);
    }

    // Add the verbose model name for the model if not provided.
    // Note: This should probably be pushed down to the UI logic to support localization.
    if (message.modelName == null && message.modelId != null) {
      final model = _modelManager.getModel(message.modelId!);
      message = message.copyWith(modelName: model?.name);
    }

    setState(() {
      _chatHistory.addMessage(message);
    });
    scrollMessagesDown();
  }

  void _updateSelectedModels(List<String> modelIds) {
    setState(() {
      if (_multiSelectMode) {
        _userSelectedModelIds = modelIds;
      } else {
        // In single-select mode, only keep the most recently selected model
        _userSelectedModelIds = modelIds.isNotEmpty ? [modelIds.last] : [];
      }
    });
    log('Selected models updated to: $_userSelectedModelIds');
    StateManager().onStateChanged();
  }

  void _popAccountDialog() {
    AuthDialog.show(
      context,
      initialChain: _selectedChain,
      initialFunder: _funder,
      initialSignerKey: _signerKey,
      initialAuthToken: _authToken,
      initialInferenceUrl: _inferenceUrl,
      accountDetailNotifier: _accountDetailNotifier,
      onAccountChanged: (chain, funder, signerKey) {
        setState(() {
          _selectedChain = chain;
          _funder = funder;
          _signerKey = signerKey;
          // Clear auth token values when switching to account mode
          _authToken = null;
          _inferenceUrl = null;
        });
        _accountChanged();
      },
      onAuthTokenChanged: (token, url) {
        setState(() {
          _authToken = token;
          _inferenceUrl = url;
          // Clear account values when switching to token mode
          _funder = null;
          _signerKey = null;
        });
        _providerManager.connectWithAuthToken(token, url);
      },
    );
  }

  // item builder
  Widget _buildChatBubble(BuildContext context, int index) {
    return ChatBubble(
      message: _chatHistory.messages[index],
      debugMode: _debugMode,
    );
  }

  void _send() {
    if (_canSendMessages()) {
      _sendUserPrompt();
    } else {
      _popAccountDialog();
    }
  }

  bool _canSendMessages() {
    // Check if we have a direct auth token connection
    if (_authToken != null && _inferenceUrl != null) {
      return true;
    }

    // Check if we have any available tool providers - needed for tools-only mode
    if (_providerManager.toolProviders.isNotEmpty) {
      return true;
    }

    // Traditional check for inference client
    return _providerManager.hasInferenceClient;
  }

  // Validate the prompt, selections, and provider connection and then send the prompt to models.
  void _sendUserPrompt() async {
    var msg = _promptTextController.text;

    // Validate the prompt
    if (msg.trim().isEmpty) {
      return;
    }

    // Validate connection state - check both inference and tool providers
    if (!_providerManager.hasProviderConnection &&
        _providerManager.toolProviders.isEmpty) {
      _addMessage(ChatMessageSource.system, 'Not connected to any provider');
      return;
    }

    // Debug hack
    if (_userSelectedModelIds.isEmpty &&
        ChatScripting.enabled &&
        (UserPreferencesScripts().userScriptEnabled.get() ?? false) &&
        ChatScripting.instance.debugMode) {
      setState(() {
        _userSelectedModelIds = ['gpt-4o'];
      });
    }

    // When only using tools (no models), we may not need a model selection
    final hasOnlyToolProviders = _providerManager.toolProviders.isNotEmpty &&
        !_providerManager.hasInferenceClient;
    final hasEnabledTools = _providerManager.getEnabledTools().isNotEmpty;

    // Validate the selected models (unless we're in tools-only mode)
    if (_userSelectedModelIds.isEmpty &&
        !(hasOnlyToolProviders && hasEnabledTools)) {
      _addMessage(
          ChatMessageSource.system,
          _multiSelectMode
              ? 'Please select at least one model'
              : 'Please select a model');
      return;
    }

    // Manage the prompt UI
    _promptTextController.clear();

    // If we have a script selected allow it to handle the prompt
    if (ChatScripting.enabled) {
      ChatScripting.instance.sendUserPrompt(msg, _userSelectedModels);
    } else {
      _sendUserPromptDefaultBehavior(msg);
    }
  }

  // The default behavior for handling the user prompt and selected models.
  Future<void> _sendUserPromptDefaultBehavior(String msg) async {
    // Set processing flag to enable ESC key cancellation
    setState(() {
      _isProcessingRequest = true;
    });
    
    // Tell the provider manager we have active, cancellable requests
    _providerManager.setHasCancellableRequests(true);
    
    log('Starting processing request - ESC to cancel');
    
    // Ensure the app has focus for keyboard events (only on non-mobile platforms)
    if (!_isMobilePlatform && _keyboardFocusNode.canRequestFocus) {
      _keyboardFocusNode.requestFocus();
    }
    
    try {
      // Add user message immediately to update UI and include in history
      _addMessage(ChatMessageSource.client, msg);

      // Send the prompt to the selected models
      await _sendChatHistoryToSelectedModels();
    } catch (e, stack) {
      log('Error in prompt processing: $e\n$stack');
      _addMessage(
        ChatMessageSource.system,
        'Error processing request: $e',
      );
    } finally {
      // Only reset the processing state if we're not in tool processing mode
      // If we are in tool processing mode, the state will be managed by _processToolCalls
      if (!_inToolProcessingMode) {
        log('Request processing complete, disabling ESC handler');
        // Reset processing flag when done
        setState(() {
          _isProcessingRequest = false;
        });
        // Tell the provider manager there are no more active requests
        _providerManager.setHasCancellableRequests(false);
      } else {
        log('Tool processing in progress, not resetting processing state yet');
      }
    }
  }

  // The default strategy for sending the next round of the full, potentially multi-model, chat history:
  // This strategy selects messages based on the isolated / party mode and sends them sequentially to each
  // of the user-selected models allowing each model to see the previous responses.
  Future<void> _sendChatHistoryToSelectedModels() async {
    // When we only have tool providers and no inference client, we're in tools-only mode
    final hasOnlyToolProviders = _providerManager.toolProviders.isNotEmpty &&
        !_providerManager.hasInferenceClient;
    final hasEnabledTools = _providerManager.getEnabledTools().isNotEmpty;

    // In tools-only mode with no model selected, we create a synthetic response
    if (hasOnlyToolProviders &&
        hasEnabledTools &&
        _userSelectedModelIds.isEmpty) {
      _addMessage(
        ChatMessageSource.system,
        "Using tools-only mode. Available tools: ${_providerManager.getEnabledTools().map((t) => t.name).join(', ')}",
      );
      return;
    }

    // Normal processing for models
    for (final modelId in _userSelectedModelIds) {
      try {
        // Filter messages based on conversation mode.
        final selectedMessages = _partyMode
            ? _chatHistory.getConversation()
            : _chatHistory.getConversation(withModelId: modelId);

        final chatResponse = await _providerManager.sendMessagesToModel(
            selectedMessages, modelId, _maxTokens);

        if (chatResponse != null) {
          _handleChatResponseDefaultBehavior(chatResponse);
        } else {
          // The provider connection should have logged the issue. Do nothing.
        }
      } catch (e) {
        _addMessage(
            ChatMessageSource.system, 'Error querying model $modelId: $e');
      }
    }
  }

  // The default handler for chat responses from the models.
  void _handleChatResponseDefaultBehavior(ChatInferenceResponse chatResponse) {
    final metadata = chatResponse.metadata;
    final modelId = metadata['model_id']; // or request.modelId?
    log('Handle response: ${chatResponse.message ?? "null"}, $metadata');

    final String messageToDisplay =
        chatResponse.message ?? "Processing tool call...";

    // Add the message to the chat history, using a fallback if null
    // IMPORTANT: Always add as provider message to maintain conversation context
    final assistantMessage = ChatMessage(
      source: ChatMessageSource.provider,
      message: messageToDisplay,
      metadata: metadata,
      modelId: modelId,
    );
    
    // Add the message to the chat history
    _addChatMessage(assistantMessage);

    // Check if the response contains tool calls that need to be executed
    if (metadata.containsKey('tool_calls') && metadata['tool_calls'] is List) {
      final toolCalls = metadata['tool_calls'] as List;
      log('Response contains ${toolCalls.length} tool calls to process');

      // We need to maintain the processing request state across the whole sequence
      // Don't reset the _isProcessingRequest flag here as tool processing will take over
      
      // Process each tool call sequentially - this function will handle its own state
      _processToolCalls(toolCalls);
    } else {
      // Only reset the state if there are no tool calls to process
      // This is important to avoid conflict between the reset here and in tool processing
      if (!metadata.containsKey('tool_calls')) {
        log('Response complete - no tool calls to process, resetting processing state');
        setState(() {
          _isProcessingRequest = false;
        });
        _providerManager.setHasCancellableRequests(false);
      }
    }
  }

  // Flag to avoid resetting state in nested async calls
  bool _inToolProcessingMode = false;
  
  // Process and execute tool calls extracted from a model response
  // IMPORTANT: This handles both single tool calls and sequences of tool calls
  Future<void> _processToolCalls(List<dynamic> toolCalls) async {
    // Debug info to track entry/exit
    log('ENTER _processToolCalls with ${toolCalls.length} tool calls');
    
    // Maintain mapping between tool calls and results for proper sequencing
    Map<String, ChatMessage> toolCallResultMap = {};
    // Set the tool processing mode flag to prevent premature state reset
    _inToolProcessingMode = true;
    
    // Mark as processing request so we can interrupt with ESC
    setState(() {
      _isProcessingRequest = true;
    });
    
    // Tell the provider manager we have active, cancellable requests
    _providerManager.setHasCancellableRequests(true);
    
    // Ensure we have focus for keyboard events (only on non-mobile platforms)
    if (!_isMobilePlatform && _keyboardFocusNode.canRequestFocus) {
      _keyboardFocusNode.requestFocus();
    }
    
    List<ChatMessage> toolResultMessages = [];
    String? modelId;

    try {
      for (final toolCall in toolCalls) {
        // Check if request was cancelled before each tool call
        if (!_isProcessingRequest) {
          log('Tool processing was cancelled - skipping remaining tool calls');
          break;
        }
        
        try {
          if (toolCall is! Map) continue;

          // Extract tool details
          final function = toolCall['function'];
          if (function == null || function is! Map) continue;

          final toolName = function['name'];
          if (toolName == null || toolName is! String) continue;

          // Get the tool call ID for response routing
          final toolCallId = toolCall['id'];

          // Parse arguments - may be string JSON or already a map
          Map<String, dynamic> arguments = {};
          if (function.containsKey('arguments')) {
            final args = function['arguments'];
            if (args is String) {
              try {
                arguments = json.decode(args);
              } catch (e) {
                log('Error parsing tool arguments JSON: $e');
                // Use empty arguments if parsing fails
              }
            } else if (args is Map) {
              arguments = Map<String, dynamic>.from(args);
            }
          }

          // Get the model ID for sending results back to the model
          if (modelId == null && toolCall.containsKey('model_id')) {
            modelId = toolCall['model_id'];
          }

          // Get the provider ID either from the tool call or lookup the provider
          String? providerId;
          String? providerName;
          if (toolCall.containsKey('provider_id') &&
              toolCall['provider_id'] != null) {
            providerId = toolCall['provider_id'].toString();
            providerName = toolCall['provider_name']?.toString();
            log('Using provider from tool call: $providerId ($providerName)');
          }

          // Log the tool execution attempt with detailed info
          log('Executing tool call: $toolName');
          // Log complete arguments with proper chunking
          _logResponseDetails('Tool arguments for $toolName', arguments);
          log('Provider ID: $providerId');
          log('Tool call ID: $toolCallId');

          // Add a message to show the tool is being called - with properly formatted arguments
          // Note: Need to handle nullable provider ID and name properly
          _addMessage(
            ChatMessageSource.tool,
            'Calling tool: $toolName',
            metadata: {
              'tool_name': toolName,
              'arguments': arguments,
              'provider_id': providerId ?? '',
              'provider_name': providerName ?? '',
              'tool_call_id': toolCallId,
            },
            sourceName: toolName.contains('__') ? toolName.split('__').last : toolName,
            toolName: toolName,
            toolArguments: arguments,
          );

          // Execute the tool call with the provider manager - making sure it's marked as processing
          // Pass the tool call ID to ensure it's preserved in the result
          final result = await _providerManager.callTool(
            toolName, 
            arguments,
            toolCallId: toolCallId
          );
          
          // Check if request was cancelled during tool execution
          if (!_isProcessingRequest) {
            log('Request was cancelled during tool execution');
            break;
          }

          if (result != null) {
            // CRITICAL: For proper linking of tool calls to results, ensure the toolCallId is preserved
            // First check if the result already has a toolCallId from the API response
            String effectiveToolCallId = result.toolCallId ?? toolCallId ?? '';
            
            if (effectiveToolCallId.isEmpty) {
              log('WARNING: No tool call ID available for tool result. This may cause format errors.');
            } else {
              log('Tool result has tool_call_id: $effectiveToolCallId');
            }
            
            // Add the result to the chat history - with tool_call_id explicitly set
            final resultMessage = ChatMessage.toolResult(
              result: result,
              providerName: providerName ?? result.providerId,
              toolCallId: effectiveToolCallId,
              // Ensure metadata includes critical fields for proper API formatting
              metadata: {
                'tool_call_id': effectiveToolCallId,
                'tool_name': toolName,
                'provider_id': result.providerId,
                'provider_name': providerName ?? result.providerId,
              },
            );
            
            // Verify the result message has the correct tool_call_id in its metadata
            if (resultMessage.metadata == null || 
                !resultMessage.metadata!.containsKey('tool_call_id') ||
                resultMessage.metadata!['tool_call_id'].toString().isEmpty) {
              log('ERROR: Created tool result message without valid tool_call_id!');
            } else {
              log('Verified tool result has tool_call_id: ${resultMessage.metadata!['tool_call_id']}');
            }
            
            // Add to chat history
            _addChatMessage(resultMessage);

            // Store the result message for sending back to the model
            toolResultMessages.add(resultMessage);
            
            // Store in our tool call to result mapping
            if (effectiveToolCallId.isNotEmpty) {
              toolCallResultMap[effectiveToolCallId] = resultMessage;
              log('Added mapping for tool call $effectiveToolCallId to its result');
            }

            // Special extra logging for sequential thinking tool
            if (toolName == 'mcp__sequentialthinking__sequentialthinking') {
              try {
                if (result.content.isNotEmpty && result.content.first.text != null) {
                  final rawContent = result.content.first.text!;
                  log('Sequential thinking raw JSON content:');
                  log(rawContent);
                  
                  final parsed = json.decode(rawContent);
                  final thoughtNumber = parsed['thoughtNumber'] ?? 1;
                  final totalThoughts = parsed['totalThoughts'] ?? 1;
                  final nextThoughtNeeded = parsed['nextThoughtNeeded'] ?? false;
                  final thought = parsed['thought'] ?? '';
                  
                  log('Sequential thinking thought number: $thoughtNumber / $totalThoughts');
                  log('Next thought needed: $nextThoughtNeeded');
                  log('Thought content (first 100 chars): ${thought.toString().substring(0, math.min(100, thought.toString().length))}...');
                  
                  // Add a message showing the parsed thought information to make it more visible
                  _addMessage(
                    ChatMessageSource.internal,
                    'Sequential thinking debug - thought $thoughtNumber/$totalThoughts, nextNeeded=$nextThoughtNeeded',
                  );
                }
              } catch (e) {
                log('Error parsing sequential thinking content: $e');
              }
            }

            log('Tool execution complete: $toolName');
          } else {
            // Log tool execution failure
            _addMessage(
              ChatMessageSource.system,
              'Failed to execute tool: $toolName',
            );
            log('Tool execution failed: $toolName');
          }
        } catch (e, stack) {
          log('Error processing tool call: $e\n$stack');
          _addMessage(
            ChatMessageSource.system,
            'Error processing tool call: $e',
          );
        }
      }

      // Check if we were cancelled before sending results back
      if (_isProcessingRequest && toolResultMessages.isNotEmpty) {
        // Send tool results back to the model to continue conversation
        // Try to get model ID from metadata if not found in tool call
        if (modelId == null) {
          final latestMessages = _chatHistory.getConversation();
          for (final msg in latestMessages.reversed) {
            if (msg.source == ChatMessageSource.provider && msg.modelId != null) {
              modelId = msg.modelId;
              break;
            }
          }
        }

        if (modelId != null) {
          log('Sending ${toolResultMessages.length} tool results back to model: $modelId');
          await _sendToolResultsToModel(toolResultMessages, modelId);
        } else {
          log('No model ID found to send tool results back to');
          _addMessage(
            ChatMessageSource.system,
            'Unable to send tool results - no model ID available',
          );
        }
      } else {
        if (toolResultMessages.isEmpty) {
          log('No tool results to send back to model');
        } else {
          log('Request was cancelled, not sending tool results back to model');
        }
      }
    } finally {
      // Reset the tool processing mode flag
      _inToolProcessingMode = false;
      
      // Only reset processing state if we're not in the middle of a follow-up model call
      // This is checked by examining if toolResultMessages is empty or if all tools failed
      if (toolResultMessages.isEmpty) {
        log('No successful tool results to send back to model, resetting processing state');
        setState(() {
          _isProcessingRequest = false;
        });
        _providerManager.setHasCancellableRequests(false);
      } else {
        log('Tool execution complete with ${toolResultMessages.length} results - maintaining processing state for follow-up model call');
        // Keep processing state active for the follow-up model call
      }
      
      // Debug info to track entry/exit
      log('EXIT _processToolCalls with ${toolResultMessages.length} tool results');
    }
  }

  // Flag to track if recent response has tool calls
  bool _responseHasToolCalls = false;
  
  // Send tool results back to the model to continue the conversation
  Future<void> _sendToolResultsToModel(
      List<ChatMessage> toolResultMessages, String modelId) async {
    // Debug info to track entry/exit
    log('ENTER _sendToolResultsToModel with ${toolResultMessages.length} tool results to model: $modelId');
      
    // Make sure we're marked as processing so interruption works
    setState(() {
      _isProcessingRequest = true;
    });
    
    // Reset tool calls flag
    _responseHasToolCalls = false;
    
    // Update the provider manager state
    _providerManager.setHasCancellableRequests(true);
    
    try {
      // Check if already cancelled
      if (!_isProcessingRequest) {
        log('Request was cancelled before sending tool results to model');
        return;
      }
      
      log('Sending ${toolResultMessages.length} tool results back to model: $modelId');
      
      // Add system message for internal tracking
      _addMessage(
        ChatMessageSource.internal,
        'Sending ${toolResultMessages.length} tool results back to model $modelId for continued conversation',
      );

      // IMPORTANT: Use the FULL conversation history for all inference requests
      // This ensures consistency and avoids the "forgetting" problem with tools
      
      // Get the full conversation from the chat history
      final conversationHistory = _chatHistory.getConversation();
      
      // Use standard formatting for the conversation
      // This will automatically include all user messages, assistant responses,
      // and tool calls/results already in the conversation
      final model = _modelManager.getModel(modelId);
      if (model == null) {
        log('Error: Could not find model info for $modelId');
        _addMessage(
          ChatMessageSource.notice,
          'Failed to send tool results to model',
        );
        return;
      }
      
      // Format the conversation using the standard method
      // The model_api.formatMessages method will properly filter notice/internal messages
      // and format all messages with appropriate roles (user, assistant, system, tool)
      final formattedMessages = model.formatMessages(conversationHistory);
      
      // Log the conversation being sent
      log('Sending complete conversation with ${formattedMessages.length} messages');
      for (int i = 0; i < formattedMessages.length; i++) {
        final msg = formattedMessages[i];
        final role = msg['role'] as String;
        String details = '';
        
        if (role == 'assistant' && msg.containsKey('tool_calls')) {
          final toolCalls = msg['tool_calls'] as List;
          List<String> ids = [];
          for (var tc in toolCalls) {
            if (tc.containsKey('id')) {
              ids.add(tc['id'].toString());
            }
          }
          details = '(with tool calls: ${ids.join(", ")})';
        } else if (role == 'tool' && msg.containsKey('tool_call_id')) {
          details = '(tool_call_id: ${msg['tool_call_id']})';
        }
        
        log('  [$i] $role $details');
      }
      
      // Log message sequence for debugging
      log('Message role sequence:');
      List<String> roleSequence = formattedMessages.map((m) => m['role'] as String).toList();
      log(roleSequence.join(' -> '));
      
      try {
        // Send the formatted messages to the model
        log('Sending complete conversation to model');
        final chatResponse = await _providerManager.sendFormattedMessagesToModel(
            formattedMessages, modelId, _maxTokens);
        
        // Check if we were cancelled during the model call
        if (!_isProcessingRequest) {
          log('Request was cancelled during model continuation call');
          return;
        }

        // Handle the response like a normal model response
        if (chatResponse != null) {
          // Check if this response has tool calls
          final metadata = chatResponse.metadata;
          if (metadata.containsKey('tool_calls') && 
              metadata['tool_calls'] is List && 
              (metadata['tool_calls'] as List).isNotEmpty) {
            // Mark that we have tool calls in this response
            _responseHasToolCalls = true;
            log('Follow-up response has more tool calls, will not reset processing state yet');
            
            // IMPORTANT: Still need to add the assistant message to keep conversation flow
            final assistantMessage = ChatMessage(
              source: ChatMessageSource.provider,
              message: chatResponse.message ?? "Processing additional tool calls...",
              metadata: metadata,
              modelId: modelId,
            );
            
            _addChatMessage(assistantMessage);
            
            // Create an artificial delay to ensure the UI is properly updated
            // and the previous message is visible before we process the tools
            Future.delayed(Duration(milliseconds: 100), () {
              // Now process the tool calls - this maintains the processing state automatically
              final toolCalls = metadata['tool_calls'] as List;
              _processToolCalls(toolCalls);
            });
          } else {
            // Normal response (no tool calls) - process normally
            _handleChatResponseDefaultBehavior(chatResponse);
          }
        } else {
          _addMessage(
            ChatMessageSource.notice,
            'Failed to send tool results to model',
          );
        }
      } catch (e, innerStack) {
        log('Error sending messages to model: $e\n$innerStack');
        _addMessage(
          ChatMessageSource.notice,
          'Error sending continuation request to model: $e',
        );
      }
    } catch (e, stack) {
      log('Error sending tool results to model: $e\n$stack');
      _addMessage(
        ChatMessageSource.notice,
        'Error sending tool results to model: $e',
      );
    } finally {
      // Only reset the processing state if the follow-up response didn't have tool calls
      // This is now handled by _handleChatResponseDefaultBehavior or _processToolCalls
      if (!_responseHasToolCalls) {
        log('Follow-up response complete - no more tool calls to process, resetting state');
        _inToolProcessingMode = false;
        setState(() {
          _isProcessingRequest = false;
        });
        _providerManager.setHasCancellableRequests(false);
      } else {
        log('Follow-up response has more tool calls, maintaining processing state');
        // Do not reset state here as _processToolCalls will handle it
      }
      
      // Debug info to track entry/exit
      log('EXIT _sendToolResultsToModel, responseHasToolCalls=$_responseHasToolCalls');
    }
  }

  void scrollMessagesDown() {
    // Dispatching it to the next frame seems to mitigate overlapping scrolls.
    Future.delayed(millis(50), () {
      messageListController.animateTo(
        messageListController.position.maxScrollExtent,
        duration: millis(300),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _clearChat() {
    setState(() {
      _chatHistory.clear();
    });
  }

  // State management methods
  CoreAppState _captureCurrentState() {
    // Get current script state
    Map<String, dynamic>? scriptState;
    String? scriptUrl;
    
    // Safely get script URL if ChatScripting is initialized
    if (ChatScripting.enabled) {
      scriptUrl = ChatScripting.instance.currentScriptUrl;
    }
    
    final scriptContent = UserPreferencesScripts().userScript.get();
    if (scriptUrl != null || scriptContent != null) {
      scriptState = {
        'url': scriptUrl,
        'content': scriptContent,
        'enabled': UserPreferencesScripts().userScriptEnabled.get(),
      };
    }

    return CoreAppState(
      providers: _providerManager.getProvidersConfig(),
      selectedModelIds: _userSelectedModelIds,
      maxTokens: _maxTokens,
      disabledTools: _providerManager.disabledTools,
      script: scriptState,
      uiPreferences: {
        'debugMode': _debugMode,
        'multiSelectMode': _multiSelectMode,
        'partyMode': _partyMode,
      },
    );
  }

  void _applyState(CoreAppState state) {
    setState(() {
      // Apply UI preferences
      _debugMode = state.uiPreferences['debugMode'] ?? false;
      _multiSelectMode = state.uiPreferences['multiSelectMode'] ?? false;
      _partyMode = state.uiPreferences['partyMode'] ?? false;
      
      // Apply model selection
      _userSelectedModelIds = state.selectedModelIds;
      
      // Apply max tokens
      _maxTokens = state.maxTokens;
      if (_maxTokens != null) {
        _maxTokensController.value = _maxTokens!.toDouble();
      }
    });

    // Apply providers configuration
    if (state.providers.isNotEmpty) {
      _providerManager.setProvidersFromState(state.providers);
    }

    // Apply disabled tools
    _providerManager.setDisabledTools(state.disabledTools);

    // Apply script state
    if (state.script != null) {
      final scriptUrl = state.script!['url'] as String?;
      final scriptContent = state.script!['content'] as String?;
      final scriptEnabled = state.script!['enabled'] as bool? ?? false;

      if (scriptUrl != null && ChatScripting.enabled) {
        ChatScripting.instance.setURL(scriptUrl);
      } else if (scriptContent != null) {
        UserPreferencesScripts().userScript.set(scriptContent);
        UserPreferencesScripts().userScriptEnabled.set(scriptEnabled);
        if (scriptEnabled && ChatScripting.enabled) {
          ChatScripting.instance.setScript(scriptContent);
        }
      }
    }
  }

  void _exportState() async {
    try {
      final stateJson = await StateManager().exportFullState();
      final canGenerateDirectLink = stateJson.length <= 100000; // ~100KB limit for URLs
      
      // Show export dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session includes ${_chatHistory.messages.length} messages'),
                Text('Size: ${(stateJson.length / 1024).toStringAsFixed(1)} KB'),
                const SizedBox(height: 16),
                
                if (canGenerateDirectLink) ...[
                  Row(
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Privacy-preserving link (client-side only)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Copy Private Link'),
                    onPressed: () async {
                      final url = await StateManager().getShareableUrl(useHashbang: true);
                      await Clipboard.setData(ClipboardData(text: url));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Private link copied to clipboard')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                
                const Text('Or save this JSON to GitHub Gist, Pastebin, or any text hosting service:'),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: TextField(
                    controller: TextEditingController(text: stateJson),
                    maxLines: null,
                    readOnly: true,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: stateJson));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('JSON copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                if (!canGenerateDirectLink) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Session too large for direct link. Please use external hosting.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange[700]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export state: $e')),
      );
    }
  }

  void _importState() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste the session JSON or enter a URL to load from:'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste JSON or URL here...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final input = textController.text.trim();
              if (input.isEmpty) return;

              try {
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Importing session...'),
                      ],
                    ),
                  ),
                );
                
                // Check if it's a URL
                String processedInput = input;
                
                // Auto-add https:// if it looks like a URL without protocol
                if (!input.startsWith('http://') && 
                    !input.startsWith('https://') && 
                    !input.startsWith('data:') &&
                    !input.startsWith('{') &&
                    (input.contains('.') && (input.contains('/') || input.split('.').last.length <= 4))) {
                  processedInput = 'https://$input';
                }
                
                if (processedInput.startsWith('http://') || processedInput.startsWith('https://')) {
                  // Fetch content from URL
                  final response = await http.get(Uri.parse(processedInput));
                  if (response.statusCode == 200) {
                    await StateManager().importStateJson(response.body, isFullState: true);
                  } else {
                    throw Exception('Failed to fetch from URL: ${response.statusCode}');
                  }
                } else if (processedInput.startsWith('data:')) {
                  // Handle data URL
                  final base64Part = processedInput.split(',').last;
                  final bytes = base64Decode(base64Part);
                  final jsonStr = utf8.decode(bytes);
                  await StateManager().importStateJson(jsonStr, isFullState: true);
                } else {
                  // Import JSON directly
                  await StateManager().importStateJson(processedInput, isFullState: true);
                }
                
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session imported successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog if error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to import state: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accountDetail?.cancel();
    _keyboardFocusNode.dispose();
    
    // Clean up global keyboard listener (only if it was added on non-mobile platforms)
    if (!_isMobilePlatform && kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minWidth = 500.0;
    var showIcons = AppSize(context).narrowerThanWidth(700);
    var showMinWidth = AppSize(context).narrowerThanWidth(minWidth);
    
    // Request focus for keyboard detection on first build (only on non-mobile platforms)
    if (!_isMobilePlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_keyboardFocusNode.canRequestFocus) {
          _keyboardFocusNode.requestFocus();
        }
      });
    }
    
    // Use a global key so we can access this widget from anywhere 
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    
    // Listen for key presses at the document level (more reliable in web)
    // Only wrap with Focus on desktop to avoid interfering with mobile text input
    Widget scaffoldWidget = Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Container(
                decoration: const BoxDecoration(
                  gradient: OrchidGradients.blackGradientBackground,
                ),
              ),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                      // header row
                      if (showMinWidth)
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                                width: minWidth,
                                child: _buildHeaderRow(showIcons: showIcons)))
                      else
                        _buildHeaderRow(showIcons: showIcons),
                      // Messages area
                      _buildChatPane(),
                      // Prompt row
                      AnimatedSize(
                        alignment: Alignment.topCenter,
                        duration: millis(150),
                        child: ChatPromptPanel(
                          promptTextController: _promptTextController,
                          onSubmit: _send,
                          setMaxTokens: _setMaxTokens,
                          maxTokensController: _maxTokensController,
                        ).top(8),
                      ),
                      // Processing indicator
                      if (_isProcessingRequest)
                        GestureDetector(
                          onTap: !_isMobilePlatform ? _cancelOngoingRequests : null, // Disable tap cancellation on mobile
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_isMobilePlatform 
                                    ? 'Processing...' 
                                    : 'Processing... Press ESC or tap here to cancel', 
                                  style: OrchidText.caption.copyWith(
                                    color: Colors.white70,
                                    decoration: _isMobilePlatform 
                                        ? TextDecoration.none 
                                        : TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ).top(8).bottom(8),
              ),
            ],
          ),
        ),
      );
    
    // Only wrap with Focus on desktop platforms to avoid interfering with mobile text input
    if (!_isMobilePlatform) {
      return Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          // Check for escape key
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            if (_isProcessingRequest) {
              _cancelOngoingRequests();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: scaffoldWidget,
      );
    } else {
      return scaffoldWidget;
    }
  }

  Widget _buildChatPane() {
    return Flexible(
      child: Stack(
        children: <Widget>[
          ListView.builder(
            controller: messageListController,
            itemCount: _chatHistory.messages.length,
            itemBuilder: _buildChatBubble,
          ).top(16),
          if (_emptyState() && !_calloutDismissed)
            Positioned(
              top: 35, // Adjust this value to align with the Account button
              right: 0,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: CalloutPainter(),
                    child: Container(
                      width: 390,
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'This is a demonstration of the application of Orchid Nanopayments within a consolidated Multi-LLM chat service.',
                            style:
                                OrchidText.normal_14.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'To get started, enter or create a funded Orchid account.',
                            style:
                                OrchidText.normal_14.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          ChatButton(
                            text: 'Enter Account',
                            onPressed: _popAccountDialog,
                            width: 200,
                          ).top(24),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () =>
                                _launchURL('https://account.orchid.com'),
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: Theme.of(context).primaryColor),
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Create Account').button,
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://docs.orchid.com/en/latest/accounts/'),
                            child: Text(
                              'Learn more about creating an Orchid account',
                              style: TextStyle(
                                  color: Colors.blue[300],
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Close button positioned at top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withOpacity(0.8)),
                      onPressed: () {
                        setState(() {
                          _calloutDismissed = true;
                        });
                      },
                      tooltip: 'Dismiss',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow({required bool showIcons}) {
    const buttonHeight = 40.0;

    return Row(
      children: <Widget>[
        // Logo
        SizedBox(height: buttonHeight, child: OrchidAsset.image.logo),

        // Model selector with loading state
        ListenableBuilder(
          listenable: _modelManager,
          builder: (context, _) {
            if (_modelManager.isAnyLoading) {
              return const SizedBox(
                width: buttonHeight,
                height: buttonHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            return ModelSelectionButton(
              models: _modelManager.allModels,
              selectedModelIds: _userSelectedModelIds,
              updateModels: _updateSelectedModels,
              multiSelectMode: _multiSelectMode,
            );
          },
        ).left(24),

        const Spacer(),

        // Account button
        OutlinedChatButton(
          text: 'Account',
          onPressed: _popAccountDialog,
          height: buttonHeight,
          icon: _emptyState()
              ? Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.amber,
                )
              : null,
        ).left(8),

        // Settings button
        _buildSettingsButton(
          buttonHeight,
          authToken: _authToken ??
              _providerManager.providerConnection?.inferenceClient?.authToken,
          inferenceUrl: _inferenceUrl ??
              _providerManager.providerConnection?.inferenceClient?.baseUrl,
        ).left(8),
      ],
    );
  }

  SizedBox _buildSettingsButton(double buttonHeight,
      {String? authToken, String? inferenceUrl}) {
    final settingsIconSize = buttonHeight * 1.5;
    return SizedBox(
      width: settingsIconSize,
      height: buttonHeight,
      child: Center(
        child: ChatSettingsButton(
          debugMode: _debugMode,
          multiSelectMode: _multiSelectMode,
          partyMode: _partyMode,
          onDebugModeChanged: () {
            setState(() {
              _debugMode = !_debugMode;
            });
            StateManager().onStateChanged();
          },
          onMultiSelectModeChanged: () {
            setState(() {
              _multiSelectMode = !_multiSelectMode;
              // Reset selections when toggling modes
              _userSelectedModelIds = [];
            });
            StateManager().onStateChanged();
          },
          onPartyModeChanged: () {
            setState(() {
              _partyMode = !_partyMode;
              if (_partyMode) {
                _multiSelectMode = true;
              }
            });
            StateManager().onStateChanged();
          },
          onClearChat: _clearChat,
          editUserScript: () {
            UserScriptDialog.show(context);
          },
          onExportState: _exportState,
          onImportState: _importState,
          authToken: authToken,
          inferenceUrl: inferenceUrl,
          stateUrl: StateManager().loadedStateUrl,
        ),
      ),
    );
  }
}

Future<void> _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url)) {
    throw 'Could not launch $url';
  }
}
