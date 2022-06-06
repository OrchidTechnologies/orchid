import 'package:orchid/orchid.dart';
import 'dart:async';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/pages/dapp_wallet_info_panel.dart';

class TransactionStatusPanel extends StatefulWidget {
  final Function(String) onDismiss;
  final VoidCallback onTransactionUpdated;

  // final TransactionResponse tx;
  final OrchidWeb3Context context;
  final String transactionHash;

  const TransactionStatusPanel({
    Key key,
    @required this.context,
    @required this.transactionHash,
    @required this.onDismiss,
    this.onTransactionUpdated,
  }) : super(key: key);

  @override
  _TransactionStatusPanelState createState() => _TransactionStatusPanelState();
}

class _TransactionStatusPanelState extends State<TransactionStatusPanel> {
  TransactionReceipt _receipt;

  bool get _txComplete {
    if (widget.context == null) {
      return false;
    }
    return (_receipt?.confirmations ?? 0) >=
        widget.context.chain.requiredConfirmations;
  }

  Duration pollingPeriod = const Duration(seconds: 1);
  Timer _pollTimer;

  int get confirmations {
    return _receipt?.confirmations ?? 0;
  }

  // Support onTransactionUpdated callback
  int _lastConfirmationCount;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _pollTimer = Timer.periodic(pollingPeriod, _poll);
    _poll(null);
  }

  void _poll(_) async {
    if (widget.context?.web3 != null && widget.transactionHash != null) {
      try {
        _receipt = await widget.context.web3
            .getTransactionReceipt(widget.transactionHash);
      } catch (err) {
        log("Error fetching transaction receipt for ${widget.transactionHash}");
      }
    }

    // Update listeners on first update or change in confirmation count.
    if (_lastConfirmationCount == null ||
        confirmations > _lastConfirmationCount) {
      widget.onTransactionUpdated();
    }
    _lastConfirmationCount = confirmations;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.context == null) {
      return Container();
    }
    return SizedBox(width: 334.0, child: _buildStatusContainer());
  }

  Widget _buildStatusContainer() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: OrchidColors.dark_background,
          ),
          padding: EdgeInsets.all(16),
          child: _buildStatus(),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            iconSize: 18,
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              widget.onDismiss(widget.transactionHash);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    var message = _receipt != null
        ? s.confirmations + ': ${_receipt.confirmations}'
        : s.pending;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(s.orchidTransaction ?? '').body1,
        pady(16),
        if (!_txComplete)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OrchidCircularProgressIndicator.smallIndeterminate(size: 22),
          ),
        if (_receipt?.transactionHash != null)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.txHash).caption,
                  SizedBox(
                    width: 95,
                    child: TapToCopyText(
                      _receipt.transactionHash,
                      displayText: EthereumAddress.elideAddressString(
                          _receipt.transactionHash),
                      overflow: TextOverflow.ellipsis,
                      style: OrchidText.caption,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ).bottom(8),
              // DappWalletInfoPanel.buildExplorerLink(OrchidText.caption, link),
            ],
          ),
        Text(message ?? '').caption,
      ],
    );
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }
}
