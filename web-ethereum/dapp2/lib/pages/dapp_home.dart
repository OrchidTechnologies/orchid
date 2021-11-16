import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
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

class Web3Context {
  final Web3Provider provider;
  final Chain chain;
  final EthereumAddress wallet;

  /// If this web3 provider is from wallet connect this is the underlying provider.
  final WalletConnectProvider walletConnect;

  Web3Context({this.walletConnect, this.provider, this.chain, this.wallet});

  @override
  String toString() {
    return 'Web3Context{provider: $provider, chain: $chain, wallet: $wallet, walletConnect: $walletConnect}';
  }
}

class _DappHomeState extends State<DappHome> {
  Web3Context _context;
  var _pastedSignerField = TextEditingController();
  EthereumAddress _signer;
  AccountDetailPoller _accountDetail;

  @override
  void initState() {
    super.initState();
    _pastedSignerField.addListener(_textFieldChanged);
    initStateAsync();
  }

  void initStateAsync() async {}

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
    _updateAccount();
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

  void _updateAccount() {
    _clearAccountDetail();
    if (_signer != null && _context?.wallet != null) {
      var account = Account.fromSignerAddress(
        signerAddress: _signer,
        version: 0,
        funder: _context.wallet,
        chainId: _context.chain.chainId,
      );
      _accountDetail = AccountDetailPoller(account: account);
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
    return Column(
      children: [
        pady(32),
        _buildButtons(),
        AnimatedSwitcher(
          duration: Duration(seconds: 1),
          child: _connected
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(height: 40, child: _buildConnectedPane()),
                )
              : SizedBox(height: 48),
        ),
        pady(64),
        SizedBox(
            height: 180,
            width: 300,
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
        if (_accountDetail != null)
          AccountCard(
            accountDetail: _accountDetail,
            initiallyExpanded: true,
          ),
      ],
    );
  }

  Widget _buildConnectedPane() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 26, height: 27, child: _context.chain.icon),
        padx(16),
        Text(_context.chain.name).title,
        padx(16),
        OrchidCircularIdenticon(address: _context.wallet, size: 24),
        padx(16),
        SizedBox(
            width: 200,
            child: Text(
              _context.wallet.toString(),
              overflow: TextOverflow.ellipsis,
            ).title),
      ],
    );
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
        SizedBox(
          width: 500,
          child: OrchidTextField(
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
        ),
      ],
    );
  }

  Row _buildButtons() {
    var height = 42.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            height: height,
            child: RoundedRectButton(
              text: "Connect",
              textColor: Colors.black,
              lineHeight: 1.2,
              onPressed: _connected ? null : _connectEthereum,
            )),
        padx(24),
        Container(
          height: height,
          child: RoundedRectButton(
            onPressed: _connected ? null : _connectWalletConnect,
            text: "Wallet Connect",
            textColor: Colors.black,
            lineHeight: 1.2,
            trailing: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 16.0),
              child: Icon(Icons.qr_code, color: Colors.black),
            ),
          ),
        ),
        padx(24),
        Container(
            height: height,
            child: RoundedRectButton(
              text: "Disconnect",
              textColor: Colors.black,
              lineHeight: 1.2,
              onPressed: _connected ? _disconnect : null,
            )),
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
    final accounts = await ethereum.requestAccount();
    if (accounts.isNotEmpty) {
      _context = Web3Context(
          provider: Web3Provider.fromEthereum(ethereum),
          chain: Chains.chainFor(await ethereum.getChainId()),
          wallet: EthereumAddress.from(accounts.first));
      _updateAccount();
      setState(() {});
      log("context = $_context");
    }
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
    if (wc.accounts.isNotEmpty) {
      _context = Web3Context(
          walletConnect: wc,
          provider: Web3Provider.fromWalletConnect(wc),
          chain: Chains.chainFor(int.parse(wc.chainId)),
          wallet: EthereumAddress.from(wc.accounts.first));
      _updateAccount();
      setState(() {});
      log("context from wallet connect = $_context");
    }
  }

  void _disconnect() async {
    if (_context == null) {
      return;
    }

    // TODO: How do we close a plain eth provider?
    //_context.provider.call('close'); // ??
    _context.walletConnect?.disconnect();

    setState(() {
      _clearAccountDetail();
      _context = null;
    });
  }

  S get s {
    return S.of(context);
  }
}
