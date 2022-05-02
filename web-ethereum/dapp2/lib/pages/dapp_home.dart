import 'package:orchid/orchid.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/pages/v0/dapp_tabs_v0.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/util/gestures.dart';
import 'package:styled_text/styled_text.dart';
import 'dapp_button.dart';
import 'dapp_chain_selector_button.dart';
import 'dapp_settings_button.dart';
import 'dapp_version_button.dart';
import 'dapp_wallet_button.dart';
import 'v1/dapp_tabs_v1.dart';

class DappHome extends StatefulWidget {
  const DappHome({Key key}) : super(key: key);

  @override
  State<DappHome> createState() => _DappHomeState();
}

class _DappHomeState extends State<DappHome> {
  OrchidWeb3Context _web3Context;
  EthereumAddress _signer;

  // TODO: Encapsulate this in a provider widget
  AccountDetailPoller _accountDetail;

  final _signerField = TextEditingController();
  final _scrollController = ScrollController();

  /// The contract version defaulted or selected by the user.
  /// Null if no contacts are available.
  int _contractVersionSelectedValue;

  int get _contractVersionSelected {
    return _contractVersionSelectedValue;
  }

  void _selectContractVersion(int version) {
    // if (version == _contractVersionSelected) { return; }
    log("XXX: version = $version");
    _contractVersionSelectedValue = version;
    _onContractVersionChanged(version);
  }

