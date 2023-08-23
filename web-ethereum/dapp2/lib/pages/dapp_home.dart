// @dart=2.9
import 'dart:math';
import 'package:orchid/api/orchid_web3/v1/orchid_contract_deployment_v1.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/pages/v0/dapp_tabs_v0.dart';
import 'package:orchid/api/orchid_web3/wallet_connect_eth_provider.dart';
import 'package:orchid/util/gestures.dart';
import '../orchid/menu/orchid_chain_selector_menu.dart';
import 'dapp_settings_button.dart';
import 'dapp_wallet_info_button.dart';
import 'dapp_wallet_select_button.dart';
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

  // TODO: Encapsulate this in a provider builder widget (ala TokenPriceBuilder)
  // TODO: Before that we need to add a controller to our PollingBuilder to allow
  // TODO: for refresh on demand.
  AccountDetailPoller _accountDetail;

  Chain _userDefaultChainSelection;

  final _signerField = AddressValueFieldController();
  final _scrollController = ScrollController();

  /// The contract version defaulted or selected by the user.
  /// Null if no contacts are available.
  int _contractVersionSelectedValue;

  int get _contractVersionSelected {
    return _contractVersionSelectedValue;
  }

  void _selectContractVersion(int version) {
    // if (version == _contractVersionSelected) { return; }
    log('XXX: version = $version');
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
        _signerField.textController.text = _signer.toString();
      });
    }
  }

  /// If the user has previously connected accounts reconnect without requiring
  /// the user to hit the connect button.
  Future<void> _checkForExistingConnectedAccounts() async {
    try {
      var accounts = await ethereum?.getAccounts() ?? [];
      if (accounts.isNotEmpty) {
        log('connect: User already has accounts, connecting.');
        await Future.delayed(Duration(seconds: 0), () {
          _connectEthereum();
        });
      } else {
        log('connect: No connected accounts, require the user to initiate.');
      }
    } catch (err) {
      log('connect: Error checking getAccounts: $err');
    }
  }

  void _signerFieldChanged() {
    // signer field changed?
    var oldSigner = _signer;
    _signer = _signerField.value;
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
      // Avoid starting the poller in the rare case where there are no contracts
      if (_contractVersionSelected != null) {
        var account = Account.fromSignerAddress(
          signerAddress: _signer,
          version: _contractVersionSelected,
          funder: _web3Context.walletAddress,
          chainId: _web3Context.chain.chainId,
        );
        _accountDetail = AccountDetailPoller(
          account: account,
          pollingPeriod: Duration(seconds: 10),
        );
        _accountDetail.addListener(_accountDetailUpdated);
        _accountDetail.startPolling();
      }
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
      ],
    );
  }

  int _txStatusIndex = 0;

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
                    if (_contractVersionsAvailable != null &&
                        _contractVersionsAvailable.isEmpty)
                      RoundedRect(
                        backgroundColor: OrchidColors.dark_background,
                        child: Text(s
                                .theOrchidContractHasntBeenDeployedOnThisChainYet)
                            .subtitle
                            .height(1.7)
                            .withColor(OrchidColors.status_yellow)
                            .pad(24),
                      ).center.bottom(24),

                    _buildTransactionsList().top(24),

                    // signer field
                    ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: _buildPasteSignerField().top(24).padx(8)),

                    // account card
                    AnimatedVisibility(
                      show: _hasAccount,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: altColumnWidth, maxWidth: altColumnWidth),
                        child: AccountCard(
                          // todo: the key here just allows us to expanded when details are available
                          // todo: maybe make that the default behavior of the card
                          key:
                              Key(_accountDetail?.funder?.toString() ?? 'null'),
                          minHeight: true,
                          showAddresses: false,
                          showContractVersion: false,
                          accountDetail: _accountDetail,
                          // initiallyExpanded: _accountDetail != null,
                          initiallyExpanded: false,
                          // partial values from the connection panel
                          partialAccountFunderAddress:
                              _web3Context?.walletAddress,
                          partialAccountSignerAddress: _signer,
                        ).top(24).padx(8),
                      ),
                    ),

                    // tabs
                    // Divider(color: Colors.white.withOpacity(0.3)).bottom(8),
                    AnimatedVisibility(
                      // show: _hasAccount,
                      show: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: altColumnWidth),
                        child: _buildTabs(),
                      ).padx(8).top(16),
                    ),

                    // _buildFooter().padx(24).bottom(24),
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
      txs = (txs ?? [])
          .where((tx) => tx.chainId == _web3Context?.chain?.chainId)
          .toList();
      if (txs.isEmpty) {
        return Container();
      }

      // REMOVE: TESTING
      // txs = txs + txs + txs + txs;

      var txWidgets = txs
          .map((tx) => TransactionStatusPanel(
                context: _web3Context,
                tx: tx,
                onDismiss: _dismissTransaction,
                onTransactionUpdated: () {
                  _refreshUserData();
                },
              ))
          .toList()
          // show latest first
          .reversed
          .toList();

      final colWidth = min(MediaQuery.of(context).size.width, mainColumnWidth);
      var viewportFraction = min(0.75, 334 / colWidth);

      return AnimatedSwitcher(
        duration: millis(400),
        child: SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: txWidgets.length,
            controller: PageController(viewportFraction: viewportFraction),
            onPageChanged: (int index) =>
                setState(() => _txStatusIndex = index),
            itemBuilder: (_, i) {
              return AnimatedScale(
                  duration: millis(300),
                  scale: i == _txStatusIndex ? 1 : 0.9,
                  child: Center(child: txWidgets[i]));
            },
          ),
        ),
      );
    });
  }

  Widget _buildPasteSignerField() {
    return OrchidLabeledAddressField(
      label: s.orchidIdentity,
      controller: _signerField,
      contentPadding: EdgeInsets.only(top: 8, bottom: 18, left: 16, right: 16),
    );
  }

  Widget _buildHeader() {
    final deploy = (_contractVersionsAvailable?.contains(1) ?? false)
        ? null
        : _deployContract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // logo
        _buildLogo(),
        Row(
          children: [
            _buildChainSelector().left(16),
            _buildHeaderConnectWalletButton().left(16),
            DappSettingsButton(
              contractVersionsAvailable: _contractVersionsAvailable,
              contractVersionSelected: _contractVersionSelected,
              selectContractVersion: _selectContractVersion,
              deployContract: _connected ? deploy : null,
            ).left(16),

          ],
        ),
      ],
    );
  }

  void _deployContract() async {
    final deploy = OrchidContractDeployment(_web3Context);
    if (await deploy.deployIfNeeded()) {
      _onAccountOrChainChange();
    }
  }

  /// The "connect" button in the header that toggles the connection panel
  Widget _buildHeaderConnectWalletButton() {
    final narrow = AppSize(context).narrowerThanWidth(550);
    final reallyNarrow = AppSize(context).narrowerThanWidth(385);

    final textStyleBase =
        OrchidText.medium_16_025.semibold.black.copyWith(height: 1.8);
    final selectedTextStyle =
        textStyleBase.copyWith(color: Colors.white.withOpacity(0.8));
    final backgroundColor = OrchidColors.tappable;

    final deploy = (_contractVersionsAvailable?.contains(1) ?? false)
        ? null
        : _deployContract;

    return AnimatedCrossFade(
      duration: Duration(milliseconds: 300),
      crossFadeState:
          _connected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      // Wallet info button
      firstChild: SizedBox(
        // Hight must be set on each child
        height: 40,
        child: DappWalletInfoButton(
          web3Context: _web3Context,
          onDisconnect: _disconnect,
          showBalance: !narrow,
          minimalAddress: reallyNarrow,
          // onPressed: _toggleShowConnectPanel,
          disconnect: _disconnect,
          contractVersionsAvailable: _contractVersionsAvailable,
          contractVersionSelected: _contractVersionSelected,
          selectContractVersion: _selectContractVersion,
          deployContract: deploy,
        ),
      ),
      // Connect button
      secondChild: SizedBox(
        height: 40,
        child: DappWalletSelectButton(
          connected: _connected,
          disconnect: _disconnect,
          enabled: !_walletConnectionInProgress,
          width: reallyNarrow ? 115 : 164,
          unselectedTextStyle: textStyleBase,
          selectedTextStyle: selectedTextStyle,
          backgroundColor: backgroundColor,
          connectMetamask: _connectEthereum,
          connectWalletConnect: () =>
              _uiGuardConnectingState(_connectWalletConnect),
        ),
      ),
    );
  }

  Widget _buildChainSelector() {
    final size = AppSize(context);
    final narrow = (_connected && size.narrowerThanWidth(700)) ||
        size.narrowerThanWidth(600);
    final chain = _web3Context?.chain ?? _userDefaultChainSelection;
    return SizedBox(
      width: narrow ? 40 : 190,
      height: 40,
      child: OrchidChainSelectorMenu(
        iconOnly: narrow,
        selected: chain,
        onSelection: _switchOrAddChain,
        enabled: true,
      ),
    );
  }

  void _switchOrAddChain(Chain chain) async {
    // If there is no current context the user is selecting a default chain for future connection.
    if (_web3Context == null) {
      setState(() {
        _userDefaultChainSelection = chain;
      });
      return;
    }
    log("XXX: switch chain: $chain");

    // Handle a WalletConnect switch:
    if (_web3Context.walletConnectProvider != null) {
      await _switchOrAddChainWalletConnect(chain);
      return;
    }

    try {
      if (_web3Context.ethereumProvider != null) {
        await _web3Context.ethereumProvider.walletSwitchChain(chain.chainId);
      }
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

  // WalletConnect does have the notion of multiple chains per wallet connection,
  // however they must be specified at connection time and the connection will fail
  // if the wallet does not support the chain.  The "optional chains" parameter does not
  // seem to work currently.  So for now we will create a new connection for chain switch.
  // @see our WalletConnect provider switch chain method.  This has been tested and
  // does work if the chain is specified at init() time.
  void _switchOrAddChainWalletConnect(Chain chain) async {
    log("switchOrAddChainWalletConnect");
    // Dispatch this to avoid a flutter bug?
    Future.delayed(millis(0), () {
      AppDialogs.showConfirmationDialog(
          context: context,
          title: "Switch Chain",
          bodyText:
              "Switching to the ${chain.name} with WalletConnect will require a new connection.\n"
              "Do you wish to drop this session and reconnect?",
          commitAction: () async {
            await _disconnect();
            setState(() {
              _userDefaultChainSelection = chain;
            });
            await _uiGuardConnectingState(_connectWalletConnect);
          });
    });
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

  Future<void> _connectEthereum() async {
    log("XXX: connectEthereum");
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
      title: s.checkWallet,
      bodyText: s.checkYourWalletAppOrExtensionFor,
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

    var web3 = await OrchidWeb3Context.fromEthereum(ethereum);
    _setNewContex(web3);
  }

  var _walletConnectionInProgress = false;

  Future<void> _uiGuardConnectingState(Future<void> Function() connect) async {
    setState(() {
      _walletConnectionInProgress = true;
    });
    try {
      await connect();
    } finally {
      setState(() {
        _walletConnectionInProgress = false;
      });
    }
  }

  Future<void> _connectWalletConnect() async {
    log("XXX: connectWalletConnect");
    // const walletConnectProjectId = 'bd5be579e9cae68defff05a6fa7b0049'; // test
    const walletConnectProjectId = 'afe2e392884aefdae72d4babb5482ced';

    final chain = _userDefaultChainSelection ?? Chains.Ethereum;
    var wc = await WalletConnectEthereumProvider.init(
      projectId: walletConnectProjectId,
      rpcMap: {
        chain.chainId: chain.providerUrl,
      },
      chains: [chain.chainId],
      // This does not seem to work, otherwise we could simply connect to all
      // of our chains as optional and allow more straightforward switching.
      // optionalChains: [Chains.Gnosis.chainId, 31411234],
      showQrModal: true,
    );
    // consoleLog(wc.impl);
    try {
      log('Before wc connect');
      await wc.connect();
      log('After wc connect');
    } catch (err) {
      log('wc connect/init, err = $err');
      return;
    }
    if (!wc.connected) {
      AppDialogs.showAppDialog(
          context: context,
          title: s.error,
          bodyText: s.failedToConnectToWalletconnect);
      return;
    }

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
      log('set new context: error setting app web3 provider: $err,\n$stack');
    }

    // The context was replaced or updated. Check various attributes.
    // check the contract
    // if (_web3Context != null) {
    //   if (_contractVersionsAvailable == null ||
    //       _contractVersionsAvailable.isEmpty) {
    //     await _noContract();
    //   }
    // }

    try {
      _web3Context?.refresh();
    } catch (err) {
      log('set new context: error in refreshing context: $err');
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
      log('set new context: error in selected account changed: $err');
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
    // var chainId = await ethereum.getChainId();
    // if (!Chains.isKnown(chainId)) {
    //   return _invalidChain();
    // }

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
      log('Error constructing web context:');
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
    // TODO: Encapsulate this in a provider builder widget (ala TokenPriceBuilder)
    // TODO: Before that we need to add a controller to our PollingBuilder to allow
    // TODO: for refresh on demand.
    _accountDetail?.refresh();
  }

  Future<void> _disconnect() async {
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
