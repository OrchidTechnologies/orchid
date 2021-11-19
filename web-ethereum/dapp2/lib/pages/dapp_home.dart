import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
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

  final _pastedSignerField = TextEditingController();
  final TextEditingController _addFundsField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pastedSignerField.addListener(_textFieldChanged);
    _addFundsField.addListener(_textFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {
    // TODO: TESTING
    /*
    await Future.delayed(Duration(seconds: 0), () {
      _connectEthereum();
      _signer =
          EthereumAddress.from('0x5eea55E63a62138f51D028615e8fd6bb26b8D354');
      _pastedSignerField.text = _signer.toString();
    });
     */
  }

  bool get _connected {
    return _context != null;
  }

  void _textFieldChanged() {
    try {
      _signer = EthereumAddress.from(_pastedSignerField.text);
      log("signer = $_signer");
    } catch (err) {
      _signer = null;
    }
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

  void _walletAddressChanged() async {
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
    return Column(
      children: [
        pady(32),
        _buildButtons(),
        AnimatedSwitcher(
          duration: Duration(seconds: 1),
          child: _connected
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(height: 40, child: _buildWalletPane()),
                )
              : SizedBox(height: 48),
        ),
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
        SizedBox(
          width: 500,
          child: Column(
            children: [
              if (_connected) _buildPasteSignerField(),
              pady(40),
              if (_accountDetail != null)
                AccountCard(
                  accountDetail: _accountDetail,
                  initiallyExpanded: true,
                ),
              pady(40),
              if (_connected && _signer != null)
                Divider(
                  color: Colors.white.withOpacity(0.3),
                ),
              pady(32),
              if (_connected && _signer != null) _buildAddFunds(),
            ],
          ),
        ),
      ],
    );
  }

  // the value or null
  Token _addFundsAmount() {
    try {
      var value = double.parse(_addFundsField.text);
      return _wallet.balance.type.fromDouble(value);
    } catch (err) {
      return null;
    }
  }

  bool get _addFundsFieldValid {
    var amount = _addFundsAmount();
    return amount != null && amount < _wallet.balance;
  }

  void _addFunds() async {
    if (!_addFundsFieldValid) {
      return;
    }
    var amount = _addFundsAmount();
    var tx = await OrchidWeb3V1(_context).orchidAddFunds(
      wallet: _wallet,
      signer: _signer,
      addBalance: amount,
      addEscrow: amount.type.zero,
    );
    log("tx = $tx");
  }

  Widget _buildAddFunds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text("Add Funds:").title,
        ),
        pady(12),
        Row(
          children: [
            Flexible(
              child: OrchidTextField(
                hintText: '0.0',
                margin: EdgeInsets.zero,
                controller: _addFundsField,
                numeric: true,
              ),
            ),
            // padx(4),
            Text(_wallet?.balance?.type?.symbol ?? "").button.height(1.5),
            padx(16),
            _buildButton(
                text: "Add", onPressed: _addFundsFieldValid ? _addFunds : null),
          ],
        ),
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
          controller: _pastedSignerField,
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

  Row _buildButtons() {
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

    _walletAddressChanged();
    setState(() {});
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
    _walletAddressChanged();
    log("updated context = $_context");
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
