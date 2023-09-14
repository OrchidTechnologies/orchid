import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/purchase/orchid_pac_seller.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/vpn/purchase/orchid_pac.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/vpn/purchase/orchid_purchase.dart';
import 'package:orchid/orchid/account/account_selector.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_identity_field.dart';
import 'package:orchid/orchid/menu/orchid_chain_selector_menu.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_checkbox.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_titled_panel.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'package:orchid/util/format_currency.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:styled_text/styled_text.dart';
import '../app_routes.dart';

class WelcomePanel extends StatefulWidget {
  final VoidCallback? onDismiss;
  final void Function(Account account) onAccount;
  final StoredEthereumKey? defaultIdentity;

  const WelcomePanel({
    Key? key,
    required this.onDismiss,
    required this.onAccount,
    this.defaultIdentity,
  }) : super(key: key);

  @override
  State<WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel> {
  _State? _state;
  PAC? _dollarPAC;
  StoredEthereumKey? _generatedIdentity;
  StoredEthereumKey? _importedIdentity;

  // This could be either the imported or generated identity, depending on whether
  // the user hits the "back" button.
  StoredEthereumKey? _selectedIdentity;

  EthereumAddress? _funderAddress;
  Chain? _chain;

  @override
  void initState() {
    super.initState();
    // If a default key was passed use it and skip the key choice.
    _selectedIdentity = widget.defaultIdentity;
    initStateAsync();
  }

  void initStateAsync() async {
    UserPreferencesVPN().pacTransaction.stream().listen((tx) {
      if (tx == null) {
        // If we already have an identity supplied skip the choice.
        if (_selectedIdentity != null) {
          _state = _State.setup_account;
        } else {
          _state = _State.welcome;
        }
      } else {
        switch (tx.state) {
          case PacTransactionState.None:
          case PacTransactionState.Pending:
          case PacTransactionState.Ready:
          case PacTransactionState.InProgress:
          case PacTransactionState.WaitingForRetry:
            _state = _State.processing_pac;
            break;
          case PacTransactionState.WaitingForUserAction:
          case PacTransactionState.Error:
            _state = _State.processing_timeout;
            break;
          case PacTransactionState.Complete:
            _state = _State.processing_chain;
            break;
        }
      }

      if (mounted) {
        setState(() {});
      }
    });

    _dollarPAC = await OrchidPurchaseAPI.getDollarPAC();
    if (_dollarPAC == null) {
      log("(first launch) welcome pane: Can't find dollar pac product.");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      log("(first launch) welcome pane: not ready: $_state");
      return Container();
    }
    return SizedBox(
      width: double.infinity,
      child:
          OrchidTitledPanel.title(title: _buildTitle(), body: _buildContent()),
    ).padx(28);
  }

  Widget _buildTitle() {
    final titleContent = _getTitleContent();
    return OrchidTitledPanelTitle(
        titleText: titleContent.text,
        onDismiss: titleContent.showDismiss
            ? () {
                setState(() {
                  _dismiss();
                });
              }
            : null,
        onBack: titleContent.backState != null
            ? () {
                setState(() {
                  _state = titleContent.backState;
                });
              }
            : null);
  }

  // merge this with _buildContent
  _TitleContent _getTitleContent() {
    switch (_state) {
      // null should not be possible here due to page logic.
      case null:
      case _State.welcome:
        return _TitleContent(text: s.welcomeToOrchid);
      case _State.setup_choice:
        return _TitleContent(
            text: s.orchidIdentity,
            backState: _State.welcome,
            showDismiss: true);
      case _State.backup_identity:
        return _TitleContent(
          text: s.backUpYourIdentity,
          backState: _State.setup_choice,
          showDismiss: true,
        );

      case _State.setup_account:
        return _TitleContent(
          text: s.linkAnOrchidAccount,
          backState: _selectedIdentity == _generatedIdentity
              ? _State.backup_identity
              : _State.setup_choice,
          showDismiss: true,
        );

      case _State.confirm_purchase:
        return _TitleContent(
            text: s.fundYourAccount, backState: _State.welcome);

      case _State.confirm_purchase_wait:
        return _TitleContent(text: s.fundYourAccount);

      case _State.processing_pac:
      case _State.processing_timeout:
        return _TitleContent(text: s.processing, showDismiss: true);

      case _State.processing_chain:
        return _TitleContent(text: s.purchaseComplete, showDismiss: false);
    }
  }

  Widget _buildContent() {
    switch (_state) {
      // Null case guarded by page logic, should not be reached.
      case null:
      case _State.welcome:
        return _buildContentWelcomeState();
      case _State.setup_choice:
        return _buildContentSetupChoiceState();
      case _State.setup_account:
        return _buildContentSetupAccountState();
      case _State.backup_identity:
        return _buildContentBackupIdentityState();

      case _State.confirm_purchase:
      case _State.confirm_purchase_wait:
        return _buildContentConfirmPurchaseState();
      case _State.processing_pac:
      case _State.processing_chain:
      case _State.processing_timeout:
        return _buildContentProcessingPurchaseState();
    }
  }

  Widget _buildContentWelcomeState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService)
            .body2
            .center
            .padx(24)
            .top(32),
        pady(40),
        OrchidActionButton(
          height: 50,
          enabled: true,
          text: s.importAccount.toUpperCase(),
          onPressed: () {
            setState(() {
              _state = _State.setup_choice;
            });
          },
        ),
        pady(16),
        Visibility(
          visible: _dollarPAC != null,
          child: OrchidOutlineButton(
            text: s.buyCredits.toUpperCase(),
            onPressed: () {
              setState(() {
                _state = _State.confirm_purchase;
              });
            },
          ),
        ),
        pady(24),
        if (widget.onDismiss != null)
          Text(s.illDoThisLater).linkButton(onTapped: _dismiss),
        pady(40),
      ],
    );
  }

  final Map<String, StyledTextTagBase> tags = {
    'account_link':
        OrchidText.body2.tappable.link(OrchidUrls.partsOfOrchidAccount),
  };

  Widget _buildContentSetupChoiceState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.generateNewIdentity + ':').body2.top(32).padx(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                child: OrchidActionButton(
                  height: 50,
                  text: s.generateIdentity,
                  onPressed: () async {
                    await _generateIdentityIfNeeded();
                    setState(() {
                      _state = _State.backup_identity;
                    });
                  },
                  enabled: true,
                ),
              ).top(24).padx(24),
            ),
          ],
        ),
        Divider(color: Colors.black).top(24),
        StyledText(
          style: OrchidText.body2,
          text: s.enterAnExistingOrchidIdentity + ':',
          tags: tags,
        ).top(24).padx(24),
        OrchidLabeledImportIdentityField(
          label: s.orchidIdentity,
          onChange: (ParseOrchidIdentityOrAccountResult? result) async {
            if (result != null) {
              if (result.hasMultipleAccounts) {
                await _importMultipleAccounts(result.accounts ?? []);
              } else {
                await _importSingleAccount(result);
              }
            }
          },
        ).top(16).padx(24).bottom(40),
      ],
    );
  }

  Future<void> _importSingleAccount(
      ParseOrchidIdentityOrAccountResult result) async {
    await result.saveIfNeeded();

    if (result.account != null) {
      // Populate the form even though it is not currently shown.
      _funderAddress = result.account!.funder;
      _chain = Chains.chainFor(result.account!.chainId);
      // We don't have a version selector in account import yet
      // _version = result.account.version;
      widget.onAccount(result.account!);
    }
    setState(() {
      _importedIdentity = result.signer;
      _selectedIdentity = _importedIdentity;
      _state = _State.setup_account;
    });
  }

  Future<void> _importMultipleAccounts(List<Account> accounts) async {
    await AccountSelectorDialog.show(
      context: context,
      accounts: accounts,
      onSelectedAccounts: (accounts) async {
        await ParseOrchidIdentityOrAccountResult.saveAccountsIfNeeded(accounts);
        // TODO
        widget.onAccount(accounts.first);
      },
    );
  }

  Widget _buildContentSetupAccountState() {
    if (_selectedIdentity == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.yourOrchidIdentityPublicAddress + ':').body2.height(2.0).top(16),
        _buildAddress(address: _selectedIdentity!.address).top(16),
        _buildCopyIdentityButton(
                value: _selectedIdentity!.address
                    .toString(prefix: true, elide: false))
            .center
            .top(16),
        Text(s.enterYourWeb3).body2.top(32),
        OrchidLabeledAddressField(
          label: s.funderWalletAddress,
          onChange: (value) {
            setState(() {
              _funderAddress = value;
            });
          },
        ).top(16),
        Text(s.chain).body1.top(32),
        OrchidChainSelectorMenu(
          key: Key(_funderAddress?.toString() ?? 'null'),
          // enabled: _funderAddress != null,
          enabled: true,
          selected: _chain,
          onSelection: (chain) {
            setState(() {
              _chain = chain;
            });
          },
        ).top(12),
        OrchidOutlineButton(
          text: s.importAccount.toUpperCase(),
          onPressed: _formValid()
              ? () async {
                  await _importAccount();
                  _dismiss();
                }
              : null,
        ).top(32).bottom(40),
      ],
    ).padx(24);
  }

  bool _formValid() {
    return _selectedIdentity != null &&
        _funderAddress != null &&
        _chain != null;
  }

  bool _backupComplete = false;

  // If the user generated an identity suggest backing it up
  Widget _buildContentBackupIdentityState() {
    if (_generatedIdentity == null) {
      return Container();
    }

    var config = _generatedIdentity!.toExportString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundedRect(
          borderColor: OrchidColors.tappable,
          borderWidth: 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: QrImage(
                  data: config,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                  size: 108.0,
                ),
              ),
              Flexible(
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.start,
                  // mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      height: 70,
                      child: Text(
                        config,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 0.02,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    _buildCopyIdentityButton(label: s.copy, value: config)
                        .top(12),
                  ],
                ).left(12),
              )
            ],
          ).pad(12),
        ).top(24),
        StyledText(
          style: OrchidText.body2,
          text: s.backUpYourOrchidIdentityPrivateKeyYouWill,
          tags: {
            'bold': StyledTextTag(style: OrchidText.body2.bold),
          },
        ).top(24),
        Row(
          children: [
            OrchidCheckbox(
              value: _backupComplete,
              onChanged: (value) {
                setState(() {
                  _backupComplete = value ?? false;
                });
              },
            ).bottom(8),
            Flexible(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _backupComplete = true;
                  });
                },
                child: Text(
                  s.yesIHaveSavedACopyOf,
                ).body2.boxHeight(36).left(8).top(8),
              ),
            ),
          ],
        ).top(24),
        OrchidActionButton(
          height: 50,
          text: s.continueButton,
          enabled: _backupComplete,
          onPressed: () {
            setState(() {
              _state = _State.setup_account;
              _selectedIdentity = _generatedIdentity;
            });
          },
        ).center.top(22),
        pady(40),
      ],
    ).padx(24);
  }

  Row _buildAddress({required EthereumAddress address, bool elide = false}) {
    return Row(
      children: [
        OrchidCircularIdenticon(size: 22, address: address),
        Flexible(
          child: SelectableText(
            address.toString(elide: elide),
            style: OrchidText.extra_large,
          ).top(4).left(16),
        ),
      ],
    );
  }

  TextButton _buildCopyIdentityButton({required String value, String? label}) {
    return TextButton(
      child: Row(
        children: [
          Icon(Icons.copy, color: OrchidColors.tappable, size: 20),
          Text(label ?? s.copyIdentity).body2.tappable.left(14).top(2),
          SizedBox(width: 20),
        ],
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
      },
    );
  }

  Widget _buildContentConfirmPurchaseState() {
    return Column(
      children: [
        StyledText(
          textAlign: TextAlign.center,
          style: OrchidText.body2,
          text: s
              .connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By,
          tags: {
            'link1': OrchidText.linkStyle.link(OrchidUrls.preferredProviders),
          },
        )
            .padx(24)
            .top(32)
            // Note: styled text breaks animated size layout so we provide a height
            .height(100),

        _buildConfirmPurchaseDetails(pac: _dollarPAC).top(40),
        OrchidActionButton(
          enabled: _state == _State.confirm_purchase,
          text: s.confirmPurchase,
          onPressed: _generateIdentityAndDoPurchase,
        ).top(40),
        if (widget.onDismiss != null)
          Text(s.illDoThisLater).linkButton(onTapped: _dismiss).top(24),
        StyledText(
          textAlign: TextAlign.center,
          style: OrchidText.caption.copyWith(fontSize: 12),
          text: s
              .orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink,
          tags: {
            'link': OrchidText.linkStyle.size(12).link(OrchidUrls.xdaiChain),
          },
        )
            .padx(24)
            .top(40)
            // Note: styled text breaks animated size layout so we provide a height
            .height(80),
        pady(40),
      ],
    );
  }

  Widget _buildContentProcessingPurchaseState() {
    String text;
    switch (_state) {
      // Null case guarded by page logic, should not be reached.
      case null:
      case _State.processing_pac:
        text = s.yourPurchaseIsInProgress;
        break;
      case _State.processing_chain:
        text = s.yourPurchaseIsComplete;
        break;
      case _State.processing_timeout:
        text = s.thisPurchaseIsTakingLongerThanExpectedToProcessAnd;
        break;
      case _State.welcome:
      case _State.confirm_purchase:
      case _State.confirm_purchase_wait:
        text = '...';
        break;
      case _State.setup_choice:
      case _State.backup_identity:
      case _State.setup_account:
        throw Exception();
    }

    bool timeout = false;
    bool complete = false;
    switch (_state) {
      case _State.processing_pac:
        timeout = false;
        break;
      case _State.processing_chain:
        timeout = false;
        complete = true;
        break;
      case _State.processing_timeout:
      case _State.welcome:
      case _State.confirm_purchase:
      case _State.confirm_purchase_wait:
        timeout = true;
        break;
      case null:
      case _State.setup_choice:
      case _State.backup_identity:
      case _State.setup_account:
        throw Exception();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pady(24),

        // icon
        if (complete)
          Icon(Icons.check, color: OrchidColors.green, size: 40)
        else if (timeout)
          Icon(Icons.error, color: Color(0xFFF88B9F), size: 40)
        else
          OrchidCircularProgressIndicator.smallIndeterminate(
              size: 30, stroke: 4),

        // wait message
        if (!timeout && !complete) ...[
          pady(24),
          Text(s.thisMayTakeAMinute).subtitle,
        ],

        pady(24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: StyledText(
            textAlign: TextAlign.center,
            style: OrchidText.caption.copyWith(fontSize: 12),
            text: text,
            tags: {
              'link': OrchidText.linkStyle.size(12).link(OrchidUrls.xdaiChain),
            },
          ),
        ),
        pady(24),

        if (complete) ...[
          // User hits continue, returning the new PAC account.
          TextButton(
            onPressed: () async {
              _dismiss();
              final funderAddress = OrchidPacSeller.sellerContractAddress;
              final account = Account.fromSignerKeyRef(
                  // generated identity should exist by virtue of page logic
                  signerKey: _generatedIdentity!.ref(),
                  funder: funderAddress,
                  chainId: Chains.GNOSIS_CHAINID,
                  version: 1);
              await UserPreferencesVPN().addCachedDiscoveredAccounts([account]);
              widget.onAccount(account);
            },
            child: Text(
              s.continueButton,
              style: OrchidText.button.tappable,
            ),
          ),
          pady(32),
        ] else if (timeout) ...[
          TextButton(
            onPressed: () {
              AppRoutes.pushAccountManager(context);
            },
            child: Text(
              s.manageAccounts.toUpperCase(),
              style: OrchidText.button.tappable,
            ),
          ),
          pady(32),
        ],
      ],
    );
  }

  Widget _buildConfirmPurchaseDetails({required PAC? pac}) {
    if (pac == null) {
      log("welcome panel: pac null");
      return Text("...");
    }
    var credits = pac.localPrice;
    var fee = pac.localPrice * 0.3;
    var promo = fee;
    var total = credits;

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.vpnCredits).body2,
              Text(formatCurrency(credits, locale: context.locale)).body2,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.blockchainFee).body2,
              Text('+ ' + formatCurrency(fee, locale: context.locale)).body2,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.promotion, style: OrchidText.body2.blueHightlight),
              Text('- ' + formatCurrency(promo, locale: context.locale),
                  style: OrchidText.body2.blueHightlight),
            ],
          ),
          pady(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.total.toUpperCase()).subtitle,
              Text(formatCurrency(total, locale: context.locale)).subtitle,
            ],
          )
        ],
      ),
    );
  }

  Future<void> _generateIdentityIfNeeded() async {
    if (_generatedIdentity == null) {
      log("welcome panel: generating identity");
      final key = StoredEthereumKey.generate();
      await UserPreferencesKeys().addKey(key);
      setState(() {
        _generatedIdentity = key;
      });
    }
  }

  void _generateIdentityAndDoPurchase() async {
    await _generateIdentityIfNeeded();
    return _doPurchase();
  }

  void _doPurchase() async {
    if (_dollarPAC == null || _generatedIdentity == null) {
      log("no purchase");
      return;
    }
    // disable the purchase button, etc.
    setState(() {
      _state = _State.confirm_purchase_wait;
    });
    await PurchaseUtils.purchase(
      purchase: _dollarPAC!,
      signerKey: _generatedIdentity!,
      onError: ({required rateLimitExceeded}) async {
        setState(() {
          // This should really be an additional error state
          _state = _State.processing_timeout;
        });
      },
    );
  }

  void _dismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  Future<void> _importAccount() async {
    if (_selectedIdentity == null || _funderAddress == null || _chain == null) {
      return;
    }
    final account = Account.fromSignerKeyRef(
      signerKey: _selectedIdentity!.ref(),
      funder: _funderAddress!,
      chainId: _chain!.chainId,
      version: 1,
    );
    await UserPreferencesVPN().addCachedDiscoveredAccounts([account]);
    log("XXX: saved account: $account");
    widget.onAccount(account);
  }
}

enum _State {
  welcome,
  // Import or generate identity
  setup_choice,

  // If the user generated an identity suggest backing it up
  backup_identity,

  // Specify the funder and chain
  setup_account,

  // Begin PAC purchase
  confirm_purchase,
  // after hitting confirm wait for processing to begin
  confirm_purchase_wait,
  processing_pac,
  processing_chain,
  processing_timeout
}

class _TitleContent {
  final String text;
  final bool showDismiss;

  // The state to return to if the back button is tapped.
  final _State? backState;

  _TitleContent({
    required this.text,
    this.showDismiss = false,
    this.backState,
  });
}
