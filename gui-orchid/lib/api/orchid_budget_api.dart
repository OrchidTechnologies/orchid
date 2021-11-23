import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/units.dart';

import 'orchid_crypto.dart';

// Funds and Budgeting API
class OrchidBudgetAPI {
  static OrchidBudgetAPI _shared = OrchidBudgetAPI._init();

  OrchidBudgetAPI._init();

  factory OrchidBudgetAPI() {
    return _shared;
  }

  void applicationReady() async {}
}

/// Lottery pot balance and deposit amounts.
// TODO: Remove after migration
// Note: This supports migration of OXT-specific code. If we simply generalize
// Note: the value types to Token Dart would not catch assignment type errors
// Note: until runtime due to its automatic downcasting.
class OXTLotteryPot implements LotteryPot {
  final OXT deposit;
  final OXT balance;
  final BigInt unlock;
  final EthereumAddress verifier;

  OXTLotteryPot({
    this.deposit,
    this.balance,
    this.unlock,
    this.verifier,
  });

  OXT get maxTicketFaceValue {
    return maxTicketFaceValueFor(balance, deposit);
  }

  static OXT maxTicketFaceValueFor(OXT balance, OXT deposit) {
    return Token.min(balance, deposit / 2.0);
  }

  @override
  String toString() {
    return 'OXTLotteryPot{deposit: $deposit, balance: $balance}';
  }
}

class LotteryPot {
  final Token deposit;
  final Token balance;
  final BigInt unlock;
  // TODO: Warned

  LotteryPot({
    this.deposit,
    this.balance,
    this.unlock,
  });

  Token get maxTicketFaceValue {
    return maxTicketFaceValueFor(balance, deposit);
  }


  @override
  String toString() {
    return 'LotteryPot{deposit: $deposit, balance: $balance, unlock: $unlock}';
  }

  static Token maxTicketFaceValueFor(Token balance, Token deposit) {
    return Token.min(balance, deposit / 2.0);
  }
}
