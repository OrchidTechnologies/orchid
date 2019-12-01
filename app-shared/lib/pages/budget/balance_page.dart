import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/clipboard.dart';
import 'package:intl/intl.dart';
import 'package:orchid/api/etherscan_io.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/budget/budget_page.dart';
import 'package:orchid/pages/budget/budget_summary_tile.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/util/units.dart';

import '../app_colors.dart';
import '../app_text.dart';


class BalancePage extends StatefulWidget {
  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  Pricing _pricing;
  Budget _budget;
  LotteryPot _pot;
  List<LotteryPotUpdateEvent> _events;
  List<StreamSubscription> _subscriptions = List();

  @override
  void initState() {
    super.initState();

    ScreenOrientation.portrait();

    OrchidAPI().pricing().getPricing().then((pricing) {
      setState(() {
        _pricing = pricing;
      });
    });
    /*
    OrchidAPI().budget().getBudget().then((budget) {
      setState(() {
        _budget = budget;
      });
    });
    _subscriptions.add(OrchidAPI().budget().potStatus.listen((balance) {
      OrchidAPI().logger().write(("budget page got balance: $balance"));
      setState(() {
        this._pot = balance;
      });
    }));
    _subscriptions.add(OrchidAPI().budget().fundingEvents.listen((events) {
      OrchidAPI().logger().write(("budget page got events: ${events.length}"));
      setState(() {
        this._events = events;
      });
    }));
     */
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: buildPage(context),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.grey_7, AppColors.grey_6])),
    );
  }

  Widget buildPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 16, bottom: 16),
      child: Column(
        children: <Widget>[
          pady(16),
          _buildCardView(oxtValue: _pot?.balance),
          pady(16),
          /*
          BudgetSummaryTile(
              image: "assets/images/creditCard.png",
              title: "MONTHLY\nBUDGET",
              oxtValue: _budget?.spendRate,
              pricing: _pricing,
              detail: () {
                _showSubscriptionPage();
              }),
          _divider(),
          */
          BudgetSummaryTile(
            image: "assets/images/pig.png",
            title: "MEMBERSHIP\nDEPOSIT",
            //oxtValue: _budget?.deposit,
            oxtValue: _pot?.deposit,
            pricing: _pricing,
          ),
          _divider(),
          /*
          BudgetSummaryTile(
            image: "assets/images/accountBalanceWallet.png",
            title: "REMAINING\nBALANCE",
            oxtValue: _pot?.balance,
            pricing: _pricing,
          ),
           */
          _divider(),
          pady(30),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  Widget _buildCardView({OXT oxtValue}) {
    var oxtString = oxtValue?.value?.toStringAsFixed(2) ?? "";
    var usdString = _pricing?.toUSD(oxtValue)?.value?.toStringAsFixed(2) ?? "";

    const valueStyle = TextStyle(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.38,
        fontFamily: "SFProText-Regular",
        height: 25.0 / 20.0);
    const valueSubtitleStyle = TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        //letterSpacing: 0.07,
        fontFamily: "SFProText-Regular",
        height: 16.0 / 12.0);

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      child: Container(
        // fixing the size here to maintain the layout proportions
        width: 315,
        height: 198,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: AppGradients.purpleL3BlueL3Gradient,
          image: DecorationImage(
              image: AssetImage("assets/images/plant.png"),
              alignment: Alignment(0.7, 1.0)),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.9),
                offset: Offset(0.0, 8.0),
                blurRadius: 11.0)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              // top row
              Row(
                children: <Widget>[
                  Image.asset("assets/images/oxtOval.png"),
                  Spacer(),
                  Text(
                    "ORCHID TOKENS",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.0, color: Colors.white),
                  )
                ],
              ),
              Spacer(),
              // bottom row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: <Widget>[
                            Text(oxtString,
                                style: valueStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Text(" OXT", style: valueStyle),
                          ],
                        ),
                        Visibility(
                          visible: _pricing != null && usdString != "",
                          child: Column(
                            children: <Widget>[
                              pady(2),
                              Text("\$$usdString USD",
                                  style: valueSubtitleStyle),
                            ],
                          ),
                        ),
                      ]),
                  Spacer(),
                  Text(
                    "BALANCE",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.0, color: Colors.white),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsListPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 24, bottom: 16),
      child: Opacity(
        opacity: 0.7,
        child: Text('Transactions will appear here.',
            textAlign: TextAlign.center,
            style:
                AppText.textLabelStyle.copyWith(fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildTransactionsList() {
    //  Return the placeholder if no transactions
    if ((_events?.length ?? 0) == 0) {
      return _buildTransactionsListPlaceholder();
    }

    return ((RefreshIndicator(
      onRefresh: () {
        //return OrchidAPI().budget().poll();
        return Future<void>(null);
      },
      // Note: The design anticipates sortable DataTable here, but I'm
      // Note: starting with a plain list for now.
      child: ListView.builder(
        itemCount: (_events?.length ?? 0) + 1 /*header*/,
        itemBuilder: (context, index) {
          return index == 0
              ? _buildTransactionHeaderRow()
              : _buildTransactionRow(_events[index - 1]);
        },
      ),
    )));
  }

  Widget _buildTransactionHeaderRow() {
    var style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.07,
        color: Color(0xff3a3149));
    return _layoutTransactionRow(
      Text("AMOUNT", style: style),
      Text("DATE", style: style),
      Text("TRANSACTION HASH", style: style),
    );
  }

  Widget _buildTransactionRow(LotteryPotUpdateEvent event) {
    var style = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.0,
        color: Color(0xff766d86));

    var date = DateFormat("MM/dd/yyyy").format(event.timeStamp);
    return _layoutTransactionRow(
      // TODO: Should be amount, not balance.
      Text("${event.balance.value.toStringAsFixed(2)} OXT",
          style: style.copyWith(fontWeight: FontWeight.bold)),
      Text(date, style: style),
      LinkText(event.transactionHash,
          url: "https://etherscan.io/tx/${event.transactionHash}",
          style: style.copyWith(decoration: TextDecoration.underline),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _layoutTransactionRow(Widget col1, Widget col2, Widget col3,
      {AlignmentGeometry alignment = Alignment.centerLeft}) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 16.0),
      child: Row(children: [
        Container(alignment: alignment, width: 65, child: col1),
        padx(23),
        Container(alignment: alignment, width: 75, child: col2),
        padx(23),
        Expanded(
          child: Container(alignment: alignment, width: 70, child: col3),
        ),
      ]),
    );
  }

  /// Generate a funding URL encoding the required balance and deposit amounts
  /// for the currently selected budget and current pot balances.
  Future<String> _generateFundingURL() async {
    if (_pot == null || _budget == null) {
      Dialogs.showAppDialog(
          context: context,
          title: "Error",
          body:
              "Unable to generate funding URL.  Waiting for balance or budget data.");
      return null;
    }

    // Any additional spendable funding needed beyond current balance
    double budgetFundAmount = max(
        0, (_budget.spendRate.value * _budget.term.value) - _pot.balance.value);

    // Any additional deposit funding needed beyond current deposit
    double depositFundAmount = max(0, _budget.deposit.value - _pot.deposit.value);

    OrchidAPI().logger().write("Budget to fund: $budgetFundAmount, Deposit to fund: $depositFundAmount");

    if (budgetFundAmount == 0 && depositFundAmount == 0) {
      Dialogs.showAppDialog(
          context: context,
          title: "No Funding Needed",
          body:
              "Your current balance and deposit are sufficient for your selected budget.");
      return null;
    }

    //return OrchidAPI().budget().getFundingURL(
        //amount: OXT(budgetFundAmount), deposit: OXT(depositFundAmount));
    return "https://";
  }

  void _copyFundingURLToClipboard() async {
    String url = await _generateFundingURL();
    // If the funding url is null nothing to do here.
    if (url == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: url));
    Dialogs.showAppDialog(
        context: context,
        title: "Orchid URL Copied",
        body: "The Orchid Funding Dapp URL has been copied to the clipboard." +
            " Paste this URL into your crypto wallet's dapp browser to proceed with funding.\n");
  }

  Widget _divider() {
    return Container(height: 0.5, color: Color(0xffcac9ce));
  }

  // Optionally place this into the header as an action.
  Widget _buildAddFundsButton() {
    return FlatButton(
      color: Colors.transparent,
      child: Text("Add Funds",
          style: TextStyle(
              fontSize: 17.0,
              height: 22.0 / 17.0,
              letterSpacing: -0.41,
              color: Color(0xff5f45ba))),
      onPressed: _copyFundingURLToClipboard,
    );
  }

  void _showSubscriptionPage() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return BudgetPage();
    }));
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _subscriptions.forEach((sub) {
      sub.cancel();
    });
  }
}
