import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/app_colors.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/gai_settings_button.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';
import 'provider.dart';

enum OrchataMenuItem { debug }

enum ChatMessageSource { client, provider, system, internal }

class ChatMessage {
  ChatMessageSource source;
  String msg;
  final Map<String, dynamic>? _metadata;

  ChatMessage(this.source, this.msg, {metadata}) : _metadata = metadata;

  String get message {
    return msg;
  }

  Map<String, dynamic> get metadata {
    return _metadata ?? {};
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<ChatMessage> messages = [];
  List<String> _providers = [];
  bool _debugMode = false;
  var _connected = false;
  var _bid = 0.00007;
  ProviderConnection? _providerConnection;

  // The active account components
  EthereumAddress? _funder;
  BigInt? _signerKey;

  final _signerFieldController = TextEditingController();
  final _funderFieldController = AddressValueFieldController();

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

  @override
  void initState() {
    super.initState();
    try {
      _initFromParams();
    } catch (e, stack) {
      log('Error initializing from params: $e, $stack');
    }
    initStateAsync();
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

  void initStateAsync() async {
    // Demo using account
    final account = _account;
    if (account != null) {
      final pot = await account.getLotteryPot();
      log('Lottery pot: $pot');
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

  void addMessage(ChatMessageSource source, String msg, [metadata]) {
    if (metadata == null) {
      messages.add(ChatMessage(source, msg));
    } else {
      messages.add(ChatMessage(source, msg, metadata: metadata));
    }
    if (source != ChatMessageSource.internal || _debugMode == true) {
      setState(() {});
      scrollMessagesDown();
    }
  }

  void setBid(double? value) {
    var _value = value ?? _bid;
    _bid = _value;
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

  Widget _buildAccountDialog(BuildContext context) {
    if (_funder != null) {
      _funderFieldController.value = _funder;
    }

    return SizedBox(
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
              OrchidLabeledAddressField(
                label: 'Funder Address',
                onChange: (EthereumAddress? s) {
                  _funder = s;
                },
                controller: _funderFieldController,
              ),
              OrchidLabeledTextField(
                label: 'Signer Key',
                controller: _signerFieldController,
                hintText: '0x...',
                onChanged: (String s) {
                  try {
                    _signerKey = BigInt.parse(s);
                  } catch (e) {
                    // print('Error parsing BigInt: $e');
                    _signerKey = null;
                  }
                },
              ).top(16),
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

  bool accountSet() {
    if (_funder == null || _signerKey == null) {
      return false;
    }
    return true;
  }

  List<Color> msgBubbleColor(ChatMessageSource src) {
    if (src == ChatMessageSource.client) {
      return <Color>[
        const Color(0xff52319c),
        const Color(0xff3b146a),
      ];
    } else {
      return <Color>[
        AppColors.teal_2,
        AppColors.neutral_1,
      ];
    }
  }

  Widget buildChatBubble(context, index) {
    ChatMessageSource src = messages[index].source;

    if (src == ChatMessageSource.system || src == ChatMessageSource.internal) {
      if (!_debugMode && src == ChatMessageSource.internal) {
        return Container();
      }

      return Center(
        child: Column(
          children: <Widget>[
            Text(
              messages[index].message,
              style: src == ChatMessageSource.system
                  ? OrchidText.normal_14
                  : OrchidText.normal_14.grey,
            ),
            const SizedBox(height: 2),
          ],
        ),
      );
    }
    return Align(
      alignment: src == ChatMessageSource.provider
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: SizedBox(
        width: 0.6 * 800, //MediaQuery.of(context).size.width * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(src == ChatMessageSource.provider ? 'Chat' : 'You',
                  style: OrchidText.normal_14),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      width: 0.6 * 800,
                      // MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: msgBubbleColor(messages[index].source),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.6 * 800,
                    // MediaQuery.of(context).size.width * 0.6,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(messages[index].message,
                        style: OrchidText.medium_20_050),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (src == ChatMessageSource.provider) ...[
              Text(
                style: OrchidText.normal_14,
                'model: ${messages[index].metadata["model"]}   usage: ${messages[index].metadata["usage"]}',
              )
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void sendPrompt(String msg, TextEditingController controller) {
    var message = '{"type": "job", "bid": $_bid, "prompt": "$msg"}';
    _providerConnection?.sendProviderMessage(message);
    controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    addMessage(ChatMessageSource.client, msg);
    addMessage(ChatMessageSource.internal, 'Client: $message');
    print('Sending message to provider $message');
  }

  final ScrollController messageListController = ScrollController();

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
    messages = [];
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  var promptTextController = TextEditingController();

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
                    Flexible(
                      child: ListView.builder(
                        controller: messageListController,
                        itemCount: messages.length,
                        itemBuilder: buildChatBubble,
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
            accountSet()
                ? sendPrompt(promptTextController.text, promptTextController)
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
        GAIButton(
            text: _connected ? 'Reroll' : 'Connect',
            onPressed: () {
              _providerConnection?.connectProvider();
            }).left(8),
        // Clear button
        GAIButton(text: 'Clear Chat', onPressed: clearChat).left(8),
        // Account button
        GAIButton(text: 'Account', onPressed: _popAccountDialog).left(8),
        // Settings button
        GAISettingsButton(
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

class GAIButton extends StatelessWidget {
  const GAIButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        style: TextButton.styleFrom(
          backgroundColor: OrchidColors.new_purple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(text).button.white,
      ),
    );
  }
}

// Rename this in a subclass as prelude to refactoring later.
class TransientEthereumKey extends StoredEthereumKey {
  TransientEthereumKey({required super.imported, required super.private});
}
