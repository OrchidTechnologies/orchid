import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_eth_v1_web3.dart';
import 'package:orchid/pages/transaction_status_panel.dart';
import 'package:orchid/util/on_off.dart';
import 'account_manager/account_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'account_manager/account_detail_poller.dart';

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

  // TODO: Encapsulate this in a provider widget
  OrchidWallet _wallet;

  final _signerField = TextEditingController();
  final _addBalanceField = TextEditingController();
  final _addDepositField = TextEditingController();

  bool _txPending = false;

  @override
  void initState() {
    super.initState();
    _signerField.addListener(_textFieldChanged);
    _addBalanceField.addListener(_textFieldChanged);
    _addDepositField.addListener(_textFieldChanged);
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

  void _textFieldChanged() {
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
      _accountDetail = AccountDetailPoller(account: account);
      _accountDetail.addListener(_updateAccountDetail);
      _accountDetail.startPolling();
      log("accountDetail = $_accountDetail");
    }
    setState(() {});

    _wallet = await _context?.getWallet();
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
        // main info column
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                children: [
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

  // the value or null
  Token get _addBalanceAmount {
    return _tokenFieldValue(
        controller: _addBalanceField, type: _wallet.balance.type);
  }

  // the value or null
  Token get _addDepositAmount {
    return _tokenFieldValue(
        controller: _addDepositField, type: _wallet.balance.type);
  }

  Token _tokenFieldValue({TextEditingController controller, TokenType type}) {
    var text = controller.text;
    if (text == null || text == "") {
      return type.zero;
    }
    try {
      var value = double.parse(text);
      return type.fromDouble(value);
    } catch (err) {
      return null;
    }
  }

  bool get _addBalanceFieldValid {
    var value = _addBalanceAmount;
    return value != null && value < _wallet.balance;
  }

  bool get _addDepositFieldValid {
    var value = _addDepositAmount;
    return value != null && value < _wallet.balance;
  }

  bool get _addFundsFormEnabled {
    if (_txPending) {
      return false;
    }
    if (_addBalanceFieldValid && _addDepositFieldValid) {
      var total = _addBalanceAmount + _addDepositAmount;
      return total > _wallet.balance.type.zero && total <= _wallet.balance;
    }
    return false;
  }

  void _addFunds() async {
    setState(() {
      _txPending = true;
    });
    if (!_addBalanceFieldValid) {
      return;
    }
    try {
      var txHash = await OrchidWeb3V1(_context).orchidAddFunds(
        wallet: _wallet,
        signer: _signer,
        addBalance: _addBalanceAmount,
        addEscrow: _addDepositAmount,
      );
      UserPreferences().addTransaction(txHash);
      _addBalanceField.text = '';
      _addDepositField.text = '';
      setState(() {});
    } catch (err) {
      log("Error on add funds: $err");
    }
    setState(() {
      _txPending = false;
    });
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 320,
      child: DefaultTabController(
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
                  Tab(child: Text("MOVE FUNDS").button),
                  Tab(child: Text("WITHDRAW FUNDS").button),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(child: SizedBox(width: 500, child: _buildAddFunds())),
              ),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFunds() {
    if (_wallet?.balance == null) {
      return Container();
    }
    var tokenText = Text(_wallet.balance.type.symbol ?? "").button.height(1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Add Funds").title,
        // pady(16),
        _buildLabeledNumericField(
            controller: _addBalanceField,
            label: "Balance" + ':',
            trailing: tokenText),
        pady(4),
        _buildLabeledNumericField(
            controller: _addDepositField,
            label: "Deposit" + ':',
            trailing: tokenText),
        pady(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
                text: "ADD FUNDS",
                onPressed: _addFundsFormEnabled ? _addFunds : null),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledNumericField(
      {TextEditingController controller, String label, Widget trailing}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label).button),
        Flexible(
          child: OrchidTextField(
            hintText: '0.0',
            margin: EdgeInsets.zero,
            controller: controller,
            numeric: true,
          ),
        ),
        // padx(4),
        trailing ?? Container(),
      ],
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
            child: Text(
              _context.walletAddress.toString(),
              overflow: TextOverflow.ellipsis,
            ).title),
      ],
    );
  }

  Widget _buildWalletBalance() {
    if (_wallet == null) {
      return Container();
    }
    return Text(_wallet.balance.formatCurrency()).title.white;
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
        _buildButton(
          text: "Connect",
          onPressed: _connected ? null : _connectEthereum,
        ),
        padx(24),
        _buildButton(
          text: "Wallet Connect",
          onPressed: _connected ? null : _connectWalletConnect,
          trailing: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 16.0),
            child: Icon(Icons.qr_code, color: Colors.black),
          ),
        ),
        padx(24),
        _buildButton(
          text: "Disconnect",
          onPressed: _connected ? _disconnect : null,
        ),
      ],
    );
  }

  Widget _buildButton({
    String text,
    VoidCallback onPressed,
    Widget trailing,
  }) {
    var height = 42.0;
    return Container(
        height: height,
        child: RoundedRectButton(
          text: text,
          textColor: Colors.black,
          lineHeight: 1.2,
          trailing: trailing,
          onPressed: onPressed,
        ));
  }

  void _connectEthereum() async {
    if (!Ethereum.isSupported) {
      AppDialogs.showAppDialog(
          context: context,
          title: "No Wallet",
          bodyText: "No Wallet or Browser not supported.");
      return;
    }
    var chainId = await ethereum.getChainId();
    if (!Chains.isKnown(chainId)) {
      AppDialogs.showAppDialog(
          context: context,
          title: "Unknown Chain",
          bodyText:
              "The Orchid Account Manager doesn't support this chain yet.");
      return;
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
    var web3 = await OrchidWeb3Context.fromWalletConnect(wc);
    _setNewContex(web3);
  }

  // Init a new context, disconnecting any old context and adding new listeners
  void _setNewContex(OrchidWeb3Context context) {
    _context?.removeAllListeners();
    _context?.disconnect();
    _context = context;

    _context.onAccountsChanged((accounts) {
      log("web3: accounts changed: $accounts");
      _updateContext();
    });
    _context.onChainChanged((chainId) {
      log("web3: chain changed: $chainId");
      _updateContext();
    });
    _context.onConnect(() {
      log("web3: connected");
    });
    _context.onDisconnect(() {
      log("web3: disconnected");
    });

    _contextChanged();
    log("new context = $_context");
  }

  // Update the existing context on change of address or chain
  void _updateContext() async {
    if (_context.ethereumProvider != null) {
      _context =
          await OrchidWeb3Context.fromEthereum(_context.ethereumProvider);
    } else {
      _context = await OrchidWeb3Context.fromWalletConnect(
          _context.walletConnectProvider);
    }
    log("updated context = $_context");
    _contextChanged();
  }

  // The context was replaced or updated (wallet address, chain id, connection)
  void _contextChanged() async {
    _selectedAccountChanged();
    OrchidEthereumV1.setWeb3Provider(OrchidEthereumV1Web3Impl(_context));
    setState(() {});
  }

  _dismissTransaction(String txHash) {
    UserPreferences().removeTransaction(txHash);
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
