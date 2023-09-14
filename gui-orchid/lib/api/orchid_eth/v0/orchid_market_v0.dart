import 'dart:math';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/tokens_legacy.dart';
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
    return forBalanceV0(pot.balance as OXT, pot.effectiveDeposit as OXT);
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
        maxFaceValue as OXT,
        efficiency,
        limitedByBalance);
  }

  // TODO: Add refresh option
  static Future<CostToRedeemV0> getCostToRedeemTicketV0() async {
    // TODO: Add refresh option
    GWEI gasPrice =
        GWEI.fromWei((await Chains.Ethereum.getGasPrice()).intValue);
    ETH ethGasCostToRedeem =
        (gasPrice * OrchidContractV0.gasLimitToRedeemTicketV0).toEth();

    PricingV0? pricingV0 = await OrchidPricingAPIV0().getPricing();
    if (pricingV0 == null) {
      throw Exception("no pricing");
    }
    OXT oxtCostToRedeem = pricingV0.ethToOxt(ethGasCostToRedeem);

    // TODO: Migrate to v1
    // Token oxtCostToRedeem2 = await OrchidPricing().tokenToToken(
    //   Tokens.ETH.fromDouble(ethGasCostToRedeem.value),
    //   Tokens.OXT,
    // );

    return CostToRedeemV0(ethGasCostToRedeem, oxtCostToRedeem);
  }

  /// Determine the pot composition and gas required for the desired
  /// efficiency and return the total tokens.
  /*
  static Future<Token> getPotStats({
    double efficiency,
    int tickets,
  }) async {
    if (efficiency < 0 || efficiency >= 1.0) {
      throw Exception("invalid efficiency: $efficiency");
    }
    // Denominate all costs in OXT for the calcualtion.
    final requiredTicketValue =
        (await getCostToRedeemTicketV0()).oxtCostToRedeem / (1 - efficiency);
    final requiredDeposit = requiredTicketValue * 2.0;
    final requiredBalance = requiredTicketValue * tickets.toDouble();

    final pricing = await OrchidPricingAPIV0().getPricing();
    final gasPriceEth = await Chains.Ethereum.getGasPrice();
    final gasPriceOxt = pricing.ethToOxtToken(gasPriceEth);
    final requiredGas =
        gasPriceOxt * OrchidContractV0.gasCostCreateAccount.toDouble();

    log("XXX: getCostToCreateAccount V0: $requiredTicketValue, $requiredDeposit, $requiredBalance, $requiredGas");
    return requiredDeposit + requiredBalance + requiredGas;
  }
   */

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
