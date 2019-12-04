import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'budget_summary_tile.dart';

class BudgetPage extends StatefulWidget {
  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<StreamSubscription> _rxSubscriptions = List();
  BudgetRecommendation _budgetRecommendation;
  Budget _budget;
  Pricing _pricing;
  LotteryPot _pot;

  @override
  void initState() {
    super.initState();
    ScreenOrientation.portrait();
    initStateAsync();
  }

  void initStateAsync() async {
    /*
    _rxSubscriptions.add(OrchidAPI().budget().potStatus.listen((pot) {
      setState(() {
        _pot = pot;
      });
    }));
    _budget = await OrchidAPI().budget().getBudget();
    _budgetRecommendation =
        await OrchidAPI().budget().getBudgetRecommendations();
    _pricing = await OrchidAPI().pricing().getPricing();
    setState(() {});
     */
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Budget",
      child: buildPage(context),
      lightTheme: true,
    );
  }

  Widget buildPage(BuildContext context) {
    const String bullet = "•";

    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 16, bottom: 16),
      child: Column(
        children: <Widget>[
          pady(8),
          _buildInstructions(),
          pady(16),
          BudgetSummaryTile(
            image: "assets/images/creditCard.png",
            title: "CURRENT\nBUDGET",
            oxtValue: _budget?.spendRate,
            pricing: _pricing,
            preserveIconSpace: false,
          ),
          pady(16),
          _buildBudgetCardView(
              budget: _budgetRecommendation?.lowUsage,
              title: "Low Usage",
              subtitle:
                  "$bullet Internet browsing\n$bullet Low video streaming",
              gradBegin: 0,
              gradEnd: 2),
          pady(24),
          _buildBudgetCardView(
              budget: _budgetRecommendation?.averageUsage,
              title: "Average Usage",
              subtitle:
                  "$bullet Internet browsing\n$bullet Moderate video streaming",
              gradBegin: -2,
              gradEnd: 1),
          pady(24),
          _buildBudgetCardView(
            budget: _budgetRecommendation?.highUsage,
            title: "High Usage",
            subtitle: "$bullet Video Streaming / calls\n$bullet Gaming",
            gradBegin: -1,
            gradEnd: -1,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontFamily: "SFProText-Semibold",
    );
    const subtitleStyle = TextStyle(
      color: Colors.grey,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      fontFamily: "SFProText-Semibold",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text("Choose your monthly plan", style: titleStyle),
        pady(16),
        Text("Based on your bandwidth usage", style: subtitleStyle),
      ],
    );
  }

  Widget _buildBudgetCardView(
      {Budget budget,
      String title,
      String subtitle,
      double gradBegin = 0.0,
      double gradEnd = 1.0}) {
    const titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFamily: "SFProText-Semibold",
        height: 22.0 / 17.0);
    const subtitleStyle = TextStyle(
      color: Colors.white,
      fontSize: 13.0,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.5,
      fontFamily: "SFProText-Semibold",
    );
    const valueStyle = TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.38,
        fontFamily: "SFProText-Regular",
        height: 25.0 / 20.0);
    const valueSubtitleStyle = TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        fontFamily: "SFProText-Regular",
        height: 16.0 / 12.0);

    var oxtString = budget?.spendRate?.toStringAsFixed(2) ?? "";
    var usdString =
        _pricing?.toUSD(budget?.spendRate ?? 0)?.toStringAsFixed(2) ?? "";

    Gradient grad = VerticalLinearGradient(
        begin: Alignment(0.0, gradBegin),
        end: Alignment(0.0, gradEnd),
        colors: [Color(0xff4e71c2), Color(0xff258993)]);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _selectBudget(newBudget: budget);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: grad,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Row(
            children: <Widget>[
              // left side usage description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: titleStyle,
                  ),
                  pady(8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.left,
                    style: subtitleStyle,
                  )
                ],
              ),
              Spacer(),
              // right side value display
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(
                  children: <Widget>[
                    Text("$oxtString",
                        style:
                            valueStyle.copyWith(fontWeight: FontWeight.bold)),
                    Text(" OXT", style: valueStyle),
                  ],
                ),
                pady(2),
                Visibility(
                  visible: _pricing != null,
                  child: Text("\$$usdString USD", style: valueSubtitleStyle),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _selectBudget({Budget newBudget}) {
    // selected same budget
    if (_pot == null) {
      Dialogs.showAppDialog(
          context: context,
          title: "Add Funds",
          body:
              "Please return to the balance screen and add funds to your account before selecting a budget.");
      return;
    }
    if (_pot == null || _pot.balance.value < newBudget.spendRate.value) {
      Dialogs.showAppDialog(
          context: context,
          title: "Add Funds",
          body:
              "Your current balance is too low to select that budget.  Please return to the balance screen and add funds before selecting this plan.");
      return;
    }
    Dialogs.showConfirmationDialog(
        context: context,
        title: "Confirm Budget Change",
        body:
            "Do you want to change your budget to ${newBudget.spendRate.toStringAsFixed(2)} OXT per month?",
        action: () {
          //OrchidAPI().budget().setBudget(newBudget);
          Navigator.of(context).pop();
        });
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _rxSubscriptions.forEach((sub) {
      sub.cancel();
    });
  }
}
