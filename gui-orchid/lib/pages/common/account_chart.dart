import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'loading.dart';

class AccountChart extends StatelessWidget {
  final LotteryPot lotteryPot;
  final double efficiency;
  final List<OrchidUpdateTransactionV0> transactions;

  const AccountChart({
    Key key,
    @required this.lotteryPot,
    @required this.efficiency,
    @required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildAccountChart(context, lotteryPot, efficiency, transactions);
  }

  static Widget buildAccountChart(BuildContext context, LotteryPot lotteryPot,
      double efficiency, List<OrchidUpdateTransactionV0> transactions) {
    if (efficiency == null) {
      return LoadingIndicator();
    }

    var chartModel = (lotteryPot != null && transactions != null)
        ? AccountBalanceChartTicketModel(lotteryPot, transactions)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        circularEfficiencyChart(efficiency),
        pady(2),
        Text(S.of(context).efficiency +
            ": " +
            MarketConditionsV0.efficiencyAsPercString(efficiency)),
        pady(16),
        // Show the tickets available / used line
        if (chartModel != null)
          Column(
            children: [
              buildTicketsAvailableLineChart(chartModel),
              pady(8),
              Text(
                S.of(context).minTicketsAvailableTickets(chartModel.availableTicketsCurrentMax),
              ),
            ],
          ),
      ],
    );
  }

  static CircularPercentIndicator circularEfficiencyChart(double efficiency) {
    return CircularPercentIndicator(
      progressColor: Colors.deepPurple,
      lineWidth: 10,
      radius: 70,
      percent: efficiency,
    );
  }

  // Build the tickets available horizontal line chart
  // This consists of "dashed" segments indicating the number of tickets available
  // at the last high-water mark with a subset colored to indicate currently available.
  static Widget buildTicketsAvailableLineChart(
      AccountBalanceChartTicketModel chartModel) {
    var totalCount = chartModel.availableTicketsHighWatermarkMax;
    var currentCount = chartModel.availableTicketsCurrentMax;

    double margin = totalCount < 10 ? 8 : 2;
    var colorFor =
        (int i) => i < currentCount ? Colors.deepPurple : Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Row(
          children: List.generate(
        totalCount,
        (i) => Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: margin),
            height: 10,
            color: colorFor(i),
          ),
        ),
      ).toList()),
    );
  }
}

class AccountBalanceChartTicketModel {
  LotteryPot pot;
  List<OrchidUpdateTransactionV0> transactions;

  AccountBalanceChartTicketModel(this.pot, this.transactions);

  // The number of tickets that could be written using the max possible face value
  int get availableTicketsCurrentMax {
    return pot.maxTicketFaceValue.lteZero()
        ? 0
        : (pot.balance.floatValue / pot.maxTicketFaceValue.floatValue).floor();
  }

  // The number of tickets that could be written using the max possible face value
  // at the time of the last high-water mark
  int get availableTicketsHighWatermarkMax {
    return pot.maxTicketFaceValue.floatValue == 0
        ? 0
        : (_lastBalanceHighWatermark.floatValue /
                pot.maxTicketFaceValue.floatValue)
            .floor();
  }

  // The last balance resulting from user actions other than a payment
  // i.e. the last time the user topped up or made a withdrawal.
  Token get _lastBalanceHighWatermark {
    var balanceAdjustments = this
        .transactions
        .where((OrchidUpdateTransactionV0 utx) => !utx.tx.isPayment)
        .toList();
    return balanceAdjustments.isNotEmpty
        ? balanceAdjustments.last.update.endBalance
        : pot.balance;
  }
}
