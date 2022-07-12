import 'package:browser_detector/browser_detector.dart';
import 'package:flutter/services.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/pages/v0/dapp_tabs_v0.dart';
import 'package:orchid/util/gestures.dart';
import 'package:styled_text/styled_text.dart';
import 'dapp_button.dart';
import 'dapp_chain_selector_button.dart';
import 'dapp_settings_button.dart';
import 'dapp_version_button.dart';
import 'dapp_wallet_button.dart';
import 'dapp_wallet_info_panel.dart';
import 'v1/dapp_tabs_v1.dart';
import 'package:flutter_svg/svg.dart';

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
    if (version != null) {
      _onContractVersionChanged(version);
    }
  }

  Set<int> get _contractVersionsAvailable {
    return _web3Context?.contractVersionsAvailable;
  }

  bool get _connected {
    return _web3Context != null;
  }

  bool _showConnectPanel = false;

  bool get _hasAccount =>
      _signer != null && _web3Context?.walletAddress != null;

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_signerFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    await _supportTestAccountConnect();
    await _checkForExistingConnectedAccounts();
  }

  Future<void> _supportTestAccountConnect() async {
    // (TESTING)
    if (OrchidUserParams().test) {
      await Future.delayed(Duration(seconds: 0), () {
        _connectEthereum();
        _signer =
            EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
        _signerField.text = _signer.toString();
        _showConnectPanel = true;
      });
    }
  }

  /// If the user has previously connected accounts reconnect without requiring
  /// the user to hit the connect button.
  Future<void> _checkForExistingConnectedAccounts() async {
    try {
      var accounts = await ethereum.getAccounts();
      if (accounts.isNotEmpty) {
        log("connect: User already has accounts, connecting.");
        await Future.delayed(Duration(seconds: 0), () {
          _connectEthereum();
        });
      } else {
        log("connect: No connected accounts, require the user to initiate.");
      }
    } catch (err) {
      log("connect: Error checking getAccounts: $err");
    }
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
    if (_hasAccount) {
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

      _showConnectPanel = false;
    }
    setState(() {});
  }

  // This must be wide enough to accommodate the tab names.
  final mainColumnWidth = 800.0;
  final altColumnWidth = 500.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader().padx(24).top(30).bottom(24),
        _buildMainColumn(),
        _buildFooter().padx(24).top(14).bottom(24),
      ],
    );
  }

  /// The toggleable panel that offers the connect wallet button and identity entry.
  Widget _buildConnectPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: altColumnWidth),
        child: OrchidPanel.vertical(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Connect or create Orchid Account').subtitle.bold,
                  _buildStep1Text().top(8),
                  AnimatedCrossFade(
                    duration: millis(300),
                    crossFadeState: !_connected
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildConnectButton(),
                    secondChild: DappWalletInfoPanel(
                      web3Context: _web3Context,
                      onDisconnect: _disconnect,
                    ),
                  ).top(16),
                  _buildStep2Text().top(24),
                  _buildPasteSignerField().top(16),
                  Text('Need more help getting started?').body2.top(24),
                  Text('View the step-by-step guide.')
                      .linkStyle
                      .link(url: OrchidUrls.partsOfOrchidAccount)
                      .top(8),
                ],
              ).pad(20),
              Divider(color: Colors.black, height: 1),
              TextButton(
                onPressed: _toggleShowConnectPanel,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      size: 20,
                      color: OrchidColors.tappable,
                    ).right(4),
                    Text("Tap to Minimize",
                        style: OrchidText.linkStyle.size(14)),
                  ],
                ),
              ).pady(8)
            ],
          ),
        ),
      ),
    );
  }

  Map<String, StyledTextTagBase> _textTags = {
    'bold': StyledTextTag(
      style: OrchidText.body2.bold,
    ),
    'link': OrchidText.body2.linkStyle.link(OrchidUrls.widget),
  };

  StyledText _buildStep1Text() {
    return StyledText(
      style: OrchidText.body2,
      text:
          '<bold>Step 1.</bold> Connect an ERC-20 wallet with <link>enough tokens</link> in it.',
      tags: _textTags,
    );
  }

  StyledText _buildStep2Text() {
    return StyledText(
      style: OrchidText.body2,
      text:
          '<bold>Step 2.</bold> Copy the Orchid Identity from the Orchid App by going to Manage Accounts then tapping the address.',
      tags: _textTags,
    );
  }

  // main info column
  Expanded _buildMainColumn() {
    return Expanded(
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
                    AnimatedVisibility(
                      duration: millis(500),
                      show: _showConnectPanel,
                      child: _buildConnectPanel().bottom(32).padx(20),
                    ),

                    // AnimatedSize(
                    //   duration: millis(1000),
                    //   child: _showConnectPanel ? _buildConnectPanel().bottom(32).padx(20) : Container(),
                    // ),

                    // account card
                    AccountCard(
                      // todo: the key here just allows us to expanded when details are available
                      // todo: maybe make that the default behavior of the card
                      key: Key(_accountDetail?.funder?.toString() ?? 'null'),
                      accountDetail: _accountDetail,
                      initiallyExpanded: _accountDetail != null,
                      // partial values from the connection panel
                      partialAccountFunderAddress: _web3Context?.walletAddress,
                      partialAccountSignerAddress: _signer,
                    ),

                    _buildTransactionsList(),
                    // tabs
                    // Divider(color: Colors.white.withOpacity(0.3)).bottom(8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: altColumnWidth),
                      child: _buildTabs(),
                    ).padx(8).top(16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
        width: narrow ? 40 : 94,
        child: narrow
            ? SvgPicture.asset(OrchidAssetSvg.orchid_logo_small_path,
                height: 38)
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
        // StyledText(
        //   style: OrchidText.body1,
        //   textAlign: TextAlign.center,
        //   text: "Need help?  "
        //       "For guidance on creating an\n"
        //       "Orchid Account see our <link>step-by-step guide</link>.",
        //   tags: {
        //     'link': OrchidText.body1.linkStyle.link(OrchidUrls.join),
        //   },
        // ).padx(16),
        if (_contractVersionSelected != null)
          SizedBox(width: 48)
        else
          Container(),
      ],
    );
  }

  Widget _buildVersionButton() {
    return AnimatedSwitcher(
      duration: millis(300),
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
  }

  Widget _buildTabs() {
    switch (_contractVersionSelected) {
      case 0:
        return DappTabsV0(
          web3Context: _web3Context,
          signer: _signer,
          accountDetail: _accountDetail,
        );
      case 1:
      default:
        return DappTabsV1(
          web3Context: _web3Context,
          signer: _signer,
          accountDetail: _accountDetail,
        );
    }
  }

  // The transactions list monitors transaction progress of pending transactions.
  // The individual transaction panels trigger refresh of the wallet and orchid
  // account info here whenever they are added or updated.
  Widget _buildTransactionsList() {
    return UserPreferences().transactions.builder((txs) {
      // Limit to currently selected chain
      txs = (txs ?? []).where((tx) => tx.chainId == _web3Context?.chain?.chainId).toList();
      if (txs.isEmpty) {
        return Container();
      }

      var txWidgets = txs
          .map((tx) => Padding(
                padding: const EdgeInsets.only(top: 32),
                child: TransactionStatusPanel(
                  context: _web3Context,
                  tx: tx,
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
          key: Key(txWidgets.length.toString()),
          children: txWidgets,
        ),
      );
    });
  }

  Widget _buildPasteSignerField() {
    final showPaste = !BrowserDetector().browser.isFirefox;
    return RoundedRect(
      backgroundColor: Colors.white.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.orchidIdentity + ':').body1.left(18).top(20).bottom(4),
          OrchidTextField(
            border: false,
            hintText: '0x...',
            style: OrchidText.title.copyWith(fontSize: 22, height: 1.0),
            controller: _signerField,
            trailing: showPaste
                ? IconButton(
                    icon: Icon(Icons.paste, color: Colors.white),
                    onPressed: _onPaste,
                  ).bottom(4)
                : null,
            contentPadding:
                EdgeInsets.only(top: 8, bottom: 14, left: 16, right: 16),
          ),
        ],
      ),
    );
  }

  void _onPaste() async {
    try {
      ClipboardData data = await Clipboard.getData('text/plain');
      setState(() {
        _signerField.text = data.text;
      });
    } catch (err) {
      print("Can't get clipboard: $err");
    }
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
            _buildChainSelector().left(16),
            _buildWalletButton().left(16),
            if (_showWalletConnect) _buildWalletConnectTMButton().left(16),
            // if (_contractVersionsAvailable != null) _buildVersionSwitch(),
            DappSettingsButton(
              contractVersionsAvailable: _contractVersionsAvailable,
              contractVersionSelected: _contractVersionSelected,
              selectContractVersion: _selectContractVersion,
              // onDisconnect: _disconnect,
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

  /// The connect wallet button within the connect panel
  Widget _buildConnectButton() {
    final narrow = AppSize(context).narrowerThanWidth(550);
    // final reallyNarrow = AppSize(context).narrowerThanWidth(460);
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
          onPressed: null,
        ),
      ),
      // Connect button
      secondChild: SizedBox(
        height: 40,
        child: DappButton(
          // width: reallyNarrow ? 140 : null,
          width: double.infinity,
          textStyle: OrchidText.medium_18_025.black.copyWith(height: 1.8),
          text: "CONNECT WALLET",
          onPressed: _connected ? null : _connectEthereum,
        ),
      ),
    );
  }

  /// The "connect" button in the header that toggles the connection panel
  Widget _buildWalletButton() {
    final narrow = AppSize(context).narrowerThanWidth(550);
    final reallyNarrow = AppSize(context).narrowerThanWidth(385);
    final textStyleBase = OrchidText.medium_18_025.black.copyWith(height: 1.8);
    final textStyle = _showConnectPanel
        ? textStyleBase.copyWith(color: Colors.white.withOpacity(0.4))
        : textStyleBase;
    final backgroundColor =
        _showConnectPanel ? OrchidColors.selected_color_dark : null;

    return AnimatedCrossFade(
      duration: Duration(milliseconds: 300),
      crossFadeState:
          _hasAccount ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      // Wallet info button
      firstChild: SizedBox(
        // Hight must be set on each child
        height: 40,
        child: DappWalletButton(
          web3Context: _web3Context,
          onDisconnect: _disconnect,
          showBalance: !narrow,
          minimalAddress: reallyNarrow,
          onPressed: _toggleShowConnectPanel,
        ),
      ),
      // Connect button
      secondChild: SizedBox(
        height: 40,
        child: DappButton(
          width: reallyNarrow ? 115 : 164,
          textStyle: textStyle,
          backgroundColor: backgroundColor,
          text: s.connect.toUpperCase(),
          onPressed: _toggleShowConnectPanel,
        ),
      ),
    );
  }

  void _toggleShowConnectPanel() {
    return setState(() {
      _showConnectPanel = !_showConnectPanel;
    });
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
      if (accounts.isEmpty) {
        _setNewContex(null);
      } else {
        _onAccountOrChainChange();
      }
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
    } else {
      _selectContractVersion(null);
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
    if (_web3Context == null) {
      return;
    }

    // Check chain before constructing web3
    var chainId = await ethereum.getChainId();
    if (!Chains.isKnown(chainId)) {
      return _invalidChain();
    }

    // Recreate the context wrapper
    var context = null;
    try {
      if (_web3Context.ethereumProvider != null) {
        context =
            await OrchidWeb3Context.fromEthereum(_web3Context.ethereumProvider);
      } else {
        context = await OrchidWeb3Context.fromWalletConnect(
            _web3Context.walletConnectProvider);
      }
    } catch (err) {
      log("Error constructing web context:");
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
