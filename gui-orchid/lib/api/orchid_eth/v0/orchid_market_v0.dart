import 'dart:math';

import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/util/units.dart';

import '../../pricing/orchid_pricing_v0.dart';
import '../orchid_market.dart';
import '../chains.dart';
import '../token_type.dart';
import 'orchid_contract_v0.dart';

// Market conditions for the V0 contract where payment is in OXT with gas in ETH.
class MarketConditionsV0 implements MarketConditions {
  final ETH ethGasCostToRedeem;
  final OXT costToRedeem;
  final OXT maxFaceValue;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditionsV0(this.ethGasCostToRedeem, this.costToRedeem,
      this.maxFaceValue, this.efficiency, this.limitedByBalance);

  static String efficiencyAsPercString(double efficiency) {
    return (efficiency * 100.0).toStringAsFixed(2) + '%';
  }

  // TODO: Add refresh option
  static Future<MarketConditionsV0> forPotV0(LotteryPot pot) async {
    // TODO: Add refresh option
    return forBalanceV0(pot.balance, pot.effectiveDeposit);
  }

  // TODO: Add refresh option
  static Future<MarketConditionsV0> forBalanceV0(
      OXT balance, OXT escrow) async {
    // log("eth v0: Fetch market conditions");
    // TODO: Add refresh option
    var costToRedeem = await getCostToRedeemTicketV0();
    var limitedByBalance = balance.floatValue <= (escrow / 2.0).floatValue;
    Token maxFaceValue = LotteryPot.maxTicketFaceValueFor(balance, escrow);

    // value received as a fraction of ticket face value
    double efficiency = maxFaceValue.floatValue == 0
        ? 0
        : max(
                0,
                (maxFaceValue - costToRedeem.oxtCostToRedeem).floatValue /
                    maxFaceValue.floatValue)
            .toDouble();

    return new MarketConditionsV0(
        costToRedeem.gasCostToRedeem,
        costToRedeem.oxtCostToRedeem,
        maxFaceValue,
        efficiency,
        limitedByBalance);
  }

  // TODO: Add refresh option
  static Future<CostToRedeemV0> getCostToRedeemTicketV0() async {
    // TODO: Add refresh option
    PricingV0 pricing = await OrchidPricingAPIV0().getPricing();
    GWEI gasPrice =
        GWEI.fromWei((await Chains.Ethereum.getGasPrice()).intValue);
    ETH ethGasCostToRedeem =
        (gasPrice * OrchidContractV0.gasCostToRedeemTicketV0).toEth();
    OXT oxtCostToRedeem = pricing.ethToOxt(ethGasCostToRedeem);
    return CostToRedeemV0(ethGasCostToRedeem, oxtCostToRedeem);
  }

  @override
  String toString() {
    return 'MarketConditionsV0{ethGasCostToRedeem: $ethGasCostToRedeem, oxt costToRedeem: $costToRedeem, maxFaceValue: $maxFaceValue, efficiency: $efficiency, limitedByBalance: $limitedByBalance}';
  }
}

class CostToRedeemV0 {
  ETH gasCostToRedeem;
  OXT oxtCostToRedeem;

  CostToRedeemV0(this.gasCostToRedeem, this.oxtCostToRedeem);
}
