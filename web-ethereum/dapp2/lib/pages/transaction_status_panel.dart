import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/formatting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/on_off.dart';

class TransactionStatusPanel extends StatefulWidget {
  // TODO: persist this with the tx hashes
  final String description = "Orchid Transaction";

  final Function(String) onDismiss;
  final VoidCallback onCompletedTx;

  // final TransactionResponse tx;
  final OrchidWeb3Context context;
  final String transactionHash;

  const TransactionStatusPanel({
    Key key,
    @required this.context,
    @required this.transactionHash,
    @required this.onDismiss,
    this.onCompletedTx,
  }) : super(key: key);

  @override
  _TransactionStatusPanelState createState() => _TransactionStatusPanelState();
}

class _TransactionStatusPanelState extends State<TransactionStatusPanel> {
  TransactionReceipt _receipt;

  // Support onCompltedTx callback
  bool _txCompleteLastStatus;

  bool get _txComplete {
    if (widget.context == null) {
      return false;
    }
    return (_receipt?.confirmations ?? 0) >=
        widget.context.chain.requiredConfirmations;
  }

  Duration pollingPeriod = const Duration(seconds: 1);
  Timer _pollTimer;

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
      _receipt = await widget.context.web3
          .getTransactionReceipt(widget.transactionHash);
    }

    // Check for a change in tx complete status from false to true.
    if (_txCompleteLastStatus == false && _txComplete == true) {
      widget.onCompletedTx();
    }
    _txCompleteLastStatus = _txComplete;

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
    return _buildProgressIndicator();
  }

  // The spinner
  Column _buildProgressIndicator() {
    var message = _receipt != null
        ? "Confirmations: ${_receipt.confirmations}"
        : "Pending...";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(widget.description ?? "").body1,
        pady(16),
        if (!_txComplete)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OrchidCircularProgressIndicator.smallIndeterminate(size: 22),
          ),
        if (_receipt?.transactionHash != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
                width: 200,
                child: Row(
                  children: [
                    Text("Tx Hash: ").caption,
                    Expanded(
                      child: TapToCopyText(
                        _receipt.transactionHash,
                        overflow: TextOverflow.ellipsis,
                        style: OrchidText.caption,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )),
          ),
        Text(message ?? "").caption,
      ],
    );
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }
}
