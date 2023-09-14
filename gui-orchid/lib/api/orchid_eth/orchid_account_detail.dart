import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';

/// Orchid account details including pot balance and market conditions.
abstract class AccountDetail {
  Account get account;

  // The resolved signer address. Null until details are polled.
  EthereumAddress? signerAddress;

  // The funder from the account
  EthereumAddress? get funder {
    return account.funder;
  }

  // The lotter pot.  Null until polled
  LotteryPot? get lotteryPot;

  // The market conditions. Null until polled
  MarketConditions? get marketConditions;

  // The market alert flag.  False until polled
  bool get showMarketStatsAlert;

  // The transactions.  Null until polled
  List<OrchidUpdateTransactionV0>? get transactions;
}

class AccountDetailPoller extends ChangeNotifier implements AccountDetail {
  static int nextId = 0;
  final int id;
  final Account account;
  final Duration pollingPeriod;

  // The resolved signer address (non-async). Null until details are polled.
  EthereumAddress? signerAddress;

  EthereumAddress get funder {
    return account.funder;
  }

  AccountDetailPoller({
    required this.account,
    this.pollingPeriod = const Duration(seconds: 30),
  }) : this.id = nextId++ {
    log("XXX: AccountDetailPoller $id created.");
  }

  Timer? _balanceTimer;
  bool _balancePollInProgress = false;
  DateTime? _lotteryPotLastUpdate;

  // Account Detail
  LotteryPot? lotteryPot; // initially null
  MarketConditions? marketConditions;
  bool showMarketStatsAlert = false;
  bool _isCancelled = false;

  List<OrchidUpdateTransactionV0>? transactions;

  /// Start periodic polling
  Future<void> startPolling() async {
    _balanceTimer = Timer.periodic(pollingPeriod, (_) {
      _pollBalanceAndAccountDetails();
    });
    return _pollBalanceAndAccountDetails(); // kick one off immediately
  }

  /// Load data once
  Future<void> pollOnce() async {
    return _pollBalanceAndAccountDetails();
  }

  /// Load data updating caches
  Future<void> refresh() async {
    return _pollBalanceAndAccountDetails(refresh: true);
  }

  Future<void> _pollBalanceAndAccountDetails({bool refresh = false}) async {
    // log("XXX: poller $id polling details");
    // if (!_balanceTimer.isActive) {
    if (_isCancelled) {
      log("XXX: call to _pollBalanceAndAccountDetails with cancelled timer.");
      return;
    }

    if (signerAddress == null) {
      signerAddress = account.signerAddress;
    }

    if (_balancePollInProgress) {
      return;
    }
    _balancePollInProgress = true;
    try {
      // Fetch the pot balance
      LotteryPot _pot;
      try {
        _pot = await account
            .getLotteryPot(refresh: refresh)
            .timeout(Duration(seconds: 30));
      } catch (err) {
        log('poller $id error fetching lottery pot 1: $err');
        return;
      }
      lotteryPot = _pot;
      _lotteryPotLastUpdate = DateTime.now();

      MarketConditions? _marketConditions;
      try {
        _marketConditions = await account
            .getMarketConditionsFor(_pot)
            .timeout(Duration(seconds: 60));
      } catch (err, stack) {
        log('poller $id error fetching market conditions: $err\n$stack');
      }
      marketConditions = _marketConditions;

      // TODO: Complete for V1 and move to Accounts
      // TODO: Implement caching if appropriate
      List<OrchidUpdateTransactionV0>? _transactions;
      try {
        if (account.version == 0) {
          _transactions = await OrchidEthereumV0()
              .getUpdateTransactions(funder: funder, signer: signerAddress!);
        } else {
          // _transactions = await OrchidEthereumV1()
          //     .getUpdateTransactions(funder: funder, signer: resolvedSigner);
        }
      } catch (err) {
        log('Error fetching account update transactions: $err');
      }
      transactions = _transactions;

      if (marketConditions != null) {
        showMarketStatsAlert = (marketConditions!.efficiency ?? 0) <
            MarketConditions.minEfficiency;
      }

      this.notifyListeners();
    } catch (err, stack) {
      log("Can't fetch market stats: $err\n$stack");

      // Allow a stale balance for a period of time.
      if (_lotteryPotLastUpdate != null &&
          _lotteryPotLastUpdate!.difference(DateTime.now()) >
              Duration(hours: 1)) {
        lotteryPot = null; // no balance available
        notifyListeners();
      }
    } finally {
      _balancePollInProgress = false;
    }
  }

  void cancel() {
    _isCancelled = true;
    _balanceTimer?.cancel();
    log("XXX: account detail $id poller cancelled (account chain = ${account.chainId})");
  }

  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  String toString() {
    return 'AccountDetailPoller{name: $id, account: $account, lotteryPot: $lotteryPot, marketConditions: $marketConditions}';
  }
}
