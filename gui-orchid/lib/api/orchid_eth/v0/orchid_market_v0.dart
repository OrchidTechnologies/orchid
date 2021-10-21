import 'dart:math';

import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/util/units.dart';

import '../../pricing/orchid_pricing_v0.dart';
import '../token_type.dart';
import 'orchid_contract_v0.dart';

class MarketConditions {
  final Token maxFaceValue;
  final Token costToRedeem;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditions(
    this.maxFaceValue,
    this.costToRedeem,
    this.efficiency,
    this.limitedByBalance,
  );

  static bool isBelowMinEfficiency(MarketConditions conditions) {
    return (conditions.efficiency ?? 0) < minEfficiency;
  }

  static double minEfficiency = 0.2;
}

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
    return (efficiency * 100.0).toStringAsFixed(2) + "%";
  }

  // TODO: Add refresh option
  static Future<MarketConditionsV0> forPotV0(OXTLotteryPot pot) async {
    // TODO: Add refresh option
    return forBalanceV0(pot.balance, pot.deposit);
  }

  // TODO: Add refresh option
  static Future<MarketConditionsV0> forBalanceV0(
      OXT balance, OXT escrow) async {
    log("fetch market conditions");
    // TODO: Add refresh option
    var costToRedeem = await getCostToRedeemTicketV0();
    var limitedByBalance = balance.floatValue <= (escrow / 2.0).floatValue;
    OXT maxFaceValue = OXTLotteryPot.maxTicketFaceValueFor(balance, escrow);

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
    GWEI gasPrice = GWEI.fromWei((await Chains.Ethereum.getGasPrice()).intValue);
    ETH gasCostToRedeem =
        (gasPrice * OrchidContractV0.gasCostToRedeemTicketV0).toEth();
    OXT oxtCostToRedeem = pricing.ethToOxt(gasCostToRedeem);
    return CostToRedeemV0(gasCostToRedeem, oxtCostToRedeem);
  }
}

class CostToRedeemV0 {
  ETH gasCostToRedeem;
  OXT oxtCostToRedeem;

  CostToRedeemV0(this.gasCostToRedeem, this.oxtCostToRedeem);
}
