import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/chains.dart';

/// Discovers on-chain and persistently caches accounts for a single signer identity.
class AccountStore extends ChangeNotifier {
  /// Identity
  final StoredEthereumKeyRef identity;

  /// If true the account store attempts to find all accounts for the user's
  /// identities.  This involves loading previously cached accounts as well as
  /// actively searching for new ones on-chain.
  /// If false only previously discovered cached accounts are loaded.
  final bool discoverAccounts;

  /// Accounts discovered on chain for the active identity (possibly including cached)
  List<Account> discoveredAccounts = [];

  /// Cached accounts previously discovered on chain for the active identity
  List<Account> cachedAccounts = [];

  AccountStore({
    @required this.identity,
    this.discoverAccounts = true,
  }) {
    if (identity == null) {
      throw Exception("identity may not be null");
    }
  }

  /// All accounts known for the identity, unordered.
  Set<Account> get accounts {
    // Cached
    Set<Account> set = Set.from(cachedAccounts);

    // Discovered
    set.addAll(discoveredAccounts);

    return set;
  }

  // Load available identities and user active account information
  // Optionally return the future without waiting for network discovery to complete.
  // (Only applicable if discoverAccounts is true.)
  Future<AccountStore> load({bool waitForDiscovered = true}) async {
    await _loadCached();
    if (waitForDiscovered) {
      await _discoverAccounts();
    } else {
      _discoverAccounts();
    }
    return this;
  }

  Future<AccountStore> refresh() async {
    return load(waitForDiscovered: true);
  }

  // Load the locally persisted and cached account information.
  // This method can be awaited without potential long delays for network activity.
  Future<AccountStore> _loadCached() async {
    // Load cached previously discovered accounts for this identity
    var cached = await UserPreferences().cachedDiscoveredAccounts.get();
    cachedAccounts = cached
        .where((account) => account.signerKeyUid == identity.keyUid)
        .toList();
    log("account_store: loaded cached discovered accounts: "
        "cached = $cached, filtered = $cachedAccounts");
    notifyListeners();
    return this;
  }

  // Discovery new account information for the active identity.
  // This method performs potentially slow network activity.
  Future<AccountStore> _discoverAccounts() async {
    // Discover new accounts for this identity
    if (discoverAccounts) {
      log("account_store: Discovering accounts");

      discoveredAccounts = [];

      StoredEthereumKey signer = await identity.get();
      try {
        // Discover accounts for the active identity on V1 chains.
        discoveredAccounts = await OrchidEthereumV1()
            .discoverAccounts(chain: Chains.xDAI, signer: signer);

        notifyListeners();
        log("account_store: After discovering v1 accounts: discovered = $discoveredAccounts");
      } catch (err) {
        log("account_store: Error in v1 account discovery: $err");
      }

      try {
        // Discover accounts for the active identity on V0 Ethereum.
        discoveredAccounts +=
            await OrchidEthereumV0().discoverAccounts(signer: signer);
        notifyListeners();
      } catch (err) {
        log("account_store: Error in v0 account discovery: $err");
      }

      // Add any newly discovered accounts to the persistent cache
      if (discoveredAccounts.isNotEmpty) {
        log("account_store: Saving discovered accounts: $discoveredAccounts");
        await UserPreferences().addCachedDiscoveredAccounts(discoveredAccounts);
      }
    }

    return this;
  }
}
