import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'chat_message.dart';
import 'model_manager.dart';
import 'provider_connection.dart';
import 'dart:convert';

// Manage the provider state for the UI, including the map of providers and the active provider connection.
class ProviderManager {
  late final Map<String, Map<String, String>> _providers;
  final VoidCallback onProviderConnected;
  final VoidCallback onProviderDisconnected;
  final void Function(ChatMessage) onChatMessage;

  final ModelManager modelsState;

  AccountDetail? accountDetail;
  ProviderConnection? providerConnection;
  bool _connected = false;

  bool get connected {
    return _connected;
  }

  ProviderManager({
    required this.modelsState,
    required this.onProviderConnected,
    required this.onProviderDisconnected,
    required this.onChatMessage,
  }) {
    init();
  }

  void init() {
    _providers = getFromEnv();
  }

  void setAccountDetail(AccountDetail? accountDetail) {
    this.accountDetail = accountDetail;
    if (_connected) {
      providerConnection?.dispose();
      _connected = false;
    }
  }

  void setProviders(Map<String, Map<String, String>> providers) {
    _providers = providers;
  }

  void setUserProvider(String provider) {
    setProviders({
      'user-provider': {'url': provider, 'name': 'User Provider'}
    });
  }

  bool get hasProviderConnection => providerConnection != null;

  bool get hasInferenceClient => providerConnection?.inferenceClient != null;

  void connectToInitialProvider() {
    if (_providers.isEmpty) {
      log('No providers configured');
      return;
    }

    // Get first provider from the list
    final firstProviderId = _providers.keys.first;
    final firstProvider = _providers[firstProviderId];
    if (firstProvider == null) {
      log('Invalid provider configuration');
      return;
    }

    log('Connecting to initial provider: ${firstProvider['name']}');
    _connectProvider(firstProviderId);
  }

  void _addMessage(
    ChatMessageSource source,
    String msg, {
    Map<String, dynamic>? metadata,
    String sourceName = '',
    String? modelId,
    String? modelName,
  }) {
    final message = ChatMessage(
      source,
      msg,
      metadata: metadata,
      sourceName: sourceName,
      modelId: modelId,
      modelName: modelName,
    );
    onChatMessage(message);
  }