  Set<int> get _contractVersionsAvailable {
    return _web3Context?.contractVersionsAvailable;
  }

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_signerFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    // (TESTING)
    if (OrchidUserParams().test) {
      await Future.delayed(Duration(seconds: 0), () {
        _connectEthereum();
        _signer =
            EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
        _signerField.text = _signer.toString();
      });
    }
  }

  bool get _connected {
    return _web3Context != null;
  }

  void _signerFieldChanged() {
    // signer field changed?
    var oldSigner = _signer;
    try {
      _signer = EthereumAddress.from(_signerField.text);
    } catch (err) {
      _signer = null;
    }
    if (_signer != oldSigner) {
      _selectedAccountChanged();
    }

    // Update UI
    setState(() {});
  }

  void _accountDetailUpdated() {
    setState(() {});
  }

  // TODO: replace this account detail management with a provider builder
  void _clearAccountDetail() {
    // log("XXX: clearAccountDetail");
    _accountDetail?.cancel();
    _accountDetail?.removeListener(_accountDetailUpdated);
    _accountDetail = null;
  }

  // TODO: replace this account detail management with a provider builder
  // Start polling the correct account
  void _selectedAccountChanged() async {
    // log("XXX: selectedAccountChanged");
    _clearAccountDetail();
    if (_signer != null && _web3Context?.walletAddress != null) {
      var account = Account.fromSignerAddress(
        signerAddress: _signer,
        version: _contractVersionSelected,
        funder: _web3Context.walletAddress,
        chainId: _web3Context.chain.chainId,
      );
      _accountDetail = AccountDetailPoller(
        account: account,
        pollingPeriod: Duration(seconds: 5),
      );
      _accountDetail.addListener(_accountDetailUpdated);
      _accountDetail.startPolling();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This must be wide enough to accommodate the tab names.
    final mainColumnWidth = 800.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        _buildHeader().padx(32).top(32).bottom(64),

        // main info column
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: OrchidColors.tappable,
              scrollbarTheme: ScrollbarThemeData(
                thumbColor:
                    MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
                isAlwaysShown: true,
              ),
            ),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                physics: OrchidPlatform.isWeb ? ClampingScrollPhysics() : null,
                controller: _scrollController,
                child: Center(
                  child: SizedBox(
                    width: mainColumnWidth,
                    child: Column(
                      children: [
                        // logo
                        // pady(_accountDetail == null ? 64 : 32),
                        // _buildLogo(),
                        // pady(16),
                        if (_connected) _buildPasteSignerField(),
                        pady(40),
                        // account card
                        if (_accountDetail != null)
                          AccountCard(
                            accountDetail: _accountDetail,
                            initiallyExpanded: true,
                          ),
                        _buildTransactionsList(),
                        pady(40),
                        // tabs
                        if (_connected && _signer != null) ...[
                          Divider(color: Colors.white.withOpacity(0.3)),
                          pady(16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildTabs(),
                          ).padx(8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildFooter().pad(32),
      ],
    );
  }

  Widget _buildLogo() {
    final size = AppSize(context);
    final narrow = (_connected && size.narrowerThanWidth(765)) ||
        size.narrowerThanWidth(680);

    return TripleTapGestureDetector(
      onTripleTap: _openLogsPage,
      child: AnimatedContainer(
        duration: millis(300),
        width: narrow ? 24 : 94,
        child: narrow
            ? OrchidAsset.svg.orchid_logo_small
            : OrchidAsset.svg.orchid_logo_text,
      ),
    );
  }

  void _openLogsPage() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return LoggingPage();
    }));
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: (_contractVersionSelected != null)
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: [
        _buildVersionButton(),
        StyledText(
          style: OrchidText.body1,
          textAlign: TextAlign.center,
          text: "Need help?  "
              "For guidance on creating an\n"
              "Orchid Account see our <link>step-by-step guide</link>.",
          tags: {
            'link': OrchidText.body1.linkStyle.link(OrchidUrls.join),
          },
        ).padx(16),
        if (_contractVersionSelected != null)
          SizedBox(width: 48)
        else
          Container(),
      ],
    );
  }

  Widget _buildVersionButton() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _contractVersionSelected != null
          ? _buildVersionButtonImpl()
          : Container(),
    );
  }

  Widget _buildVersionButtonImpl() {
    return DappVersionButton(
        contractVersionSelected: _contractVersionSelected,
        selectContractVersion: _selectContractVersion,
        contractVersionsAvailable: _contractVersionsAvailable);

    /*
    return SizedBox(
      width: 48,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: OrchidColors.new_purple,
          borderRadius: BorderRadius.all(
            Radius.circular(16.0),
          ),
        ),
        child: Center(
            child: Text(_contractVersionSelected == 0 ? "V0" : "V1")
                .body1
                .height(1.8)),
      ),
    );
     */
  }

  Widget _buildTabs() {
    if (_contractVersionSelected == null) {
      return Container();
    }
    switch (_contractVersionSelected) {
      case 0:
        return DappTabsV0(
          web3Context: _web3Context,
          signer: _signer,
          accountDetail: _accountDetail,
        );
      case 1:
        return DappTabsV1(
          web3Context: _web3Context,
          signer: _signer,
          accountDetail: _accountDetail,
        );
      default:
        throw Exception('unknown contract version');
    }
  }

  // The transactions list monitors transaction progress of pending transactions.
  // The individual transaction panels trigger refresh of the wallet and orchid
  // account info here whenever they are added or updated.
  Widget _buildTransactionsList() {
    return UserPreferences().transactions.builder((txs) {
      if (txs == null) {
        return Container();
      }
      var children = txs
          .map((tx) => Padding(
                padding: const EdgeInsets.only(top: 32),
                child: TransactionStatusPanel(
                  context: _web3Context,
                  transactionHash: tx,
                  onDismiss: _dismissTransaction,
                  onTransactionUpdated: () {
                    _refreshUserData();
                  },
                ),
              ))
          .toList();
      return AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: Column(
          key: Key(children.length.toString()),
          children: children,
        ),
      );
    });
  }

  Widget _buildPasteSignerField() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(s.orchidIdentity + ':').title,
          ),
          pady(12),
          OrchidTextField(
            hintText: '0x...',
            controller: _signerField,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final _showWalletConnect = OrchidUserParams().has('wc');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // logo
        _buildLogo(),
        Row(
          children: [
            _buildChainSelector().left(24),
            _buildWalletButton().left(16),
            if (_showWalletConnect) _buildWalletConnectTMButton().left(16),
            // if (_contractVersionsAvailable != null) _buildVersionSwitch(),
            DappSettingsButton(
              contractVersionsAvailable: _contractVersionsAvailable,
              contractVersionSelected: _contractVersionSelected,
              selectContractVersion: _selectContractVersion,
            ).left(16),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletConnectTMButton() {
    return DappButton(
      // 'WalletConnect' is a name, not a description
      text: "WalletConnect",
      onPressed: _connected ? null : _connectWalletConnect,
      trailing: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 16.0),
        child: Icon(Icons.qr_code, color: Colors.black),
      ),
    );
  }

  Widget _buildWalletButton() {
    final narrow = AppSize(context).narrowerThanWidth(550);
    final reallyNarrow = AppSize(context).narrowerThanWidth(460);
    return AnimatedCrossFade(
      duration: Duration(milliseconds: 300),
      crossFadeState:
          _connected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      // Wallet info button
      firstChild: SizedBox(
        // Hight must be set on each child
        height: 40,
        child: DappWalletButton(
          web3Context: _web3Context,
          onDisconnect: _disconnect,
          showBalance: !narrow,
        ),
      ),
      // Connect button
      secondChild: SizedBox(
        height: 40,
        child: DappButton(
          width: reallyNarrow ? 140: null,
          textStyle: OrchidText.medium_18_025.black.copyWith(height: 1.8),
          text: s.connect.toUpperCase(),
          onPressed: _connected ? null : _connectEthereum,
        ),
      ),
    );
  }

  Widget _buildChainSelector() {
    final size = AppSize(context);
    final narrow = (_connected && size.narrowerThanWidth(700)) ||
        size.narrowerThanWidth(600);
    return SizedBox(
      width: narrow ? 40 : 190,
      height: 40,
      child: DappChainSelectorButton(
        iconOnly: narrow,
        selected: _web3Context?.chain,
        onSelection: _switchOrAddChain,
        enabled: _web3Context != null,
      ),
    );
  }

  void _switchOrAddChain(Chain chain) async {
    log("XXX: switch chain: $chain");
    final ethereum = _web3Context.ethereumProvider;
    try {
      await ethereum.walletSwitchChain(chain.chainId);
    } on EthereumUserRejected {
      log("XXX: user rejected switch");
    } on EthereumUnrecognizedChainException {
      log("XXX: chain not recognized, suggesting add");
      _addChain(chain);
    } on EthereumException catch (err) {
      // If metamask gives us an exception that includes text suggesting calling
      // the add chain method we'll assume this was was an unrecognized chain.
      if (err.message.contains('wallet_addEthereumChain')) {
        log("XXX: inferring chain not recognized from exception message, suggesting add. err=$err");
        _addChain(chain);
      }
      if (err.message.contains('already pending for origin')) {
        log("XXX: inferring request pending from exception message: err=$err");
        _showRequestPendingMessage();
      } else {
        log("Unknown EthereumException in switch chain: $err");
      }
    } catch (err) {
      log("Unknown err in switch chain: $err");
    }
  }

  void _addChain(Chain chain) async {
    final ethereum = _web3Context.ethereumProvider;
    try {
      await ethereum.walletAddChain(
        chainId: chain.chainId,
        chainName: chain.name,
        nativeCurrency: CurrencyParams(
          name: chain.nativeCurrency.symbol,
          symbol: chain.nativeCurrency.symbol,
          decimals: chain.nativeCurrency.decimals,
        ),
        blockExplorerUrls:
            chain.explorerUrl != null ? [chain.explorerUrl] : null,
        rpcUrls: [chain.providerUrl],
      );
    } on EthereumUserRejected {
      log("XXX: user rejected add chain");
    } catch (err) {
      log("XXX: add chain failed: $err");
    }
  }

  void _connectEthereum() async {
    try {
      await _tryConnectEthereum();
    } on EthereumException catch (err) {
      // Infer the "request already pending" exception from the exception text.
      if (err.message.contains('already pending for origin')) {
        log("XXX: inferring request pending from exception message: err=$err");
        _showRequestPendingMessage();
      } else {
        log("Unknown EthereumException in connect: $err");
      }
    } catch (err) {
      log("Unknown err in connect ethereum: $err");
    }
  }

  void _showRequestPendingMessage() {
    AppDialogs.showAppDialog(
      context: context,
      title: "Check Wallet",
      bodyText: "Check your Wallet app or extension for a pending request.",
    );
  }

  void _tryConnectEthereum() async {
    if (!Ethereum.isSupported) {
      AppDialogs.showAppDialog(
          context: context,
          title: s.noWallet,
          bodyText: s.noWalletOrBrowserNotSupported);
      return;
    }

    // Check chain before constructing web3
    var chainId = await ethereum.getChainId();
    if (!Chains.isKnown(chainId)) {
      return _invalidChain();
    }

    var web3 = await OrchidWeb3Context.fromEthereum(ethereum);
    _setNewContex(web3);
  }

  void _connectWalletConnect() async {
    var chain = Chains.Ethereum;
    var wc = WalletConnectProvider.fromRpc(
      {chain.chainId: chain.providerUrl},
      chainId: chain.chainId,
    );
    try {
      await wc.connect();
    } catch (err) {
      log('wc connect, err = $err');
      return;
    }
    if (!wc.connected) {
      AppDialogs.showAppDialog(
          context: context,
          title: s.error,
          bodyText: s.failedToConnectToWalletconnect);
      return;
    }

    // TODO: Check chain here
    var web3 = await OrchidWeb3Context.fromWalletConnect(wc);
    _setNewContex(web3);
  }

  // Init a new context, disconnecting any old context and registering listeners
  void _setNewContex(OrchidWeb3Context web3Context) async {
    log('set new context: $web3Context');

    // Clear the old context, removing listeners and disposing of it properly.
    _web3Context?.disconnect();

    // Register listeners on the new context
    web3Context?.onAccountsChanged((accounts) {
      log('web3: accounts changed: $accounts');
      _onAccountOrChainChange();
    });
    web3Context?.onChainChanged((chainId) {
      log('web3: chain changed: $chainId');
      _onAccountOrChainChange();
    });
    // _context?.onConnect(() { log('web3: connected'); });
    // _context?.onDisconnect(() { log('web3: disconnected'); });
    web3Context?.onWalletUpdate(() {
      // Update the UI
      setState(() {});
    });

    // Install the new context here and as the UI provider
    _web3Context = web3Context;
    try {
      _setAppWeb3Provider(web3Context);
    } catch (err, stack) {
      log("set new context: error setting app web3 provider: $err,\n$stack");
    }

    // The context was replaced or updated. Check various attributes.
    // check the contract
    if (_web3Context != null) {
      if (_contractVersionsAvailable == null ||
          _contractVersionsAvailable.isEmpty) {
        return _noContract();
      }
    }

    try {
      _web3Context?.refresh();
    } catch (err) {
      log("set new context: error in refreshing context: $err");
    }

    // Default the contract version
    if (_contractVersionsAvailable != null) {
      final selectedVersion = _web3Context.contractVersionsAvailable.contains(1)
          ? 1
          : _web3Context.contractVersionsAvailable.contains(0)
              ? 0
              : null;
      _selectContractVersion(selectedVersion);
    }
    // XXX
    // if (OrchidUserParams().test) {
    //   _contractVersionSelected = 0;
    // }

    try {
      _selectedAccountChanged();
    } catch (err) {
      log("set new context: error in selected account changed: $err");
    }
    setState(() {});
  }

  // For contracts that may exist on chains other than main net we ensure that
  // all requests go through the web3 context.
  void _setAppWeb3Provider(OrchidWeb3Context web3Context) {
    // log("XXX: setAppWeb3Provider: $web3Context");
    if (web3Context != null &&
        _contractVersionSelected != null &&
        _contractVersionSelected > 0) {
      OrchidEthereumV1.setWeb3Provider(OrchidEthereumV1Web3Impl(web3Context));
    } else {
      OrchidEthereumV1.setWeb3Provider(null);
    }
  }

  /// Update on change of address or chain by rebuilding the web3 context.
  void _onAccountOrChainChange() async {
    // log('XXX: _onAccountOrChainChanged');
    if (_web3Context == null) {
      return;
    }

    // Check chain before constructing web3
    var chainId = await ethereum.getChainId();
    if (!Chains.isKnown(chainId)) {
      return _invalidChain();
    }

    // Recreate the context wrapper
    var context;
    if (_web3Context.ethereumProvider != null) {
      context =
          await OrchidWeb3Context.fromEthereum(_web3Context.ethereumProvider);
    } else {
      context = await OrchidWeb3Context.fromWalletConnect(
          _web3Context.walletConnectProvider);
    }
    _setNewContex(context);
  }

  _dismissTransaction(String txHash) {
    UserPreferences().removeTransaction(txHash);
  }

  void _onContractVersionChanged(int version) async {
    _selectedAccountChanged();
    _setAppWeb3Provider(_web3Context);
    // Update the UI
    setState(() {});
  }

  // Refresh the wallet and account balances
  void _refreshUserData() {
    _web3Context?.refresh();
    _accountDetail?.refresh();
  }

  void _invalidChain() {
    AppDialogs.showAppDialog(
        context: context,
        title: s.unknownChain,
        bodyText: s.theOrchidAccountManagerDoesntSupportThisChainYet);

    _setNewContex(null);
  }

  void _noContract() {
    AppDialogs.showAppDialog(
        context: context,
        title: s.orchidIsntOnThisChain,
        bodyText: s.theOrchidContractHasntBeenDeployedOnThisChainYet);

    _setNewContex(null);
  }

  void _disconnect() async {
    _web3Context?.disconnect();
    setState(() {
      _clearAccountDetail();
      _web3Context = null;
      _contractVersionSelectedValue = null;
    });
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    _signerField.removeListener(_signerFieldChanged);
    super.dispose();
  }
}
