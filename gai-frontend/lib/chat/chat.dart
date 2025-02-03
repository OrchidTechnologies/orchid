import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
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

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  // UI state
  bool _debugMode = false;
  bool _multiSelectMode = false;
  bool _partyMode = false;
  int? _maxTokens;
  Chain _selectedChain = Chains.Gnosis;
  final ScrollController messageListController = ScrollController();
  final _promptTextController = TextEditingController();
  final _maxTokensController = NumericValueFieldController();

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
    try {
      _initFromParams();
      // If we have providers and an account, connect to first provider
      _providerManager.connectToInitialProvider();
    } catch (e, stack) {
      log('Error initializing from params: $e, $stack');
    }

    // Initialize the scripting extension mechanism
    _initScripting();
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

  void _accountChanged() async {
    log("chat: accountChanged: $_account");
    _accountDetail?.cancel();
    _accountDetail = null;

    if (_account != null) {
      _accountDetail = AccountDetailPoller(account: _account!);
      await _accountDetail?.pollOnce();

      // Disconnects any existing provider connection
      _providerManager.setAccountDetail(_accountDetail);

      // Connect to provider with new account
      _providerManager.connectToInitialProvider();
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
  void _initFromParams() {
    final params = OrchidUserParams();
    _funder = params.getEthereumAddress('funder');
    _signerKey = params.getBigInt('signer');
    _accountChanged();

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
  }) {
    _addChatMessage(ChatMessage(
      source: source,
      message: msg,
      metadata: metadata,
      sourceName: sourceName,
      modelId: modelId,
      modelName: modelName,
    ));
  }

  // Add a message to the chat history and update the UI
  void _addChatMessage(ChatMessage message) {
    log('Adding message: ${message.message.truncate(64)}');

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
    return (_providerManager.hasInferenceClient) ||
        (_authToken != null && _inferenceUrl != null);
  }

  // Validate the prompt, selections, and provider connection and then send the prompt to models.
  void _sendUserPrompt() async {
    var msg = _promptTextController.text;

    // Validate the prompt
    if (msg.trim().isEmpty) {
      return;
    }

    // Validate the provider connection
    if (!_providerManager.hasProviderConnection) {
      _addMessage(ChatMessageSource.system, 'Not connected to provider');
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

    // Validate the selected models
    if (_userSelectedModelIds.isEmpty) {
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
    // Add user message immediately to update UI and include in history
    _addMessage(ChatMessageSource.client, msg);

    // Send the prompt to the selected models
    await _sendChatHistoryToSelectedModels();
  }

  // The default strategy for sending the next round of the full, potentially multi-model, chat history:
  // This strategy selects messages based on the isolated / party mode and sends them sequentially to each
  // of the user-selected models allowing each model to see the previous responses.
  Future<void> _sendChatHistoryToSelectedModels() async {
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

  // The default handler for chat responses from the models (simply adds response to the chat history).
  void _handleChatResponseDefaultBehavior(ChatInferenceResponse chatResponse) {
    final metadata = chatResponse.metadata;
    final modelId = metadata['model_id']; // or request.modelId?
    log('Handle response: ${chatResponse.message}, $metadata');
    _addMessage(
      ChatMessageSource.provider,
      chatResponse.message,
      metadata: metadata,
      modelId: modelId,
    );
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

  @override
  void dispose() {
    _accountDetail?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minWidth = 500.0;
    var showIcons = AppSize(context).narrowerThanWidth(700);
    var showMinWidth = AppSize(context).narrowerThanWidth(minWidth);
    return Scaffold(
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
                  ],
                ),
              ).top(8).bottom(8),
            ),
          ],
        ),
      ),
    );
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
          if (_emptyState())
            Positioned(
              top: 35, // Adjust this value to align with the Account button
              right: 0,
              child: CustomPaint(
                painter: CalloutPainter(),
                child: Container(
                  width: 390,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
        ).left(8),

        // Settings button
        _buildSettingsButton(
          buttonHeight,
          authToken: _authToken ?? _providerManager.providerConnection?.inferenceClient?.authToken,
          inferenceUrl: _inferenceUrl ?? _providerManager.providerConnection?.inferenceClient?.baseUrl,
        ).left(8),
      ],
    );
  }

  SizedBox _buildSettingsButton(double buttonHeight, {String? authToken, String? inferenceUrl}) {
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
          },
          onMultiSelectModeChanged: () {
            setState(() {
              _multiSelectMode = !_multiSelectMode;
              // Reset selections when toggling modes
              _userSelectedModelIds = [];
            });
          },
          onPartyModeChanged: () {
            setState(() {
              _partyMode = !_partyMode;
              if (_partyMode) {
                _multiSelectMode = true;
              }
            });
          },
          onClearChat: _clearChat,
          editUserScript: () {
            UserScriptDialog.show(context);
          },
          authToken: authToken,
          inferenceUrl: inferenceUrl,
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
