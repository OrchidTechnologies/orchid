import 'token_type.dart';

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
