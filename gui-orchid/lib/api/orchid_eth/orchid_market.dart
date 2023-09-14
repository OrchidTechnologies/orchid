import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'chains.dart';
import 'token_type.dart';

class MarketConditions {
  final Token maxFaceValue;
  final Token costToRedeem;
  final double? efficiency;
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

/// Get market stats snapshot for the creation of a pot of a specified composition.
class PotStats {
  // pot composition
  final Chain chain;
  final int version; // the contract version
  final double efficiency;
  final int tickets;

  // stats
  final Token createDeposit;
  final Token createBalance;

  // Total gas value required for the operation.
  // Note that the token type may be different from the balance / deposit token
  // and this gas amount may include more than one transaction if required.
  final Token createGas;

  // Estimate gas amount to withdraw the balance and deposit assuming the current
  // gas price and taking into account both unlock and withdrawal tx.
  Token get withdrawGas {
    return gasPrice *
        (OrchidContractV1.lotteryWarnMaxGas +
                OrchidContractV1.lotteryPullMaxGas)
            .toDouble();
  }

  // The gas price used in these calculations.
  final Token gasPrice;

  PotStats({
    required this.chain,
    required this.version,
    required this.efficiency,
    required this.tickets,
    required this.createDeposit,
    required this.createBalance,
    required this.createGas,
    required this.gasPrice,
  });
}
