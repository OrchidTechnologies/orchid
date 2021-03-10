import 'dart:math';

import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/util/units.dart';

import '../../pricing/orchid_pricing_v0.dart';
import '../token_type.dart';
import 'orchid_contract_v0.dart';
import 'orchid_eth_v0.dart';

class MarketConditions {
  final Token maxFaceValue;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditions(this.maxFaceValue, this.efficiency, this.limitedByBalance);
}

class MarketConditionsV0 implements MarketConditions {

  final ETH ethGasCostToRedeem;
  final OXT oxtCostToRedeem;
  final OXT maxFaceValue;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditionsV0(this.ethGasCostToRedeem, this.oxtCostToRedeem,
      this.maxFaceValue, this.efficiency, this.limitedByBalance);

  static String efficiencyAsPercString(double efficiency) {
    return (efficiency * 100.0).toStringAsFixed(2) + "%";
  }

  static Future<MarketConditionsV0> forPot(OXTLotteryPot pot) async {
    return forBalance(pot.balance, pot.deposit);
  }

  static Future<MarketConditionsV0> forBalance(OXT balance, OXT escrow) async {
    log("fetch market conditions");
    var costToRedeem = await getCostToRedeemTicket();
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

  static Future<CostToRedeemV0> getCostToRedeemTicket() async {
    PricingV0 pricing = await OrchidPricingAPIV0().getPricing();
    GWEI gasPrice = await OrchidEthereumV0().getGasPrice();
    ETH gasCostToRedeem =
        (gasPrice * OrchidContractV0.gasCostToRedeemTicketV0).toEth();
    OXT oxtCostToRedeem = pricing.ethToOxt(gasCostToRedeem);
    return CostToRedeemV0(gasCostToRedeem, oxtCostToRedeem);
  }

  /// Calculate the current real world value of the largest ticket that can be
  /// issued from this lottery pot, taking into account the amount of gas required
  /// to redeem the ticket, current gas prices, and the OXT-ETH exchange rate.
  /// Returns the net value in OXT, which may be zero or negative if the ticket
  /// would be unprofitable to redeem.
  static Future<OXT> getMaxTicketValueV0(OXTLotteryPot pot) async {
    CostToRedeemV0 costToRedeem = await getCostToRedeemTicket();
    var oxtCostToRedeem = costToRedeem.oxtCostToRedeem;
    OXT maxTicketFaceValue = pot.maxTicketFaceValue;
    return maxTicketFaceValue - oxtCostToRedeem;
  }
}

class CostToRedeemV0 {
  ETH gasCostToRedeem;
  OXT oxtCostToRedeem;

  CostToRedeemV0(this.gasCostToRedeem, this.oxtCostToRedeem);
}
