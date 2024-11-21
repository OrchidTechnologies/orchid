import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/chat/chat_settings_button.dart';
import 'package:orchid/gui-orchid/lib/orchid/menu/orchid_chain_selector_menu.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';

import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_bubble.dart';
import 'chat_button.dart';
import 'chat_message.dart';
import 'chat_prompt.dart';
import 'chat_model_button.dart';
import 'models.dart';
import 'provider_connection.dart';
import '../config/providers_config.dart';
import 'auth_dialog.dart';

enum AuthTokenMethod { manual, walletConnect }

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<ChatMessage> _messages = [];
  late final Map<String, Map<String, String>> _providers;
  int _providerIndex = 0;
  bool _debugMode = false;
  bool _multiSelectMode = false;
  bool _connected = false;
  ProviderConnection? _providerConnection;
  int? _maxTokens; 

  // The active account components
  EthereumAddress? _funder;
  BigInt? _signerKey;

  final _signerFieldController = TextEditingController();
  final _funderFieldController = AddressValueFieldController();
  final ScrollController messageListController = ScrollController();
  final _promptTextController = TextEditingController();
  final _maxTokensController = NumericValueFieldController();
  bool _showPromptDetails = false;
  Chain _selectedChain = Chains.Gnosis;
  final ModelsState _modelsState = ModelsState();
  List<String> _selectedModelIds = [];

  AuthTokenMethod _authTokenMethod = AuthTokenMethod.manual;
  String? _authToken;
  String? _inferenceUrl;

  @override
  void initState() {
    super.initState();
    _providers = ProvidersConfig.getProviders();
    try {
      _initFromParams();
      // If we have providers and an account, connect to first provider
      _connectToInitialProvider();
    } catch (e, stack) {
      log('Error initializing from params: $e, $stack');
    }
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

  void _connectToInitialProvider() {
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

  void _connectWithAuthToken(String token, String inferenceUrl) async {
    // Clean up existing connection if any
    if (_connected) {
      _providerConnection?.dispose();
      _connected = false;
    }

    try {
      _providerConnection = await ProviderConnection.connect(
        billingUrl: inferenceUrl,
        inferenceUrl: inferenceUrl,
        contract: null,
        accountDetail: null,
        authToken: token,
        onMessage: (msg) {
          addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () { 
          providerConnected('Direct Auth');
        },
        onChat: (msg, metadata) {
          addMessage(
            ChatMessageSource.provider,
            msg,
            metadata: metadata,
            modelId: metadata['model_id'],
            modelName: _modelsState.getModelName(metadata['model_id']),
          );
        },
        onDisconnect: providerDisconnected,
        onError: (msg) {
          addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          addMessage(ChatMessageSource.internal, msg);
        },
      );
      // Fetch models after connection
      if (_providerConnection?.inferenceClient != null) {
        await _modelsState.fetchModelsForProvider(
          'direct-auth',
          _providerConnection!.inferenceClient!,
        );
      }

    } catch (e, stack) {
      log('Error connecting with auth token: $e\n$stack');
      addMessage(ChatMessageSource.system, 'Failed to connect: $e');
    }
  }

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
  AccountDetailPoller? _accountDetail;
  final _accountDetailNotifier = ChangeNotifier();

  // This should be wrapped up in a provider.  See WIP in vpn app.
  void _accountChanged() async {
    log("accountChanged: $_account");
    _accountDetail?.cancel();
    _accountDetail = null;
    if (_account != null) {
      _accountDetail = AccountDetailPoller(account: _account!);
      await _accountDetail?.pollOnce();
      
      // Disconnect any existing provider connection
      if (_connected) {
        _providerConnection?.dispose();
        _connected = false;
      }
      
      // Connect to provider with new account
      _connectToInitialProvider();
    }
    _accountDetailNotifier.notifyListeners();
    setState(() {});
  }

  // Init from user parameters (for web)
  void _initFromParams() {
    Map<String, String> params = Uri.base.queryParameters;
    try {
      _funder = EthereumAddress.from(params['funder'] ?? '');
      _funderFieldController.text = _funder.toString();
    } catch (e) {
      _funder = null;
    }
    try {
      _signerKey = BigInt.parse(params['signer'] ?? '');
      _signerFieldController.text = _signerKey.toString();
    } catch (e) {
      _signerKey = null;
    }
    _accountChanged();
    String? provider = params['provider'];
    if (provider != null) {
      _providers = {'user-provider': {'url': provider, 'name': 'User Provider'}};
    }
  }

  void providerConnected([name = '']) {
    _connected = true;
    // Only show connection message in debug mode
    addMessage(
      ChatMessageSource.internal,
      'Connected to provider${name.isEmpty ? '' : ' $name'}.',
    );
  }

  void providerDisconnected() {
    _connected = false;
    // Only show disconnection in debug mode
    addMessage(
      ChatMessageSource.internal,
      'Provider disconnected',
    );
  }
  
  void _connectProvider([String provider = '']) async {
    var account = _accountDetail;
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
      _providerConnection?.dispose();
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
    final httpUrl = wsUrl.replaceFirst('ws:', 'http:').replaceFirst('wss:', 'https:');

    log('Connecting to provider: $name (ws: $wsUrl, http: $httpUrl)');

    try {
      _providerConnection = await ProviderConnection.connect(
        billingUrl: wsUrl,
        inferenceUrl: httpUrl,
        contract: EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'),
        accountDetail: account,
        onMessage: (msg) {
          addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () { 
          providerConnected(name);
        },
        onChat: (msg, metadata) {
          print('onChat received metadata: $metadata');
          final modelId = metadata['model_id'];
          print('Found model_id: $modelId'); 
          
          addMessage(
            ChatMessageSource.provider,
            msg,
            metadata: metadata,
            modelId: modelId,
            modelName: _modelsState.getModelName(modelId),
          );
        },
        onDisconnect: providerDisconnected,
        onError: (msg) {
          addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          addMessage(ChatMessageSource.internal, msg);
        },
        onAuthToken: (token, url) async {
          // Fetch models after receiving token
          log('Fetching models after auth token receipt');
          if (_providerConnection?.inferenceClient != null) {
            await _modelsState.fetchModelsForProvider(
              providerId,
              _providerConnection!.inferenceClient!,
            );
          }
        },
      );

      // Request auth token - model fetch will happen in callback
      await _providerConnection?.requestAuthToken();

    } catch (e, stack) {
      log('Error connecting to provider: $e\n$stack');
      addMessage(ChatMessageSource.system, 'Failed to connect to provider: $e');
    }
  }
  
  void addMessage(
    ChatMessageSource source,
    String msg, {
    Map<String, dynamic>? metadata,
    String sourceName = '',
    String? modelId,
    String? modelName,
  }) {
    log('Adding message: ${msg.truncate(64)}');
    setState(() {
      _messages.add(ChatMessage(
        source,
        msg,
        metadata: metadata,
        sourceName: sourceName,
        modelId: modelId,
        modelName: modelName,
      ));
    });
    scrollMessagesDown();
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
      initialAuthToken: _authToken,  // Add this
      initialInferenceUrl: _inferenceUrl,  // Add this
      accountDetail: _accountDetail,
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
        _connectWithAuthToken(token, url);
      },
    );
  }

  // item builder
  Widget _buildChatBubble(BuildContext context, int index) {
    return ChatBubble(message: _messages[index], debugMode: _debugMode);
  }

  void _send() {
    if (_canSendMessages()) {
      _sendPrompt();
    } else {
      _popAccountDialog();
    }
  }

  bool _canSendMessages() {
    return (_providerConnection?.inferenceClient != null) || 
           (_authToken != null && _inferenceUrl != null);
  }

  void _sendPrompt() async {
    var msg = _promptTextController.text;
    if (msg.trim().isEmpty) {
      return;
    }

    if (_providerConnection == null) {
      addMessage(ChatMessageSource.system, 'Not connected to provider');
      return;
    }

    if (_selectedModelIds.isEmpty) {
      addMessage(ChatMessageSource.system, 
        _multiSelectMode ? 'Please select at least one model' : 'Please select a model'
      );
      return;
    }

    // Add user message immediately to update UI and include in history
    addMessage(ChatMessageSource.client, msg);
    _promptTextController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    for (final modelId in _selectedModelIds) {
      try {
        final modelInfo = _modelsState.allModels
            .firstWhere((m) => m.id == modelId,
                orElse: () => ModelInfo(
                      id: modelId,
                      name: modelId,
                      provider: '',
                      apiType: '',
                    ));

        // Get messages relevant to this model
        final relevantMessages = _messages.where((m) => 
          (m.source == ChatMessageSource.provider && m.modelId == modelId) ||
          m.source == ChatMessageSource.client
        ).toList();

        Map<String, Object>? params;
        if (_maxTokens != null) {
          params = {'max_tokens': _maxTokens!};
        }

        addMessage(
          ChatMessageSource.internal,
          'Querying ${modelInfo.name}...',
          modelId: modelId,
          modelName: modelInfo.name,
        );

        await _providerConnection?.requestInference(
          modelId,
          relevantMessages,
          params: params,
        );
      } catch (e) {
        addMessage(ChatMessageSource.system, 'Error querying model $modelId: $e');
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
    _messages = [];
    setState(() {});
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
            itemCount: _messages.length,
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This is a demonstration of the application of Orchid Nanopayments within a consolidated Multi-LLM chat service.',
                        style: OrchidText.normal_14.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'To get started, enter or create a funded Orchid account.',
                        style: OrchidText.normal_14.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      ChatButton(
                        text: 'Enter Account', 
                        onPressed: _popAccountDialog, 
                        width: 200,
                      ).top(24),
                      SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _launchURL('https://account.orchid.com'),
                        child: Text('Create Account').button,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          minimumSize: Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      InkWell(
                        onTap: () => _launchURL('https://docs.orchid.com/en/latest/accounts/'),
                        child: Text(
                          'Learn more about creating an Orchid account',
                          style: TextStyle(color: Colors.blue[300], decoration: TextDecoration.underline),
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
    final buttonHeight = 40.0;
    final settingsIconSize = buttonHeight * 1.5;
    
    return Row(
      children: <Widget>[
        // Logo
        SizedBox(height: buttonHeight, child: OrchidAsset.image.logo),

        // Model selector with loading state
        ListenableBuilder(
          listenable: _modelsState,
          builder: (context, _) {
            if (_modelsState.isAnyLoading) {
              return SizedBox(
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
              onClearChat: _clearChat,
            ),
          ),
        ).left(8),
      ],
    );
  }
}

class CalloutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final radius = 10.0; // Corner radius
    final calloutWidth = 25.0;
    final calloutHeight = 20.0;
    final calloutStart = size.width - 115.0; // Adjust this to position the callout

    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(calloutStart, 0)
      ..lineTo(calloutStart + (calloutWidth / 2), -calloutHeight)
      ..lineTo(calloutStart + calloutWidth, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(size.width, size.height, size.width - radius, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Future<void> _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url)) {
    throw 'Could not launch $url';
  }
}

// Rename this in a subclass as prelude to refactoring later.
class TransientEthereumKey extends StoredEthereumKey {
  TransientEthereumKey({required super.imported, required super.private});
}

enum OrchataMenuItem { debug }
