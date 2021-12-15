import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/dapp_withdraw_funds.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/util/on_off.dart';
import 'account_manager/account_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'account_manager/account_detail_poller.dart';
import 'dapp_add_funds.dart';
import 'dapp_advanced_funds.dart';
import 'dapp_button.dart';

class DappHome extends StatefulWidget {
  const DappHome({Key key}) : super(key: key);

  @override
  State<DappHome> createState() => _DappHomeState();
}

class _DappHomeState extends State<DappHome> {
  OrchidWeb3Context _context;
  EthereumAddress _signer;

  // TODO: Encapsulate this in a provider widget
  AccountDetailPoller _accountDetail;

  final _signerField = TextEditingController();
  final _scrollController = ScrollController();
  var _showWalletConnect;

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_signerFieldChanged);
    log("dapp home query = ${Uri.base.queryParameters}");
    _showWalletConnect = Uri.base.queryParameters["wc"] != null;
    initStateAsync();
  }

  void initStateAsync() async {
    // TODO: TESTING
    // await Future.delayed(Duration(seconds: 0), () {
    //   _connectEthereum();
    //   _signer =
    //       EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
    //   _signerField.text = _signer.toString();
    // });
  }

  bool get _connected {
    return _context != null;
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

  void _updateAccountDetail() {
    setState(() {});
  }

  // TODO: replace this account detail management with a provider builder
  void _clearAccountDetail() {
    _accountDetail?.cancel();
    _accountDetail?.removeListener(_updateAccountDetail);
    _accountDetail = null;
  }

  // TODO: replace this account detail management with a provider builder
  void _selectedAccountChanged() async {
    _clearAccountDetail();
    if (_signer != null && _context?.walletAddress != null) {
      var account = Account.fromSignerAddress(
        signerAddress: _signer,
        version: 1,
        funder: _context.walletAddress,
        chainId: _context.chain.chainId,
      );
      _accountDetail = AccountDetailPoller(
        account: account,
        pollingPeriod: Duration(seconds: 5),
      );
      _accountDetail.addListener(_updateAccountDetail);
      _accountDetail.startPolling();
      log("accountDetail = $_accountDetail");
    }
    setState(() {});
  }

  // void _onPasteSignerAddress() {
  //   ClipboardData data = await Clipboard.getData('text/plain');
  //   _pastedFunderField.text = data.text;
  // }

  @override
  Widget build(BuildContext context) {
    var showLockStatus = (_accountDetail?.lotteryPot?.isUnlocking ?? false) ||
        (_accountDetail?.lotteryPot?.isUnlocked ?? false);
    return Column(
      children: [
        pady(32),
        // connection buttons
        _buildConnectionButtons(),
        // connection info
        AnimatedSwitcher(
          duration: Duration(seconds: 1),
          child: _connected
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(height: 40, child: _buildWalletPane()),
                )
              : SizedBox(height: 48),
        ),

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
                    width: 600,
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
                            showLockStatus: showLockStatus,
                          ),
                        _buildTransactionsList(),
                        pady(40),
                        // tabs
                        if (_connected && _signer != null) ...[
                          Divider(color: Colors.white.withOpacity(0.3)),
                          pady(16),
                          _buildTabs(),
                          // pady(16),
                          // Divider(color: Colors.white.withOpacity(0.3)),
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
                      context: _context,
                      transactionHash: tx,
                      onDismiss: _dismissTransaction,
                      onTransactionUpdated: () {
                        _context?.refresh();
                        _accountDetail?.refresh();
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

  Widget _buildTabs() {
    return SizedBox(
      height: 1000,
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: AppBar(
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                indicatorColor: OrchidColors.tappable,
                tabs: [
                  Tab(child: Text("ADD FUNDS").button),
                  Tab(child: Text("WITHDRAW FUNDS").button),
                  Tab(child: Text("ADVANCED").button),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 500,
                  child: AddFundsPane(
                    context: _context,
                    wallet: _context.wallet,
                    signer: _signer,
                    onTransaction: () async {
                      _accountDetail.refresh();
                      setState(() {});
                    },
                  ),
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 500,
                  child: WithdrawFundsPane(
                    context: _context,
                    pot: _accountDetail?.lotteryPot,
                    signer: _signer,
                    onTransaction: () async {
                      _accountDetail.refresh();
                      setState(() {});
                    },
                  ),
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 500,
                  child: AdvancedFundsPane(
                    // the warn value is captured for the warn field
                    key: Key(_accountDetail?.lotteryPot?.toString() ?? ''),
                    context: _context,
                    pot: _accountDetail?.lotteryPot,
                    signer: _signer,
                    onTransaction: () async {
                      _accountDetail.refresh();
                      setState(() {});
                    },
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPane() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(width: 32, height: 32, child: _context.chain.icon),
        ),
        padx(8),
        Text(_context.chain.name).title,
        padx(16),
        _buildWalletBalance(),
        padx(32),
        OrchidCircularIdenticon(address: _context.walletAddress, size: 24),
        padx(16),
        SizedBox(
            width: 200,
            child: TapToCopyText(
              _context.walletAddress.toString(),
              style: OrchidText.title,
              overflow: TextOverflow.ellipsis,
              padding: EdgeInsets.zero,
            )),
      ],
    );
  }

  Widget _buildWalletBalance() {
    if (_context.wallet == null) {
      return Container();
    }
    return SelectableText(_context.wallet.balance.formatCurrency(),
        style: OrchidText.title);
  }

  Widget _buildPasteSignerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text("Orchid Identity:").title,
        ),
        pady(12),
        OrchidTextField(
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
    );
  }

  Row _buildConnectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DappButton(
          text: "Connect",
          onPressed: _connected ? null : _connectEthereum,
        ),
        if (_showWalletConnect) ...[
          padx(24),
          DappButton(
            text: "Wallet Connect",
            onPressed: _connected ? null : _connectWalletConnect,
            trailing: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 16.0),
              child: Icon(Icons.qr_code, color: Colors.black),
            ),
          ),
        ],
        padx(24),
        DappButton(
          text: "Disconnect",
          onPressed: _connected ? _disconnect : null,
        ),
      ],
    );
  }

  void _connectEthereum() async {
    if (!Ethereum.isSupported) {
      AppDialogs.showAppDialog(
          context: context,
          title: "No Wallet",
          bodyText: "No Wallet or Browser not supported.");
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
      log("wc connect, err = $err");
      return;
    }
    if (!wc.connected) {
      AppDialogs.showAppDialog(
          context: context,
          title: "Error",
          bodyText: "Failed to connect to WalletConnect.");
      return;
    }

    // TODO: Check chain here
    var web3 = await OrchidWeb3Context.fromWalletConnect(wc);
    _setNewContex(web3);
  }

  // Init a new context, disconnecting any old context and registering listeners
  void _setNewContex(OrchidWeb3Context context) async {
    // Clear the old context, removing listeners and disposing of it properly.
    _context?.disconnect();

    // Register listeners on the new context
    context?.onAccountsChanged((accounts) {
      log("web3: accounts changed: $accounts");
      _onAccountOrChainChange();
    });
    context?.onChainChanged((chainId) {
      log("web3: chain changed: $chainId");
      _onAccountOrChainChange();
    });
    // _context?.onConnect(() { log("web3: connected"); });
    // _context?.onDisconnect(() { log("web3: disconnected"); });
    context?.onWalletUpdate(() {
      // Update the UI
      setState(() {});
    });

    log("new context: $context");
    _context = context;

    // The context was replaced or updated. Check various attributes.
    // check the contract
    if (_context != null) {
      var code = await _context.web3
          .getCode(OrchidContractV1.lotteryContractAddressV1);
      if (code == "0x") {
        return _noContract();
      }
    }
    _context?.refresh();

    _selectedAccountChanged();

    if (_context != null) {
      OrchidEthereumV1.setWeb3Provider(OrchidEthereumV1Web3Impl(_context));
    } else {
      OrchidEthereumV1.setWeb3Provider(null);
    }

    setState(() {});
  }

  /// Update on change of address or chain by rebuilding the web3 context.
  void _onAccountOrChainChange() async {
    if (_context == null) {
      return;
    }

    // Check chain before constructing web3
    var chainId = await ethereum.getChainId();
    if (!Chains.isKnown(chainId)) {
      return _invalidChain();
    }

    // Recreate the context wrapper
    var context;
    if (_context.ethereumProvider != null) {
      context = await OrchidWeb3Context.fromEthereum(_context.ethereumProvider);
    } else {
      context = await OrchidWeb3Context.fromWalletConnect(
          _context.walletConnectProvider);
    }
    _setNewContex(context);
  }

  _dismissTransaction(String txHash) {
    UserPreferences().removeTransaction(txHash);
  }

  void _invalidChain() {
    AppDialogs.showAppDialog(
        context: context,
        title: "Unknown Chain",
        bodyText: "The Orchid Account Manager doesn't support this chain yet.");

    _setNewContex(null);
  }

  void _noContract() {
    AppDialogs.showAppDialog(
        context: context,
        title: "Orchid isn't on this chain",
        bodyText:
            "The Orchid contract hasn't been deployed on this chain yet.");

    _setNewContex(null);
  }

  void _disconnect() async {
    _context?.disconnect();
    setState(() {
      _clearAccountDetail();
      _context = null;
    });
  }

  S get s {
    return S.of(context);
  }
}

