import 'package:flutter/material.dart';
import 'package:flutter/src/services/clipboard.dart';
import 'package:orchid/api/etherscan_io.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class BalancePage extends StatefulWidget {
  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  double balance;
  List<LotteryPotUpdateEvent> events;

  @override
  void initState() {
    super.initState();
    OrchidAPI().budget().balance.listen((balance) {
      OrchidAPI().logger().write(("budget page got balance: $balance"));
      setState(() {
        this.balance = balance;
      });
    });
    OrchidAPI().budget().events.listen((events) {
      OrchidAPI().logger().write(("budget page got events: ${events.length}"));
      setState(() {
        this.events = events;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Transactions", child: buildPage(context));
  }

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
            color: Colors.lightGreen.withOpacity(0.2),
            child: ListTile(
              title: balance == null
                  ? Text('Loading...',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 18.0))
                  : Text('Balance: ${balance ?? ""}',
                      style: TextStyle(fontSize: 18.0)),
              trailing: FlatButton(
                color: Colors.white,
                child: Text("Add Funds"),
                onPressed: _copyURL,
              ),
            )),
        SizedBox(height: 8),
        Expanded(child: _buildList()),
      ],
    );
  }

  void _copyURL() async {
    String url = await OrchidAPI().budget().getFundingURL();
    Clipboard.setData(ClipboardData(text: url));
    Dialogs.showAppDialog(
        context: context,
        title: "Orchid URL Copied",
        body: "The Orchid Funding Dapp URL has been copied to the clipboard." +
            " Paste this URL into your crypto wallet's dapp browser to proceed with funding.\n");
  }

  Widget _buildList() {
    var subStyle = TextStyle(fontFamily: 'RobotoMono');
    return RefreshIndicator(
      onRefresh: () {
        return OrchidAPI().budget().poll();
      },
      child: ListView.builder(
        itemCount: events?.length ?? 0,
        itemBuilder: (context, index) {
          var event = events[index];
          return Card(
            child: ListTile(
                title: Text('Transaction: ${event.timeStamp}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Ending balance: ${event.balance}', style: subStyle),
                    Text("Tx hash: ${event.transactionHash}",
                        textAlign: TextAlign.left,
                        style: subStyle,
                        //overflow: TextOverflow.ellipsis
                    ),
                    Text("Block: ${event.blockNumber}", style: subStyle),
                    Text("Gas price: ${event.gasPrice}", style: subStyle),
                    Text("Gas used: ${event.gasUsed}", style: subStyle),
                  ],
                )),
          );
        },
      ),
    );
  }
}
