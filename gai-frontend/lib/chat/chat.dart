import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/chat/chat_settings_button.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';
import 'chat_bubble.dart';
import 'chat_button.dart';
import 'chat_message.dart';
import '../provider.dart';

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
  final promptTextController = TextEditingController();
  final _bidController = NumericValueFieldController();
  bool _showPromptDetails = false;

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
      chainId: 100,
    );
  }

  // This should be wrapped up in a provider.  See WIP in vpn app.
  AccountDetailPoller? _accountDetail;
  final _accountDetailNotifier = ChangeNotifier();

  // This should be wrapped up in a provider.  See WIP in vpn app.
  void _accountChanged() async {
    log("selectedAccountChanged");
    _accountDetail?.cancel();
    _accountDetail = null;
    setState(() {});
    _accountDetailNotifier.notifyListeners();
    if (_account != null) {
      _accountDetail = AccountDetailPoller(account: _account!);
      await _accountDetail?.pollOnce();
      setState(() {});
      _accountDetailNotifier.notifyListeners();
    }
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
    // _selectedAccountChanged();
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

  void connectProvider() {
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
    _providerConnection = ProviderConnection(
      onMessage: (msg) {
        addMessage(ChatMessageSource.internal, msg);
      },
      onConnect: providerConnected,
      onChat: (msg, metadata) {
        addMessage(ChatMessageSource.provider, msg, metadata);
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
  }

  void addMessage(ChatMessageSource source, String msg, [metadata]) {
    if (metadata == null) {
      _messages.add(ChatMessage(source, msg));
    } else {
      _messages.add(ChatMessage(source, msg, metadata: metadata));
    }
    if (source != ChatMessageSource.internal || _debugMode == true) {
      setState(() {});
      scrollMessagesDown();
    }
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
        child: OrchidTitledPanel(
          highlight: false,
          opaque: true,
          titleText: "Set your Orchid account",
          onDismiss: () {
            Navigator.pop(context);
          },
          body: Column(
            children: [
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
              ),
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
                      // print('Error parsing BigInt: $e');
                      _signerKey = null;
                    }
                  });
                  _accountChanged();
                },
              ).top(16),
              // Account card
              ListenableBuilder(
                  listenable: _accountDetailNotifier,
                  builder: (context, child) {
                    return AccountCard(accountDetail: _accountDetail).top(20);
                  }),
            ],
          ).pad(24),
        ),
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

  void _sendPrompt(String msg, TextEditingController controller) {
    var message = '{"type": "job", "bid": $_bid, "prompt": "$msg"}';
    _providerConnection?.sendProviderMessage(message);
    controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    addMessage(ChatMessageSource.client, msg);
    addMessage(ChatMessageSource.internal, 'Client: $message');
    print('Sending message to provider $message');
  }

  void scrollMessagesDown() {
    messageListController.animateTo(
      messageListController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  List<PopupMenuEntry<OrchataMenuItem>> buildMenu(BuildContext context) {
    return <PopupMenuEntry<OrchataMenuItem>>[
      const PopupMenuItem<OrchataMenuItem>(
        value: OrchataMenuItem.debug,
        child: Text('Debug'),
      )
    ];
  }

  void clearChat() {
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
    var small = AppSize(context).narrowerThanWidth(500);
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
                    if (small)
                      FittedBox(
                          child: SizedBox(width: 500, child: _buildHeaderRow()))
                    else
                      _buildHeaderRow(),
                    // Messages area
                    Flexible(
                      child: ListView.builder(
                        controller: messageListController,
                        itemCount: _messages.length,
                        itemBuilder: _buildChatBubble,
                      ),
                    ),
                    // Prompt row
                    AnimatedSize(
                      alignment: Alignment.topCenter,
                      duration: millis(150),
                      child:
                          _buildPromptRow(promptTextController, _submit).top(8),
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

  Widget _buildPromptRow(
    TextEditingController promptTextController,
    VoidCallback onSubmit,
  ) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: OrchidColors.new_purple),
              onPressed: () {
                setState(() {
                  _showPromptDetails = !_showPromptDetails;
                });
              },
              icon: _showPromptDetails
                  ? const Icon(Icons.expand_more, color: Colors.white)
                  : const Icon(Icons.chevron_right, color: Colors.white),
            ),
            Flexible(
              child: OrchidTextField(
                controller: promptTextController,
                hintText: 'Enter a prompt',
                contentPadding: EdgeInsets.only(bottom: 26, left: 16),
                style: OrchidText.body1,
                autoFocus: true,
                onSubmitted: (String s) {
                  onSubmit();
                },
              ).left(16),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: OrchidColors.new_purple),
              onPressed: onSubmit,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ).left(16),
          ],
        ).padx(8),
        if (_showPromptDetails) _buildBidForm(_setBid, _bidController),
      ],
    );
  }

  // prelude to widget
  static Widget _buildBidForm(
      ValueChanged<double?> setBid,
      NumericValueFieldController bidController,
      ) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          Text('Your bid is the price per token in/out you will pay.',
                  style: OrchidText.medium_20_050)
              .top(8),
          OrchidLabeledNumericField(
            label: 'Bid',
            onChange: setBid,
            controller: bidController,
          ).top(12)
        ],
      ),
    );
  }

  void _submit() {
    _account != null
        ? _sendPrompt(promptTextController.text, promptTextController)
        : _popAccountDialog();
  }

  Widget _buildHeaderRow() {
    return Row(
      children: <Widget>[
        SizedBox(height: 40, child: OrchidAsset.image.logo),
        const Spacer(),
        // Connect button
        ChatButton(
            text: _connected ? 'Reroll' : 'Connect',
            onPressed: connectProvider,
            ).left(8),
        // Clear button
        ChatButton(text: 'Clear Chat', onPressed: clearChat).left(8),
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
