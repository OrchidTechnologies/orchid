import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/cacheable.dart';

import '../orchid_budget_api.dart';

/// The base model for accounts including signer, chain, and funder.
class Account {
  final String identityUid; // stored signer key reference uid
  final EthereumAddress funder; // @nullable
  final int version; // The contract version: 0 for the original OXT contract.
  final int chainId; // @nullable

  // The signer address is normally resolved by looking up the stored key and
  // calculating the address from the secret.  This field caches the result and
  // also allows it to be pre-populated for tests to avoid the keystore.
  // Note: If this gets any more prevalent we should just mock the keystore.
  EthereumAddress resolvedSignerAddress;

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  Account({
    @required this.identityUid,
    this.version = 0,
    this.chainId,
    this.funder,
    this.resolvedSignerAddress,
  });

  /// This account uses the V0 OXT contract
  bool get isV0 {
    return version == 0;
  }

  static Cache<Account, LotteryPot> lotteryPotCache =
      Cache(duration: Duration(seconds: 60), name: "lottery pot");

  // Use refresh to force an update to the cache
  Future<LotteryPot> getLotteryPot({bool refresh = false}) async {
    return lotteryPotCache.get(
        key: this, producer: _getLotteryPotFor, refresh: refresh);
  }

  static Future<LotteryPot> _getLotteryPotFor(Account account) async {
    var signer = await account.signerAddress;
    if (account.isV0) {
      return OrchidEthereumV0.getLotteryPot(account.funder, signer);
    } else {
      return OrchidEthereumV1.getLotteryPot(
          chain: account.chain, funder: account.funder, signer: signer);
    }
  }

  Future<MarketConditions> getMarketConditions() async {
    return getMarketConditionsFor(await getLotteryPot());
  }

  // Note: Market conditions are not cached but the underlying prices are.
  Future<MarketConditions> getMarketConditionsFor(LotteryPot pot,
      {bool refresh = false}) async {
    if (isV0) {
      // TODO: Add refresh option
      return MarketConditionsV0.forPotV0(pot);
    } else {
      return MarketConditionsV1.forPot(pot, refresh: refresh);
    }
  }

  /// This method loads market conditions for each account and sorts them by efficiency.
  static Future<List<Account>> sortAccountsByEfficiency(
      Set<Account> accounts) async {
    var accountMarketConditions = (await Future.wait(accounts.map((account) async {
      try {
        return _AccountMarketConditions(
            account, await account.getMarketConditions());
      } catch (err) {
        log("sort accounts: error fetching market conditions: $err");
        return null;
      }
    })))
        .where((e) => e != null) // skip errors
        .toList();

    // Sort by efficiency descending
    // Note: We have a similar sort in the account manager.
    accountMarketConditions.sort((_AccountMarketConditions a, _AccountMarketConditions b) {
      return -((a.marketConditions?.efficiency ?? 0)
          .compareTo((b.marketConditions?.efficiency ?? 0)));
    });
    return accountMarketConditions.map((e) => e.account).toList();
  }

  StoredEthereumKeyRef get signerKeyRef {
    return StoredEthereumKeyRef(this.identityUid);
  }

  Future<StoredEthereumKey> get signerKey async {
    return signerKeyRef.get();
  }

  Future<EthereumAddress> get signerAddress async {
    if (resolvedSignerAddress == null) {
      resolvedSignerAddress = (await signerKey).address;
    }
    return resolvedSignerAddress;
  }

  // Resolve the signer address using the supplied keystore. (non-async)
  EthereumAddress signerAddressFrom(List<StoredEthereumKey> keys) {
    return signerKeyRef.getFrom(keys).get().address;
  }

  // Note: Used in migration from the old active account model
  static Future<Account> get activeAccountLegacy async {
    return _filterActiveAccountLegacyLogic(
        await UserPreferences().activeAccounts.get());
  }

  // Note: Used in migration from the old active account model
  // Return the active account from the accounts list or null.
  static Account _filterActiveAccountLegacyLogic(List<Account> accounts) {
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
        'funder': funder == null ? null : funder.toString(),
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

  @override
  String toString() {
    return 'Account{identityUid: $identityUid, chainId: $chainId, funder: $funder}';
  }
}

class _AccountMarketConditions {
  final Account account;
  final MarketConditions marketConditions;

  _AccountMarketConditions(this.account, this.marketConditions);
}
