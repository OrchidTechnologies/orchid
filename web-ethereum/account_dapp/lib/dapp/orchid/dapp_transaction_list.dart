import 'dart:math';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/dapp/orchid/transaction_status_panel.dart';

// Show pending and recent transactions in the dapp.
// The side scrolling page view of transaction status panels.
class DappTransactionList extends StatefulWidget {
  final OrchidWeb3Context? web3Context;
  final VoidCallback refreshUserData;
  final double width;

  const DappTransactionList({
    super.key,
    this.web3Context,
    required this.refreshUserData,
    required this.width,
  });

  @override
  State<DappTransactionList> createState() => _DappTransactionListState();
}

class _DappTransactionListState extends State<DappTransactionList> {
  int _txStatusIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _buildTransactionsList();
  }

  // The transactions list monitors transaction progress of pending transactions.
  Widget _buildTransactionsList() {
    return UserPreferencesDapp().transactions.builder((txs) {
      // Limit to currently selected chain
      txs = (txs ?? [])
          .where((tx) => tx.chainId == widget.web3Context?.chain.chainId)
          .toList();

      // REMOVE: TESTING
      // txs = txs + txs + txs + txs;

      // REMOVE: TESTING
      // txs += [
      //   DappTransaction(
      //     transactionHash: "0x10942af0a19066e4c27b1eb6c8a7edd2e7f76a68ac147384786ee6b5fd02e78f",
      //     chainId: Chains.GNOSIS_CHAINID,
      //     type: DappTransactionType.addFunds,
      //     subtype: "approve",
      //     series_index: 1,
      //     series_total: 2,
      //   ),
      //   DappTransaction(
      //     transactionHash: "0x10942af0a19066e4c27b1eb6c8a7edd2e7f76a68ac147384786ee6b5fd02e78f",
      //     chainId: Chains.GNOSIS_CHAINID,
      //     type: DappTransactionType.addFunds,
      //     subtype: "push",
      //     series_index: 2,
      //     series_total: 2,
      //   ),
      // ];

      if (txs.isEmpty) {
        return Container();
      }

      var txWidgets = txs
          .map((tx) => TransactionStatusPanel(
                context: widget.web3Context,
                tx: tx,
                onDismiss: _dismissTransaction,
                onTransactionUpdated: () {
                  widget.refreshUserData();
                },
              ))
          .toList()
          // show latest first
          .reversed
          .toList();

      final colWidth = min(MediaQuery.of(context).size.width, widget.width);
      var viewportFraction = min(0.75, 334 / colWidth);

      return AnimatedSwitcher(
        duration: millis(400),
        child: SizedBox(
          height: 180,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent, // Start fully transparent (left side)
                  Colors.black, // Fully visible in the middle
                  Colors.black, // Fully visible in the middle
                  Colors.transparent, // End fully transparent (right side)
                ],
                stops: [
                  0.0,
                  0.2,
                  0.8,
                  1.0
                ], // Adjust stops to control fade amount
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn, // Use blend mode for transparency
            child: PageView.builder(
              itemCount: txWidgets.length,
              controller: PageController(viewportFraction: viewportFraction),
              onPageChanged: (int index) =>
                  setState(() => _txStatusIndex = index),
              itemBuilder: (_, i) {
                return AnimatedScale(
                  duration: millis(300),
                  scale: i == _txStatusIndex ? 1 : 0.9,
                  child: Center(child: txWidgets[i]),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _dismissTransaction(String? txHash) {
    if (txHash != null) {
      UserPreferencesDapp().removeTransaction(txHash);
    }
  }
}
