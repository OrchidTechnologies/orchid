import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_keys.dart';
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
import 'models.dart';
import 'auth_dialog.dart';
import 'chat_history.dart';
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
  final ModelsState _modelsState = ModelsState();
  List<String> _selectedModelIds = [];

  // Account
  // This should be wrapped up in a provider.  See WIP in vpn app.
  EthereumAddress? _funder;
  BigInt? _signerKey;
  AccountDetailPoller? _accountDetail;
  final _accountDetailNotifier = ValueNotifier<AccountDetail?>(null);

  // Auth
  // AuthTokenMethod _authTokenMethod = AuthTokenMethod.manual;
  String? _authToken;
  String? _inferenceUrl;

  @override
  void initState() {
    super.initState();

    // Init the provider manager
    _providerManager = ProviderManager(
      modelsState: _modelsState,
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

  // This should be wrapped up in a provider.  See WIP in vpn app.
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
      _modelsState.clear();
    }

    _accountDetailNotifier.value =
        _accountDetail; // This notifies the listeners
    setState(() {});
  }

  // Init from user parameters (for web)
  void _initFromParams() {
    Map<String, String> params = Uri.base.queryParameters;
    try {
      _funder = EthereumAddress.from(params['funder'] ?? '');
    } catch (e) {
      _funder = null;
    }
    try {
      _signerKey = BigInt.parse(params['signer'] ?? '');
    } catch (e) {
      _signerKey = null;
    }
    _accountChanged();

    String? provider = params['provider'];
    if (provider != null) {
      _providerManager.setUserProvider(provider);
    }
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
    final message = ChatMessage(
      source,
      msg,
      metadata: metadata,
      sourceName: sourceName,
      modelId: modelId,
      modelName: modelName,
    );
    _addChatMessage(message);
  }

  void _addChatMessage(ChatMessage message) {
    log('Adding message: ${message.msg.truncate(64)}');
    setState(() {
      _chatHistory.addMessage(message);
    });
    scrollMessagesDown();
    log('Chat history updated: ${_chatHistory.messages.length}, ${_chatHistory.messages}');
  }

  void _updateSelectedModels(List<String> modelIds) {
    setState(() {
      if (_multiSelectMode) {
        _selectedModelIds = modelIds;
      } else {
        // In single-select mode, only keep the most recently selected model
        _selectedModelIds = modelIds.isNotEmpty ? [modelIds.last] : [];
      }
    });
    log('Selected models updated to: $_selectedModelIds');
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
        // log('onAccountChanged: Account changed: $chain, $funder, $signerKey');
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
      _sendPrompt();
    } else {
      _popAccountDialog();
    }
  }

  bool _canSendMessages() {
    return (_providerManager.hasInferenceClient) ||
        (_authToken != null && _inferenceUrl != null);
  }

  // Apply the prompt to history and send to selected models
  void _sendPrompt() async {
    var msg = _promptTextController.text;
    if (msg.trim().isEmpty) {
      return;
    }

    if (!_providerManager.hasProviderConnection) {
      _addMessage(ChatMessageSource.system, 'Not connected to provider');
      return;
    }

    if (_selectedModelIds.isEmpty) {
      _addMessage(
          ChatMessageSource.system,
          _multiSelectMode
              ? 'Please select at least one model'
              : 'Please select a model');
      return;
    }

    // Add user message immediately to update UI and include in history
    _addMessage(ChatMessageSource.client, msg);
    _promptTextController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    await _sendChatToModels();
  }

  // Send the appropriate chat history to the selected models
  Future<void> _sendChatToModels() async {
    for (final modelId in _selectedModelIds) {
      try {
        final modelInfo = _modelsState.allModels.firstWhere(
          (m) => m.id == modelId,
          orElse: () => ModelInfo(
            id: modelId,
            name: modelId,
            provider: '',
            apiType: '',
          ),
        );

        // Prepare messages for this specific model
        final preparedMessages = _chatHistory.prepareForModel(
          modelId: modelId,
          preparationFunction:
              _partyMode ? ChatHistory.partyMode : ChatHistory.isolatedMode,
        );
        Map<String, Object>? params;
        if (_maxTokens != null) {
          params = {'max_tokens': _maxTokens!};
        }

        _addMessage(
          ChatMessageSource.internal,
          'Querying ${modelInfo.name}...',
          modelId: modelId,
          modelName: modelInfo.name,
        );

        // TODO: Move request inference to the provider manager?
        await _providerManager.providerConnection?.requestInference(
          modelId,
          preparedMessages,
          params: params,
        );
      } catch (e) {
        _addMessage(
            ChatMessageSource.system, 'Error querying model $modelId: $e');
      }
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

  List<PopupMenuEntry<OrchataMenuItem>> buildMenu(BuildContext context) {
    return <PopupMenuEntry<OrchataMenuItem>>[
      const PopupMenuItem<OrchataMenuItem>(
        value: OrchataMenuItem.debug,
        child: Text('Debug'),
      )
    ];
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
    const settingsIconSize = buttonHeight * 1.5;

    return Row(
      children: <Widget>[
        // Logo
        SizedBox(height: buttonHeight, child: OrchidAsset.image.logo),

        // Model selector with loading state
        ListenableBuilder(
          listenable: _modelsState,
          builder: (context, _) {
            if (_modelsState.isAnyLoading) {
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
              models: _modelsState.allModels,
              selectedModelIds: _selectedModelIds,
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
        SizedBox(
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
                  _selectedModelIds = [];
                });
              },
              onPartyModeChanged: () {
                setState(() {
                  _partyMode = !_partyMode;
                });
              },
              onClearChat: _clearChat,
            ),
          ),
        ).left(8),
      ],
    );
  }
}

Future<void> _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url)) {
    throw 'Could not launch $url';
  }
}

enum AuthTokenMethod { manual, walletConnect }

enum OrchataMenuItem { debug }
