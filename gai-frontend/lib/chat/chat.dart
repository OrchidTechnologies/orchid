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

  @override
  void initState() {
    super.initState();
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
    _providerConnection = ProviderConnection(
      providers: _providers,
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
      funder: _funder,
      signerKey: _signerKey,
      contract:
          EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'),
    );
  }

  void providerConnected() {
    _connected = true;
    addMessage(ChatMessageSource.system, 'Connected to provider.');
  }

  void providerDisconnected() {
    _connected = false;
    addMessage(ChatMessageSource.system, 'Provider disconnected');
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

  void setBid(double? value) {
    _bid = value ?? _bid;
    setState(() {});
  }

  Widget _buildPromptDialog(
      BuildContext context, Animation<double> anim1, Animation<double> anim2) {
    var controller = NumericValueFieldController();
    controller.value = _bid;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF303030), Color(0xFF757575)],
          ),
        ),
        height: 130,
        child: Column(
          children: <Widget>[
            Text('Your bid is the price per token in/out you will pay.',
                style: OrchidText.medium_20_050),
            const SizedBox(height: 3),
            OrchidLabeledNumericField(
              label: 'Bid',
              onChange: setBid,
              controller: controller,
            )
          ],
        ),
      ),
    );
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
      // This stateful builder allows this dialog to rebuild in response to setstate
      // on the _accountToImport in the parent.
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
                    _buildPromptRow(context).top(8),
                    Text('Your bid is $_bid XDAI per token.',
                        style: OrchidText.normal_14),
                  ],
                ),
              ).top(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptRow(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton.filled(
          onPressed: () {
            showGeneralDialog<String>(
              context: context,
              transitionDuration: Duration(milliseconds: 300),
              pageBuilder: _buildPromptDialog,
              barrierDismissible: true,
              barrierLabel: 'Prompt Settings',
              transitionBuilder: (context, anim1, anim2, child) {
                return SlideTransition(
                  position: Tween(begin: Offset(0, 0.8), end: Offset(0, 0.3))
                      .animate(anim1),
                  child: child,
                );
              },
            );
          },
          icon: const Icon(Icons.more_horiz),
        ),
        Flexible(
          child: OrchidTextField(
            controller: promptTextController,
            hintText: 'Enter a prompt',
            contentPadding: EdgeInsets.only(bottom: 26, left: 16),
            style: OrchidText.body1,
            autoFocus: true,
          ).left(16),
        ),
        IconButton.filled(
          onPressed: () {
            _account != null
                ? _sendPrompt(promptTextController.text, promptTextController)
                : _popAccountDialog();
          },
          icon: const Icon(Icons.send_rounded),
        ).left(16),
      ],
    ).padx(8);
  }

  Widget _buildHeaderRow() {
    return Row(
      children: <Widget>[
        SizedBox(height: 40, child: OrchidAsset.image.logo),
        const Spacer(),
        // Connect button
        ChatButton(
            text: _connected ? 'Reroll' : 'Connect',
            onPressed: () {
              _providerConnection?.connectProvider();
            }).left(8),
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
