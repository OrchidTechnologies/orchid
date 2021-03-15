import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_eth.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';

class AccountDetailPoller extends ChangeNotifier {
  final Account account;

  // the signer corresponding to the account's identity uid
  final EthereumAddress resolvedSigner;

  EthereumAddress get funder {
    return account.funder;
  }

  AccountDetailPoller({this.account, this.resolvedSigner});

  Timer balanceTimer;
  bool balancePollInProgress = false;
  LotteryPot lotteryPot; // initially null
  MarketConditions marketConditions;

  // TODO:
  List<OrchidUpdateTransactionV0> transactions;
  bool showMarketStatsAlert = false;
  DateTime lotteryPotLastUpdate;

  OrchidEthereum get eth {
    return OrchidEthereum(account.chain);
  }

  void start() async {
    balanceTimer = Timer.periodic(Duration(seconds: 15), (_) {
      _pollBalanceAndAccountDetails();
    });
    _pollBalanceAndAccountDetails(); // kick one off immediately
  }

  Future<void> refresh() {
    return _pollBalanceAndAccountDetails();
  }

  Future<void> _pollBalanceAndAccountDetails() async {
    //log("XXX: polling account details: signer = $resolvedSigner, funder = $funder");
    if (balancePollInProgress) {
      return;
    }
    balancePollInProgress = true;
    try {
      // Fetch the pot balance
      LotteryPot _pot;
      try {
        _pot = await eth
            .getLotteryPot(funder, resolvedSigner)
            .timeout(Duration(seconds: 30));
      } catch (err) {
        log('Error fetching lottery pot: $err');
        return;
      }
      lotteryPot = _pot;
      lotteryPotLastUpdate = DateTime.now();

      MarketConditions _marketConditions;
      try {
        _marketConditions =
            await eth.getMarketConditions(_pot).timeout(Duration(seconds: 60));
      } catch (err, stack) {
        log('Error fetching market conditions: $err\n$stack');
        //return;
      }
      marketConditions = _marketConditions;

      List<OrchidUpdateTransactionV0> _transactions;
      try {
        if (account.version == 0) {
          _transactions = await OrchidEthereumV0()
              .getUpdateTransactions(funder: funder, signer: resolvedSigner);
        } else {
          // _transactions = await OrchidEthereumV1()
          //     .getUpdateTransactions(funder: funder, signer: resolvedSigner);
        }
      } catch (err) {
        log('Error fetching account update transactions: $err');
      }
      transactions = _transactions;

      showMarketStatsAlert = (await eth.getMaxTicketValue(_pot)).lteZero();

      this.notifyListeners();
    } catch (err, stack) {
      log("Can't fetch balance: $err\n$stack");

      // Allow a stale balance for a period of time.
      if (lotteryPotLastUpdate != null &&
          lotteryPotLastUpdate.difference(DateTime.now()) >
              Duration(hours: 1)) {
        lotteryPot = null; // no balance available
        notifyListeners();
      }
    } finally {
      balancePollInProgress = false;
    }
  }

  void dispose() {
    balanceTimer?.cancel();
    super.dispose();
  }
}
