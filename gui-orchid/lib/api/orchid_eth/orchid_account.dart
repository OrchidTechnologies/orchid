import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

import '../orchid_budget_api.dart';
import 'orchid_eth.dart';

/// The base model for accounts including signer, chain, and funder.
class Account {
  final String identityUid; // stored signer key uid
  final int version; // The contract version: 0 for the original OXT contract.
  final int chainId; // @nullable
  final EthereumAddress funder; // @nullable

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  Account({
    @required this.identityUid,
    this.version = 0,
    this.chainId,
    this.funder,
  });

  /// Stream the current active account, ignoring identities with no selection.
  static Stream<Account> get activeAccountStream {
    return UserPreferences().activeAccounts.stream().map((accounts) {
      return _filterActiveAccount(accounts);
    });
  }

  static Future<Account> get activeAccount async {
    return _filterActiveAccount(await UserPreferences().activeAccounts.get());
  }

  // Return the active account from the accounts list or null.
  static Account _filterActiveAccount(List<Account> accounts) {
    return accounts == null ||
            accounts.isEmpty ||
            accounts[0].isIdentityPlaceholder
        ? null
        : accounts[0];
  }

  /// Indicates that this account selects an identity but not yet a designated
  /// account for the identity.
  bool get isIdentityPlaceholder {
    return chainId == null && funder == null;
  }

  Account.fromJson(Map<String, dynamic> json)
      : this.identityUid = json['identityUid'],
        this.version = int.parse(json['version']),
        this.chainId = parseNullableInt(json['chainId']),
        this.funder = EthereumAddress.fromNullable(json['funder']);

  static int parseNullableInt(String val) {
    return val == null ? null : int.parse(val);
  }

  Map<String, dynamic> toJson() => {
        'version': version.toString(),
        'identityUid': identityUid,
        'chainId': chainId == null ? null : chainId.toString(),
        'funder': funder == null ? null : funder.toString()
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          identityUid == other.identityUid &&
          version == other.version &&
          chainId == other.chainId &&
          funder == other.funder;

  @override
  int get hashCode =>
      identityUid.hashCode ^
      version.hashCode ^
      chainId.hashCode ^
      funder.hashCode;

  Future<LotteryPot> getLotteryPot() async {
    var signer = await Account.getSignerAddress(this);
    var eth = OrchidEthereum(chain);
    return eth.getLotteryPot(funder, signer);
  }

  Future<EthereumAddress> get signerAddress async {
    return await getSignerAddress(this);
  }

  static Future<EthereumAddress> getSignerAddress(Account account) async {
    var identities = await UserPreferences().getKeys();
    return StoredEthereumKey.find(identities, account.identityUid)
        .get()
        .address;
  }

  @override
  String toString() {
    return 'Account{identityUid: $identityUid, chainId: $chainId, funder: $funder}';
  }
}
