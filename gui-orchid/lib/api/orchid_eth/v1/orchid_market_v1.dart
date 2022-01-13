import 'dart:math';

import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import '../chains.dart';
import '../token_type.dart';
import 'orchid_contract_v1.dart';
import 'orchid_eth_v1.dart';

// Market conditions for V1 contracts where payment is in the ETH-like native
// token that is also used for gas.
class MarketConditionsV1 implements MarketConditions {
  final Token maxFaceValue;
  final Token costToRedeem;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditionsV1(
    this.maxFaceValue,
    this.costToRedeem,
    this.efficiency,
    this.limitedByBalance,
  );

  static Future<MarketConditions> forPot(LotteryPot pot,
      {bool refresh = false}) async {
    return forBalance(pot.balance, pot.effectiveDeposit, refresh: refresh);
  }

  static Future<MarketConditions> forBalance(Token balance, Token escrow,
      {bool refresh = false}) async {
    // Infer the chain from the balance token type.
    Chain chain = balance.type.chain;
    var costToRedeem = await getCostToRedeemTicket(chain, refresh: refresh);
    var limitedByBalance = balance.floatValue <= (escrow / 2.0).floatValue;
    var maxFaceValue = LotteryPot.maxTicketFaceValueFor(balance, escrow);

    // value received as a fraction of ticket face value
    double efficiency = maxFaceValue.floatValue == 0
        ? 0
        : max(
                0,
                (maxFaceValue - costToRedeem).floatValue /
                    maxFaceValue.floatValue)
            .toDouble();

    //log("market conditions for: $balance, $escrow, costToRedeem = $costToRedeem, maxFaceValue=$maxFaceValue");
    return new MarketConditionsV1(
        maxFaceValue, costToRedeem, efficiency, limitedByBalance);
  }

  static Future<Token> getCostToRedeemTicket(Chain chain,
      {bool refresh = false}) async {
    Token gasPrice =
        await OrchidEthereumV1().getGasPrice(chain, refresh: refresh);
    //log("gas price for chain: ${chain.name} = ${gasPrice.intValue}");
    return gasPrice * OrchidContractV1.gasCostToRedeemTicket.toDouble();
  }

  /// Determine the pot composition and gas required for the desired
  /// efficiency and return the total tokens.
  // TODO: If we use non-native tokens in the future with v1 we will have to update this.
  static Future<Token> getCostToCreateAccount({
    Chain chain,
    double efficiency,
    int tickets,
  }) async {
    if (efficiency < 0 || efficiency >= 1.0) {
      throw Exception("invalid efficiency: $efficiency");
    }
    final requiredTicketValue =
        await getCostToRedeemTicket(chain) / (1 - efficiency);
    final requiredDeposit = requiredTicketValue * 2.0;
    final requiredBalance = requiredTicketValue * tickets.toDouble();
    final requiredGas = await chain.getGasPrice() *
        OrchidContractV1.createAccountMaxGas.toDouble();
    log("XXX: getCostToCreateAccount for ${chain.name}: $requiredTicketValue, $requiredDeposit, $requiredBalance, $requiredGas");
    return requiredDeposit + requiredBalance + requiredGas;
  }

  @override
  String toString() {
    return 'MarketConditions{maxFaceValue: $maxFaceValue, efficiency: $efficiency, limitedByBalance: $limitedByBalance}';
  }
}
