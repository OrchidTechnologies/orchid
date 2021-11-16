import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/pages/account_manager/account_detail_poller.dart';

/// The view model for the account
// Note: There is duplication in the account detail. Consider cleanup.
class AccountViewModel {
  final StoredEthereumKey signerKey;
  final EthereumAddress funder;
  final Chain chain;
  final AccountDetailPoller detail;
  final bool active;

  String get identityUid {
    return signerKey.uid;
  }

  EthereumAddress get signer {
    return signerKey.address;
  }

  AccountViewModel({
    @required this.signerKey,
    @required this.funder,
    @required this.chain,
    @required this.detail,
    this.active,
  });

  Token get balance {
    return detail.lotteryPot?.balance;
  }

  Token get deposit {
    return detail.lotteryPot?.deposit;
  }

  @override
  String toString() {
    return 'AccountModel{signerKey: $signerKey, funder: $funder, chain: $chain, detail: $detail, active: $active}';
  }
}
