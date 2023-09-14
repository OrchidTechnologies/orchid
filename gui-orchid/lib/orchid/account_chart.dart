import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import '../common/loading.dart';
import '../common/formatting.dart';
import 'package:orchid/util/localization.dart';

class OrchidAccountChart extends StatelessWidget {
  final LotteryPot? lotteryPot;
  final double? efficiency;
  final List<OrchidUpdateTransactionV0>? transactions;
  final bool alignEnd;

  // Efficiency alert
  final bool alert;

  const OrchidAccountChart({
    Key? key,
    this.lotteryPot,
    this.efficiency,
    this.transactions,
    this.alert = false,
    this.alignEnd = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (efficiency == null) {
      return LoadingIndicator();
    }

    var chartModel = (lotteryPot != null && transactions != null)
        ? AccountBalanceChartTicketModel(lotteryPot!, transactions!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        pady(8),
        OrchidCircularEfficiencyIndicators.large(efficiency!),
        pady(16),
        Text(
            context.s.efficiency +
                ": " +
                MarketConditionsV0.efficiencyAsPercString(efficiency ?? 0),
            style: alert ? OrchidText.body1.red : OrchidText.body1),
        pady(16),
        // Show the tickets available / used line
        if (chartModel != null)
          buildTicketsAvailable(context, chartModel, efficiency, false),
      ],
    );
  }

  static Widget buildTicketsAvailable(
    BuildContext context,
    AccountBalanceChartTicketModel chartModel,
    double? efficiency,
    bool alignEnd,
  ) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        if (chartModel.availableTicketsCurrentMax > 0)
          buildTicketsAvailableLineChart(chartModel, efficiency).bottom(16),
        Text(
          context.s.minTicketsAvailableTickets(
              chartModel.availableTicketsCurrentMax),
        ).caption,
      ],
    );
  }

  // TODO: The glow is broken
  // Build the tickets available horizontal line chart
  // This consists of "dashed" segments indicating the number of tickets available
  // at the last high-water mark with a subset colored to indicate currently available.
  static Widget buildTicketsAvailableLineChart(
      AccountBalanceChartTicketModel chartModel, double? efficiency) {
    return SizedBox(
      width: 100,
      height: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // TODO: Why is this blur not working?
          // ImageFiltered(
          //   imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          //   child: buildTicketsAvailableLineChart(chartModel,
          //       color: OrchidCircularEfficiencyIndicators.colorForEfficiency(
          //           efficiency)),
          // ),
          _buildTicketsAvailableLineChart(chartModel,
              color: efficiency == null
                  ? Colors.white
                  : OrchidCircularEfficiencyIndicators.colorForEfficiency(
                      efficiency)),
        ],
      ),
    );
  }

  static Widget _buildTicketsAvailableLineChart(
      AccountBalanceChartTicketModel chartModel,
      {Color color = OrchidColors.purpleCaption}) {
    var totalCount = chartModel.availableTicketsHighWatermarkMax;
    var currentCount = chartModel.availableTicketsCurrentMax;

    // double margin = totalCount < 10 ? 8 : 2;
    // if (totalCount > 20) {
    //   margin = 0;
    // }
    var colorFor = (int i) => i < currentCount ? color : Color(0xff766D86);
    return Padding(
      // padding: const EdgeInsets.only(left: 8, right: 8),
      padding: EdgeInsets.zero,
      child: Row(
          children: List.generate(
        totalCount,
        (i) => Flexible(
          child: Container(
            color: colorFor(i),
          ),
        ),
      ).toList()),
    );
  }
}

class AccountBalanceChartTicketModel {
  final LotteryPot pot;
  final List<OrchidUpdateTransactionV0> transactions;

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
