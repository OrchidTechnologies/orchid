import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orchid/gui-orchid/lib/orchid/menu/orchid_chain_selector_menu.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'chat_button.dart';

typedef AccountChangedCallback = void Function(
    Chain chain, EthereumAddress? funder, BigInt? signerKey);
typedef AuthTokenChangedCallback = void Function(
    String token, String inferenceUrl);

class AuthDialog extends StatefulWidget {
  final Chain initialChain;
  final EthereumAddress? initialFunder;
  final BigInt? initialSignerKey;
  final String? initialAuthToken;
  final String? initialInferenceUrl;
  final ValueNotifier<AccountDetail?> accountDetailNotifier;
  final AccountChangedCallback onAccountChanged;
  final AuthTokenChangedCallback onAuthTokenChanged;

  const AuthDialog({
    super.key,
    required this.initialChain,
    this.initialFunder,
    this.initialSignerKey,
    this.initialAuthToken,
    this.initialInferenceUrl,
    required this.accountDetailNotifier,
    required this.onAccountChanged,
    required this.onAuthTokenChanged,
  });

  static void show(
    BuildContext context, {
    required Chain initialChain,
    EthereumAddress? initialFunder,
    BigInt? initialSignerKey,
    String? initialAuthToken,
    String? initialInferenceUrl,
    required ValueNotifier<AccountDetail?> accountDetailNotifier,
    required AccountChangedCallback onAccountChanged,
    required AuthTokenChangedCallback onAuthTokenChanged,
  }) {
    AppDialogs.showAppDialog(
      context: context,
      showActions: false,
      contentPadding: EdgeInsets.zero,
      body: AuthDialog(
        initialChain: initialChain,
        initialFunder: initialFunder,
        initialSignerKey: initialSignerKey,
        initialAuthToken: initialAuthToken,
        initialInferenceUrl: initialInferenceUrl,
        accountDetailNotifier: accountDetailNotifier,
        onAccountChanged: onAccountChanged,
        onAuthTokenChanged: onAuthTokenChanged,
      ),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late Chain _selectedChain;
  EthereumAddress? _funder;
  BigInt? _signerKey;
  String? _authToken;
  String? _inferenceUrl;

  final _funderFieldController = AddressValueFieldController();
  final _signerFieldController = TextEditingController();
  final _authTokenController = TextEditingController();
  final _inferenceUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedChain = widget.initialChain;
    _funder = widget.initialFunder;
    _signerKey = widget.initialSignerKey;
    _authToken = widget.initialAuthToken;
    _inferenceUrl = widget.initialInferenceUrl;
    if (_funder != null) {
      _funderFieldController.text = _funder.toString();
    }
    if (_signerKey != null) {
      _signerFieldController.text = _signerKey.toString();
    }
    if (_authToken != null) {
      _authTokenController.text = _authToken!;
    }
    if (_inferenceUrl != null) {
      _inferenceUrlController.text = _inferenceUrl!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(widget.accountDetailNotifier?.hashCode ?? 'key'),
      width: 500,
      child: IntrinsicHeight(
        child: ValueListenableBuilder(
            valueListenable: widget.accountDetailNotifier,
            builder: (BuildContext context, AccountDetail? accountDetail,
                Widget? child) {
              return OrchidTitledPanel(
                highlight: false,
                opaque: true,
                titleText: "Connect to Provider",
                onDismiss: () {
                  Navigator.pop(context);
                },
                body: DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Orchid Account'),
                          Tab(text: 'Auth Token'),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                      ),
                      SizedBox(
                        height: 500,
                        child: TabBarView(
                          children: [
                            _buildOrchidAccountTab(accountDetail),
                            _buildAuthTokenTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _buildOrchidAccountTab(AccountDetail? accountDetail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    widget.onAccountChanged(
                        _selectedChain, _funder, _signerKey);
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
              widget.onAccountChanged(_selectedChain, _funder, _signerKey);
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
              widget.onAccountChanged(_selectedChain, _funder, _signerKey);
            },
            onClear: () {
              setState(() {
                _signerKey = null;
              });
              widget.onAccountChanged(_selectedChain, _funder, _signerKey);
            },
          ).top(16),

          // Account card
          AccountCard(accountDetail: accountDetail).top(20),

          ChatButton(
            onPressed: () => _launchURL('https://account.orchid.com'),
            text: 'Manage Account',
            width: 200,
          ).top(20),

          Text(
            'Connect with your Orchid account to pay for usage with nanopayments',
            style: OrchidText.body2.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ).top(16),
        ],
      ).pad(24),
    );
  }

  Widget _buildAuthTokenTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrchidLabeledTextField(
            label: 'Auth Token',
            controller: _authTokenController,
            hintText: 'Enter your auth token',
            onChanged: (String s) {
              setState(() {
                _authToken = s.trim();
              });
            },
          ),
          OrchidLabeledTextField(
            label: 'Inference URL',
            controller: _inferenceUrlController,
            hintText: 'Enter the inference API URL',
            onChanged: (String s) {
              setState(() {
                _inferenceUrl = s.trim();
              });
            },
          ).top(16),
          ChatButton(
            onPressed: (_authToken?.isNotEmpty == true &&
                    _inferenceUrl?.isNotEmpty == true)
                ? () {
                    widget.onAuthTokenChanged(_authToken!, _inferenceUrl!);
                    Navigator.pop(context);
                  }
                : () {},
            text: 'Connect',
            width: double.infinity,
          ).top(24),
          Text(
            'Connect directly with an auth token from a running wallet',
            style: OrchidText.body2.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ).top(16),
        ],
      ).pad(24),
    );
  }
}

Future<void> _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url)) {
    throw 'Could not launch $url';
  }
}
