import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import '../preferences/dapp_transaction.dart';

class TransactionStatusPanel extends StatefulWidget {
  final DappTransaction tx;
  final OrchidWeb3Context? context;
  final VoidCallback onTransactionUpdated;
  final Function(String?) onDismiss;

  const TransactionStatusPanel({
    Key? key,
    required this.context,
    required this.tx,
    required this.onDismiss,
    required this.onTransactionUpdated,
  }) : super(key: key);

  @override
  _TransactionStatusPanelState createState() => _TransactionStatusPanelState();
}

class _TransactionStatusPanelState extends State<TransactionStatusPanel> {
  TransactionReceipt? _receipt;

  bool get _txComplete {
    if (widget.context == null) {
      return false;
    }
    return (_receipt?.confirmations ?? 0) >=
        widget.context!.chain.requiredConfirmations;
  }

  Duration pollingPeriod = const Duration(seconds: 1);
  Timer? _pollTimer;

  int get confirmations {
    return _receipt?.confirmations ?? 0;
  }

  // Support onTransactionUpdated callback
  int? _lastConfirmationCount;

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
    if (widget.context?.web3 != null && widget.tx.transactionHash != null) {
      try {
        _receipt = await widget.context!.web3
            .getTransactionReceipt(widget.tx.transactionHash!);
      } catch (err) {
        log("Error fetching transaction receipt for ${widget.tx.transactionHash}");
      }
    }

    // Update listeners on first update or change in confirmation count.
    if (_lastConfirmationCount == null ||
        confirmations > _lastConfirmationCount!) {
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
    return SizedBox(
        width: 334.0, child: IntrinsicHeight(child: _buildStatusContainer()));
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
              widget.onDismiss(widget.tx.transactionHash);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    // log("XXX: widget.tx = ${widget.tx}");
    var message = _receipt != null
        ? s.confirmations + ': ${_receipt!.confirmations}'
        : s.pending;

    final explorerLink = Chains.chainFor(widget.tx.chainId).explorerUrl;
    final description = widget.tx.description(context);

    return Column(
      children: <Widget>[
        Text(s.orchidTransaction).body1,
        pady(8),
        if (!_txComplete)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OrchidCircularProgressIndicator.smallIndeterminate(size: 22),
          ),
        if (_receipt?.transactionHash != null)
          Column(
            children: [
              // description
              Column(
                children: [
                  Text(description).subtitle.bottom(8),
                  SizedBox(
                      width: 100,
                      child:
                          Divider(height: 1, color: Colors.white).bottom(16)),
                ],
              ),

              // tx hash
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.txHash).caption,
                      SizedBox(
                        width: 95,
                        child: TapToCopyText(
                          // guarded above
                          _receipt!.transactionHash,
                          displayText: EthereumAddress.elideAddressString(
                              _receipt!.transactionHash),
                          overflow: TextOverflow.ellipsis,
                          style: OrchidText.caption.tappable,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ).bottom(8),

                  // confirmation status
                  Text(message).caption.bottom(12),
                ],
              ),

              // explorer link
              DappUtil.buildExplorerLink(
                context,
                OrchidText.caption.tappable,
                explorerLink,
                alignment: MainAxisAlignment.center,
                size: MainAxisSize.min,
                disabled: explorerLink == null,
              ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class DappUtil {
  static Widget buildExplorerLink(
    BuildContext context,
    TextStyle textStyle,
    String? link, {
    MainAxisAlignment alignment = MainAxisAlignment.start,
    MainAxisSize size = MainAxisSize.max,
    bool disabled = false,
  }) {
    final text =
        context.s.blockExplorer + (disabled ? ' (' + "unknown" + ')' : '');
    return Row(
      mainAxisSize: size,
      mainAxisAlignment: alignment,
      children: [
        Transform.rotate(
            angle: -3.14 / 4,
            child: Icon(Icons.arrow_forward,
                color: disabled ? OrchidColors.disabled : Colors.white)),
        Text(text, style: textStyle.disabledIf(disabled))
            .link(url: link!) // guarded by disabled
            .left(8),
      ],
    );
  }
}
