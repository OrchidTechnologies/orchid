import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_market_v1.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/util/cacheable.dart';
import 'orchid_lottery.dart';
import 'orchid_market.dart';

/// The base model for accounts including chain, signer, funder, and contract version.
class Account {
  /// If this account was created for a stored key then this is the key uid.
  final String? signerKeyUid;
  final EthereumAddress funder;

  /// The contract version: 0 for the original OXT contract.
  final int version;
  final int chainId;

  /// For an account that is created from a stored key the signer address is
  /// resolved lazily by looking up the key and calculating the address from the secret.
  /// For an account that is created from a signer address this holds the address.
  EthereumAddress? resolvedSignerAddress;

  /// For an account created from a full signer key this is the resolved key.
  StoredEthereumKey? resolvedSignerKey;

  bool get hasKey {
    return signerKeyUid != null;
  }

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  Account.base({
    required this.signerKeyUid,
    this.resolvedSignerAddress,
    this.resolvedSignerKey,
    this.version = 0,
    required this.chainId, // required?
    required this.funder, // required?
  });

  /// Create an account with referencing a stored signer key
  Account.fromSignerKeyRef({
    required StoredEthereumKeyRef signerKey,
    int version = 0,
    required int chainId,
    required EthereumAddress funder,
  }) : this.base(
          signerKeyUid: signerKey.keyUid,
          resolvedSignerAddress: null,
          version: version,
          chainId: chainId,
          funder: funder,
        );

  /// Create an account with a full signer key
  Account.fromSignerKey({
    required StoredEthereumKey signerKey,
    int version = 0,
    required int chainId,
    required EthereumAddress funder,
  }) : this.base(
          signerKeyUid: signerKey.uid,
          resolvedSignerAddress: null,
          resolvedSignerKey: signerKey,
          version: version,
          chainId: chainId,
          funder: funder,
        );

  /// Create an account with an external signer address (no key)
  Account.fromSignerAddress({
    required EthereumAddress signerAddress,
    int version = 0,
    required int chainId,
    required EthereumAddress funder,
  }) : this.base(
          signerKeyUid: null,
          resolvedSignerAddress: signerAddress,
          version: version,
          chainId: chainId,
          funder: funder,
        );

  /// This account uses the V0 OXT contract
  bool get isV0 {
    return version == 0;
  }

  static Cache<Account, LotteryPot> lotteryPotCache =
      Cache(duration: Duration(seconds: 30), name: 'lottery pot');

  // Use refresh to force an update to the cache
  Future<LotteryPot> getLotteryPot({bool refresh = false}) async {
    return lotteryPotCache.get(
        key: this, producer: _getLotteryPotFor, refresh: refresh);
  }

  static Future<LotteryPot> _getLotteryPotFor(Account account) async {
    if (account is MockAccount) {
      return account.mockLotteryPot;
    }
    log("Fetching lottery pot from network: $account");
    var signer = account.signerAddress;
    if (account.isV0) {
      return OrchidEthereumV0.getLotteryPot(account.funder, signer);
    } else {
      return OrchidEthereumV1().getLotteryPot(
          chain: account.chain, funder: account.funder, signer: signer);
    }
  }

  Future<MarketConditions> getMarketConditions() async {
    return getMarketConditionsFor(await getLotteryPot());
  }

  // Note: Market conditions are not cached but the underlying prices are.
  Future<MarketConditions> getMarketConditionsFor(LotteryPot pot,
      {bool refresh = false}) async {
    if (pot is MockLotteryPot) {
      return pot.mockMarketConditions;
    }
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
    List<_AccountMarketConditions> accountMarketConditions =
        (await Future.wait(accounts.map((account) async {
      try {
        return _AccountMarketConditions(
            account, await account.getMarketConditions());
      } catch (err) {
        log("sort accounts: error fetching market conditions: $err");
        return null;
      }
    })))
            .whereType<_AccountMarketConditions>()
            .toList();

    // Sort by efficiency descending
    // Note: We have a similar sort in the account manager.
    accountMarketConditions
        .sort((_AccountMarketConditions a, _AccountMarketConditions b) {
      return -((a.marketConditions.efficiency ?? 0)
          .compareTo((b.marketConditions.efficiency ?? 0)));
    });

    return accountMarketConditions.map((e) => e.account).toList();
  }

  ///
  /// Begin key methods
  ///

  StoredEthereumKeyRef get signerKeyRef {
    if (signerKeyUid == null) {
      throw Exception(
          'Account does not resolve to a stored key: $resolvedSignerAddress');
    }

    return StoredEthereumKeyRef(this.signerKeyUid!);
  }

  StoredEthereumKey get signerKey {
    if (resolvedSignerKey == null) {
      resolvedSignerKey = signerKeyRef.get();
    }
    return resolvedSignerKey!;
  }

  EthereumAddress get signerAddress {
    if (resolvedSignerAddress == null) {
      resolvedSignerAddress = signerKey.address;
    }
    return resolvedSignerAddress!;
  }

  // Resolve the signer address using the supplied keystore.
  EthereumAddress signerAddressFrom(List<StoredEthereumKey> keys) {
    return signerKeyRef.getFrom(keys).get().address;
  }

  ///
  /// End key methods
  ///

  static String signerKeyUidJsonName = 'identityUid';

  Account.fromJson(Map<String, dynamic> json)
      : this.signerKeyUid = json[signerKeyUidJsonName],
        this.version = int.parse(json['version']),
        this.chainId = int.parse(json['chainId']),
        this.funder = EthereumAddress.fromNullable(json['funder']);

  static int? parseNullableInt(String? val) {
    return val == null ? null : int.parse(val);
  }

  Map<String, dynamic> toJson() => {
        'version': version.toString(),
        signerKeyUidJsonName: signerKeyUid,
        'chainId': chainId == null ? null : chainId.toString(),
        'funder': funder == null ? null : funder.toString(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          signerKeyUid == other.signerKeyUid &&
          version == other.version &&
          chainId == other.chainId &&
          funder == other.funder;

  @override
  int get hashCode =>
      signerKeyUid.hashCode ^
      version.hashCode ^
      chainId.hashCode ^
      funder.hashCode;

  String toExportString() {
    return 'account={ '
        'secret: "${signerKey.formatSecretFixed()}", '
        'funder: "${funder.toString(prefix: true, elide: false)}", '
        'chainid: $chainId, '
        'version: $version'
        '}';
  }

  @override
  String toString() {
    return 'Account{signerKeyUid: $signerKeyUid, chainId: $chainId, version: $version, funder: $funder}';
  }
}

class _AccountMarketConditions {
  final Account account;
  final MarketConditions marketConditions;

  _AccountMarketConditions(this.account, this.marketConditions);
}
