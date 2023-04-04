// @dart=2.9
import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/time_extensions.dart';

class LotteryPot {
  final Token deposit;
  final Token balance;
  final BigInt unlock;
  final Token warned;

  DateTime get unlockTime {
    return DateTime.fromMillisecondsSinceEpoch(unlock.toInt() * 1000);
  }

  /// An amount is warned and the warn time has elapsed
  bool get isUnlocked {
    return isWarned && unlockTime.isBefore(DateTime.now());
  }

  /// An amount is warned but the warn time has not yet arrived
  bool get isUnlocking {
    return isWarned && unlockTime.isAfter(DateTime.now());
  }

  /// An amount is warned. Could also be named isUnlockedOrUnlocking.
  bool get isWarned {
    return warned.gtZero();
  }

  /// There is no warned amount or the warned time has not yet arrived.
  /// All funds remain locked.
  bool get isLocked {
    return !isUnlocked;
  }

  /// The amount of deposit currently unlocked and available for withdrawal or zero
  Token get unlockedAmount {
    return isUnlocked ? warned : deposit.type.zero;
  }

  String unlockInString() {
    return unlockTime.toCountdownString();
  }

  /// The amount that can be withdrawn by moving any unlocked funds from deposit
  /// to balance and withdrawing the resulting balance amount.
  Token get maxWithdrawable {
    return balance + unlockedAmount;
  }

  /// Return the deposit minus any warned amount (which constitutes the amount
  /// of deposit you can actually use).
  Token get effectiveDeposit {
    return deposit - warned;
  }

  LotteryPot({
    @required this.deposit,
    @required this.balance,
    @required this.unlock,
    @required this.warned,
  });

  Token get maxTicketFaceValue {
    return maxTicketFaceValueFor(balance, deposit);
  }

  static Token maxTicketFaceValueFor(Token balance, Token deposit) {
    return Token.min(balance, deposit / 2.0);
  }

  @override
  String toString() {
    return 'LotteryPot{deposit: $deposit, balance: $balance, unlock: $unlock, warned: $warned}';
  }
}
