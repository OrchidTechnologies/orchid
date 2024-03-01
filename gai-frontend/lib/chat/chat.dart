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
import 'chat_bubble.dart';
import 'chat_button.dart';
import 'chat_message.dart';
import '../provider.dart';
import 'chat_prompt.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<ChatMessage> _messages = [];
  List<String> _providers = [];
  int _providerIndex = 0;
  bool _debugMode = false;
  bool _connected = false;
  double _bid = 0.00007;
  ProviderConnection? _providerConnection;

  // The active account components
  EthereumAddress? _funder;
  BigInt? _signerKey;

  final _signerFieldController = TextEditingController();
  final _funderFieldController = AddressValueFieldController();
  final ScrollController messageListController = ScrollController();
  final _promptTextController = TextEditingController();
  final _bidController = NumericValueFieldController();
  bool _showPromptDetails = false;
  Chain _selectedChain = Chains.Gnosis;

  @override
  void initState() {
    super.initState();
    _bidController.value = _bid;
    try {
      _initFromParams();
    } catch (e, stack) {
      log('Error initializing from params: $e, $stack');
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
      _accountDetail?.pollOnce();
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
      _providers = [provider];
    }
  }

  void providerConnected() {
    _connected = true;
    addMessage(ChatMessageSource.system, 'Connected to provider.');
  }

  void providerDisconnected() {
    _connected = false;
    addMessage(ChatMessageSource.system, 'Provider disconnected');
  }

  void _connectProvider() {
    var account = _accountDetail;
    if (account == null) {
      return;
    }
    if (_providers.length == 0) {
      return;
    }
    if (_connected) {
      _providerConnection?.dispose();
      _providerIndex = (_providerIndex + 1) % _providers.length;
      _connected = false;
    }
    log('Connecting to provider: ${_providers[_providerIndex]}');
    _providerConnection = ProviderConnection(
      onMessage: (msg) {
        addMessage(ChatMessageSource.internal, msg);
      },
      onConnect: providerConnected,
      onChat: (msg, metadata) {
        addMessage(ChatMessageSource.provider, msg, metadata: metadata);
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
      accountDetail: account,
      contract:
          EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'),
      url: _providers[_providerIndex],
    );
    log('connected...');
  }

  void addMessage(ChatMessageSource source, String msg,
      {Map<String, dynamic>? metadata}) {
    log('Adding message: ${msg.truncate(64)}');
    setState(() {
      _messages.add(ChatMessage(source, msg, metadata: metadata));
    });
    // if (source != ChatMessageSource.internal || _debugMode == true) {
    scrollMessagesDown();
    // }
  }

  void _setBid(double? value) {
    setState(() {
      _bid = value ?? _bid;
    });
  }

  // TODO: Break out widget
  Widget _buildAccountDialog(BuildContext context) {
    if (_funder != null) {
      _funderFieldController.value = _funder;
    }
    return SizedBox(
      key: ValueKey(_account?.hashCode ?? 'key'),
      // Width here is effectively a max width and prevents dialog resizing
      width: 500,
      child: IntrinsicHeight(
        child: ListenableBuilder(
            listenable: _accountDetailNotifier,
            builder: (context, child) {
              return OrchidTitledPanel(
                highlight: false,
                opaque: true,
                titleText: "Set your Orchid account",
                onDismiss: () {
                  Navigator.pop(context);
                },
                body: Column(
                  children: [
                    // Chain selector
                    Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 190,
                          child: OrchidChainSelectorMenu(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            selected: _selectedChain,
                            onSelection: (chain) {
                              setState(() {
                                _selectedChain = chain;
                              });
                              _accountChanged();
                            },
                            enabled: true,
                          ),
                        ),
                      ],
                    ),

                    // Funder field
                    OrchidLabeledAddressField(
                      label: 'Funder Address',
                      onChange: (EthereumAddress? s) {
                        setState(() {
                          _funder = s;
                        });
                        _accountChanged();
                      },
                      controller: _funderFieldController,
                    ).top(16),
                    // Signer field
                    OrchidLabeledTextField(
                      label: 'Signer Key',
                      controller: _signerFieldController,
                      hintText: '0x...',
                      onChanged: (String s) {
                        setState(() {
                          try {
                            _signerKey = BigInt.parse(s);
                          } catch (e) {
                            _signerKey = null;
                          }
                        });
                        _accountChanged();
                      },
                    ).top(16),
                    // Account card
                    AccountCard(accountDetail: _accountDetail).top(20),
                  ],
                ).pad(24),
              );
            }),
      ),
    );
  }

  void _popAccountDialog() {
    AppDialogs.showAppDialog(
      context: context,
      showActions: false,
      contentPadding: EdgeInsets.zero,
      body: _buildAccountDialog(context),
    );
  }

  // item builder
  Widget _buildChatBubble(BuildContext context, int index) {
    return ChatBubble(message: _messages[index], debugMode: _debugMode);
  }

  void _send() {
    _account != null ? _sendPrompt() : _popAccountDialog();
  }

  void _sendPrompt() {
    var msg = _promptTextController.text;
    if (msg.trim().isEmpty) {
      return;
    }
    var message = '{"type": "job", "bid": $_bid, "prompt": "$msg"}';
    _providerConnection?.sendProviderMessage(message);
    _promptTextController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    addMessage(ChatMessageSource.client, msg);
    addMessage(ChatMessageSource.internal, 'Client: $message');
    log('Sending message to provider $message');
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
                    Flexible(
                      child: ListView.builder(
                        controller: messageListController,
                        itemCount: _messages.length,
                        itemBuilder: _buildChatBubble,
                      ).top(16),
                    ),
                    // Prompt row
                    AnimatedSize(
                      alignment: Alignment.topCenter,
                      duration: millis(150),
                      child: ChatPromptPanel(
                              promptTextController: _promptTextController,
                              onSubmit: _send,
                              setBid: _setBid,
                              bidController: _bidController)
                          .top(8),
                    ),
                    if (!_showPromptDetails)
                      Text('Your bid is $_bid XDAI per token.',
                              style: OrchidText.normal_14)
                          .top(12),
                  ],
                ),
              ).top(8).bottom(8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow({required bool showIcons}) {
    return Row(
      children: <Widget>[
        SizedBox(height: 40, child: OrchidAsset.image.logo),
        const Spacer(),
        // Connect button
        ChatButton(
          text: _connected ? 'Reroll' : 'Connect',
          onPressed: _connectProvider,
        ).left(8),
        // Clear button
        ChatButton(text: 'Clear Chat', onPressed: _clearChat).left(8),
        // Account button
        ChatButton(text: 'Account', onPressed: _popAccountDialog).left(8),
        // Settings button
        ChatSettingsButton(
          debugMode: _debugMode,
          onDebugModeChanged: () {
            setState(() {
              _debugMode = !_debugMode;
            });
          },
        ).left(8),
      ],
    );
  }
}

// Rename this in a subclass as prelude to refactoring later.
class TransientEthereumKey extends StoredEthereumKey {
  TransientEthereumKey({required super.imported, required super.private});
}

enum OrchataMenuItem { debug }