  // TODO: review duplication between auth modes
  void connectWithAuthToken(String token, String inferenceUrl) async {
    // Clean up existing connection if any
    if (_connected) {
      providerConnection?.dispose();
      _connected = false;
    }

    try {
      providerConnection = await ProviderConnection.connect(
        billingUrl: inferenceUrl,
        inferenceUrl: inferenceUrl,
        contract: null,
        accountDetail: null,
        authToken: token,
        onMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () {
          _providerConnected('Direct Auth');
        },
        onChat: (String msg, Map<String, dynamic> metadata) {
          _addMessage(
            ChatMessageSource.provider,
            msg,
            metadata: metadata,
            modelId: metadata['model_id'],
            modelName: modelsState
                .getModelOrDefaultNullable(metadata['model_id'])
                ?.name,
          );
        },
        onDisconnect: _providerDisconnected,
        onError: (msg) {
          _addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          _addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
      );
      // Fetch models after connection
      if (providerConnection?.inferenceClient != null) {
        await modelsState.fetchModelsForProvider(
          'direct-auth',
          providerConnection!.inferenceClient!,
        );
      }
    } catch (e, stack) {
      log('Error connecting with auth token: $e\n$stack');
      _addMessage(ChatMessageSource.system, 'Failed to connect: $e');
    }
  }

  void _connectProvider([String provider = '']) async {
    var account = accountDetail;
    if (account == null) {
      log('_connectProvider() -- No account');
      return;
    }
    if (_providers.isEmpty) {
      log('_connectProvider() -- _providers.isEmpty');
      return;
    }

    // Clean up existing connection if any
    if (_connected) {
      providerConnection?.dispose();
      _connected = false;
    }

    // Determine which provider to connect to
    String providerId;
    if (provider.isEmpty) {
      providerId = _providers.keys.first;
    } else {
      providerId = provider;
    }

    final providerInfo = _providers[providerId];
    if (providerInfo == null) {
      log('Provider not found: $providerId');
      return;
    }

    final wsUrl = providerInfo['url'] ?? '';
    final name = providerInfo['name'] ?? '';
    final httpUrl =
        wsUrl.replaceFirst('ws:', 'http:').replaceFirst('wss:', 'https:');

    log('Connecting to provider: $name (ws: $wsUrl, http: $httpUrl)');

    try {
      providerConnection = await ProviderConnection.connect(
        billingUrl: wsUrl,
        inferenceUrl: httpUrl,
        contract:
            EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'),
        accountDetail: account,
        onMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () {
          _providerConnected(name);
        },
        onChat: (String msg, Map<String, dynamic> metadata) {
          log('onChat received metadata: $metadata');
          final modelId = metadata['model_id'];
          log('Found model_id: $modelId');

          _addMessage(
            ChatMessageSource.provider,
            msg,
            metadata: metadata,
            modelId: modelId,
            modelName: modelsState.getModelOrDefaultNullable(modelId)?.name,
          );
        },
        onDisconnect: _providerDisconnected,
        onError: (msg) {
          _addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          _addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onAuthToken: (token, url) async {
          // Fetch models after receiving token
          log('Fetching models after auth token receipt');
          if (providerConnection?.inferenceClient != null) {
            await modelsState.fetchModelsForProvider(
              providerId,
              providerConnection!.inferenceClient!,
            );
          }
        },
      );

      // Request auth token - model fetch will happen in callback
      await providerConnection?.requestAuthToken();
    } catch (e, stack) {
      log('Error connecting to provider: $e\n$stack');
      _addMessage(
          ChatMessageSource.system, 'Failed to connect to provider: $e');
    }
  }

  void _providerConnected([name = '']) {
    _connected = true;
    onProviderConnected();
  }

  void _providerDisconnected() {
    _connected = false;
    onProviderDisconnected();
  }

  // Note: This method is exposed to the scripting environment.
  Future<void> sendMessagesToModel(
    List<ChatMessage> messages,
    String modelId,
    int? maxTokens,
  ) {
    final modelInfo = modelsState.getModelOrDefault(modelId);

    // Format messages for this model
    // Note: The default formatting logic knows how to render messages from foreign models
    // Note: as other "user" roles with prefixed model names.  The scripting environment
    // Note: can override this formatting by calling sendFormattedMessagesToModel() directly.
    final formattedMessages = modelInfo.formatMessages(messages);
    return sendFormattedMessagesToModel(formattedMessages, modelId, maxTokens);
  }

  // Note: This method is exposed to the scripting environment.
  Future<void> sendFormattedMessagesToModel(
    List<Map<String, String>> formattedMessages,
    String modelId,
    int? maxTokens,
  ) async {
    // Add api params
    Map<String, Object>? params;
    if (maxTokens != null) {
      params = {'max_tokens': maxTokens};
    }

    final modelInfo = modelsState.getModelOrDefault(modelId);
    _addMessage(
      ChatMessageSource.internal,
      'Querying ${modelInfo.name}...',
      modelId: modelInfo.id,
      modelName: modelInfo.name,
    );

    await providerConnection?.requestInference(
      modelInfo.id,
      formattedMessages,
      params: params,
    );
  }

  static Map<String, Map<String, String>> getFromEnv() {
    final providersJson =
        const String.fromEnvironment('PROVIDERS', defaultValue: '{}');
    log(providersJson);
    try {
      final providers = json.decode(providersJson) as Map<String, dynamic>;
      return providers
          .map((key, value) => MapEntry(key, Map<String, String>.from(value)));
    } catch (e) {
      log('Error parsing providers configuration: $e');
      return {};
    }
  }
}
