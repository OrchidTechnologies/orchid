import 'dart:math';

import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import '../token_type.dart';
import 'orchid_contract_v1.dart';
import 'orchid_eth_v1.dart';

// Market conditions for V1 contracts where payment is in the ETH-like native
// token that is also used for gas.
class MarketConditionsV1 implements MarketConditions {
  final Token maxFaceValue;
  final double efficiency;
  final bool limitedByBalance;

  MarketConditionsV1(this.maxFaceValue, this.efficiency, this.limitedByBalance);

  static Future<MarketConditions> forPot(LotteryPot pot) async {
    return forBalance(pot.balance, pot.deposit);
  }

  static Future<MarketConditions> forBalance(
      Token balance, Token escrow) async {
    // Infer the chain from the balance token type.
    Chain chain = balance.type.chain;
    var costToRedeem = await getCostToRedeemTicket(chain);
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
    return new MarketConditionsV1(maxFaceValue, efficiency, limitedByBalance);
  }

  static Future<Token> getCostToRedeemTicket(Chain chain) async {
    Token gasPrice = await OrchidEthereumV1().getGasPrice(chain);
    //log("gas price for chain: ${chain.name} = ${gasPrice.intValue}");
    return gasPrice * OrchidContractV1.gasCostToRedeemTicket.toDouble();
  }

  /// Calculate the current real world value of the largest ticket that can be
  /// issued from this lottery pot, taking into account the amount of gas required
  /// to redeem the ticket and current gas prices.
  /// Returns the net value which may be zero or negative if the ticket
  /// would be unprofitable to redeem.
  static Future<Token> getMaxTicketValue(Chain chain, LotteryPot pot) async {
    Token costToRedeem = await getCostToRedeemTicket(chain);
    return pot.maxTicketFaceValue - costToRedeem;
  }

  @override
  String toString() {
    return 'MarketConditions{maxFaceValue: $maxFaceValue, efficiency: $efficiency, limitedByBalance: $limitedByBalance}';
  }
}
