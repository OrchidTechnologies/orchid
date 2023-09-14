import 'dart:math';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/dapp/orchid/transaction_status_panel.dart';

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
      if (txs.isEmpty) {
        return Container();
      }

      // REMOVE: TESTING
      // txs = txs + txs + txs + txs;

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

  void _dismissTransaction(String? txHash) {
    if (txHash != null) {
      UserPreferencesDapp().removeTransaction(txHash);
    }
  }
}
