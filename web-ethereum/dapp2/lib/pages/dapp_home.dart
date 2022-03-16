import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_chain_selection.dart';
import 'package:orchid/orchid/orchid_wallet_identicon.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/pages/v0/dapp_tabs_v0.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/util/localization.dart';
import 'dapp_button.dart';
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

  set _contractVersionSelected(int version) {
    _contractVersionSelectedValue = version;
    _onContractVersionChanged(version);
  }

  Set<int> get versions {
    return _web3Context?.contractVersionsAvailable;
  }

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_signerFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {
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

  // void _onPasteSignerAddress() {
  //   ClipboardData data = await Clipboard.getData('text/plain');
  //   _pastedFunderField.text = data.text;
  // }

  @override
  Widget build(BuildContext context) {
    // This must be wide enough to accommodate the tab names.
    final mainColumnWidth = 800.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pady(32),
        // connection buttons
        FittedBox(
          child: _buildConnectionRow(),
          fit: BoxFit.scaleDown,
        ).padx(8),

        // connection info
        FittedBox(
          child: AnimatedSwitcher(
            duration: Duration(seconds: 1),
            child: _connected
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                    child: SizedBox(height: 40, child: _buildWalletPane()),
                  )
                : SizedBox(
                    height: 48,
                    width:
                        48, // why is this necessary to preserve overall padding?
                  ),
          ),
          fit: BoxFit.scaleDown,
        ).padx(8),

        // main info column
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: OrchidColors.tappable,
              scrollbarTheme: ScrollbarThemeData(
                thumbColor:
                    MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
                // isAlwaysShown: true,
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
                        pady(_accountDetail == null ? 64 : 32),
                        AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: _accountDetail == null ? 180 : 64,
                            width: _accountDetail == null ? 300 : 128,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: NeonOrchidLogo(
                                showBackground: false,
                                light: _connected ? 1.0 : 0.0,
                              ),
                            )),
                        pady(16),
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
      ],
    );
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
    return StreamBuilder<List<String>>(
        stream: UserPreferences().transactions.stream(),
        builder: (context, snapshot) {
          var txs = snapshot.data;
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

  /// The row showing the chain, wallet balance, and wallet address.
  Widget _buildWalletPane() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 1, right: 8),
          child:
              SizedBox(width: 22, height: 22, child: _web3Context.chain.icon),
        ),
        padx(8),
        Text(_web3Context.chain.name).title,
        padx(12),
        _buildWalletBalances(),
        padx(32),
        OrchidWalletIdenticon(address: _web3Context.walletAddress),
        padx(16),
        SizedBox(
            width: 125,
            child: TapToCopyText(
              _web3Context.walletAddress.toString(elide: false),
              displayText: _web3Context.walletAddress.toString(elide: true),
              style: OrchidText.title,
              // style: TextStyle(color: Colors.white),
              padding: EdgeInsets.zero,
              overflow: TextOverflow.visible,
            )),
      ],
    );
  }

  Widget _buildWalletBalances() {
    final wallet = _web3Context?.wallet;
    if (wallet == null) {
      return Container();
    }
    var showOxtBalance = wallet.oxtBalance != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SelectableText(
          wallet.balance.formatCurrency(locale: context.locale),
          style: OrchidText.title,
          textAlign: TextAlign.right,
        ),
        if (showOxtBalance)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: SelectableText(
                wallet.oxtBalance.formatCurrency(locale: context.locale),
                style: OrchidText.title,
                textAlign: TextAlign.right),
          ),
      ],
    );
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
            height: 60,
            hintText: '0x...',
            margin: EdgeInsets.zero,
            controller: _signerField,
            // readOnly: widget.readOnly(),
            // enabled: widget.editable(),
            // trailing: FlatButton(
            //     color: Colors.transparent,
            //     padding: EdgeInsets.zero,
            //     child: Text(s.paste, style: OrchidText.button.purpleBright),
            //     onPressed: _onPasteSignerAddress)
          ),
        ],
      ),
    );
  }

  Row _buildConnectionRow() {
    final _showWalletConnect = OrchidUserParams().has('wc');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // connect / disconnect button
        if (_connected)
          DappButton(
            text: s.disconnect.toUpperCase(),
            onPressed: _connected ? _disconnect : null,
          )
        else
          DappButton(
            text: s.connect.toUpperCase(),
            onPressed: _connected ? null : _connectEthereum,
          ),

        // wallet connect
        if (_showWalletConnect) ...[
          padx(24),
          DappButton(
            // 'WalletConnect' is a name, not a description
            text: "WalletConnect",
            onPressed: _connected ? null : _connectWalletConnect,
            trailing: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 16.0),
              child: Icon(Icons.qr_code, color: Colors.black),
            ),
          ),
        ],
        if (_connected) _buildChainSelector().left(24),
        _buildVersionSwitch(),
        if (_connected) _buildSettings().left(16),
      ],
    );
  }

  Widget _buildChainSelector() {
    return SizedBox(
      width: 250,
      child: ChainSelectionDropdown(
        selected: _web3Context?.chain,
        onSelection: _switchOrAddChain,
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
        blockExplorerUrls: [chain.explorerUrl],
        rpcUrls: [chain.providerUrl],
      );
    } on EthereumUserRejected {
      log("XXX: user rejected add chain");
    } catch (err) {
      log("XXX: add chain failed: $err");
    }
  }

  Widget _buildSettings() {
    return SizedBox(
      width: 48,
      child: TextButton(
          onPressed: _showSettings,
          child: Icon(
            Icons.settings,
            size: 24,
            color: OrchidColors.tappable,
          )),
    );
  }

  void _showSettings() {
    AppDialogs.showAppDialog(
        context: context,
        body: StreamBuilder<bool>(
            stream: UserPreferences().useBlockiesIdenticons.stream(),
            builder: (context, snapshot) {
              final useBlockies = snapshot.data;
              if (useBlockies == null) {
                return Container();
              }
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Settings").title,
                    pady(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Use Blockies Identicon:").button,
                        DappSwitch(
                            value: useBlockies,
                            onChanged: (value) async {
                              await UserPreferences()
                                  .useBlockiesIdenticons
                                  .set(value);
                              setState(() {});
                            }),
                      ],
                    ),
                  ],
                ),
              );
            }));
  }

  Widget _buildVersionSwitch() {
    if (versions == null) {
      return Container();
    }
    var selectedVersion = _contractVersionSelected;
    if (versions.length == 1) {
      return Text("V${selectedVersion}").title.height(1.8).left(24);
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _contractVersionSelected = 0;
            });
          },
          child: Opacity(
              opacity: selectedVersion == 0 ? 1.0 : 0.4,
              child: Text("V0").title),
        ),
        padx(8),
        DappAlternativesSwitch(
          value: selectedVersion == 1,
          onChanged: (bool value) {
            setState(() {
              _contractVersionSelected = value ? 1 : 0;
            });
          },
        ),
        padx(8),
        GestureDetector(
            onTap: () {
              setState(() {
                _contractVersionSelected = 1;
              });
            },
            child: Opacity(
                opacity: selectedVersion == 1 ? 1.0 : 0.4,
                child: Text("V1").title)),
      ],
    ).left(24);
  }

  void _connectEthereum() async {
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
      if (versions == null || versions.isEmpty) {
        return _noContract();
      }
    }

    try {
      _web3Context?.refresh();
    } catch (err) {
      log("set new context: error in refreshing context: $err");
    }

    // Default the contract version
    if (versions != null) {
      _contractVersionSelected =
          _web3Context.contractVersionsAvailable.contains(1)
              ? 1
              : _web3Context.contractVersionsAvailable.contains(0)
                  ? 0
                  : null;
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
    if (web3Context != null && _contractVersionSelected != null && _contractVersionSelected > 0) {
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
    });
  }

  S get s {
    return S.of(context);
  }
}

class DappAlternativesSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool value) onChanged;

  const DappAlternativesSwitch({
    Key key,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      trackColor: Colors.grey.withOpacity(0.5),
      thumbColor: Colors.white,
      activeColor: Colors.grey.withOpacity(0.5),
      value: value,
      onChanged: onChanged,
    );
  }
}

class DappSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool value) onChanged;

  const DappSwitch({
    Key key,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      thumbColor: value ? OrchidColors.tappable : Colors.white,
      activeColor: value
          ? OrchidColors.tappable.withOpacity(0.5)
          : Colors.grey.withOpacity(0.5),
      value: value,
      onChanged: onChanged,
    );
  }
}
