import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

import '../orchid_budget_api.dart';
import 'orchid_eth.dart';

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

  /*
  Account.v0(StoredEthereumKeyRef keyRef,
      this.funder,)
      : this.identityUid = keyRef.keyUid,
        this.version = 0,
        this.chainId = null;
   */

  bool get isV0 {
    return version == 0;
  }

  Future<LotteryPot> getLotteryPot() async {
    var signer = await this.signerAddress;
    var eth = OrchidEthereum(chain);
    return eth.getLotteryPot(funder, signer);
  }

  Future<MarketConditions> getMarketConditions() async {
    return getMarketConditionsFor(await getLotteryPot());
  }

  Future<MarketConditions> getMarketConditionsFor(LotteryPot pot) async {
    return OrchidEthereum(chain).getMarketConditions(pot);
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
