import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';

/// Discovers on-chain and persistently caches accounts for a single signer identity.
class AccountStore extends ChangeNotifier {
  /// Identity
  final EthereumKeyRef identity;

  /// If true the account store attempts to find all accounts for the user's
  /// identities.  This involves loading previously cached accounts as well as
  /// actively searching for new ones on-chain.
  /// If false only previously discovered cached accounts are loaded.
  final bool discoverAccounts;

  /// Accounts discovered on chain for the active identity (possibly including cached)
  List<Account> discoveredAccounts = [];

  /// Cached accounts previously discovered on chain for the active identity
  List<Account> cachedAccounts = [];

  /// Accounts found in Orchid Hop configurations in the Circuit
  // Note: See notes on load method for an explanation of why we are doing this.
  List<Account> circuitAccounts = [];

  AccountStore({
    required this.identity,
    this.discoverAccounts = true,
  }) {
    if (identity == null) {
      throw Exception("identity may not be null");
    }
  }

  /// All accounts known for the identity, unordered.
  Set<Account> get accounts {
    Set<Account> set = {};
    set.addAll(cachedAccounts);
    set.addAll(discoveredAccounts);
    set.addAll(circuitAccounts);
    return set;
  }

  // Load available identities and user active account information
  // Optionally return the future without waiting for network discovery to complete.
  // (Only applicable if discoverAccounts is true.)
  Future<AccountStore> load({bool waitForDiscovered = true}) async {
    _loadCached();
    _loadFromCircuitConfig();
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
  void _loadCached() {
    // Load cached previously discovered accounts for this identity
    var cached = UserPreferencesVPN().cachedDiscoveredAccounts.get() ?? {};
    cachedAccounts = cached
        .where((account) => account.signerKeyUid == identity.keyUid)
        .toList();
    logDetail("account_store: loaded cached discovered accounts: "
        "cached = $cached, filtered = $cachedAccounts");
    notifyListeners();
  }

  /// Load accounts from the user's configured Orchid hops in the circuit.
  // Note: This is a workaround for the fact that we do not currently have
  // Note: a normalized data model for fully user-entered accounts. The Orchid
  // Note: hop configuration is currently where this data resides.
  void _loadFromCircuitConfig() {
    final circuit = UserPreferencesVPN().circuit.get();
    // circuit will not be null
    circuitAccounts = circuit!.hops
        .whereType<OrchidHop>()
        .map((hop) => hop.account)
        .where((account) => account.signerKeyUid == identity.keyUid)
        .toList();

    // Cache any newly discovered accounts from the hop config
    var cachedAccounts = UserPreferencesVPN().cachedDiscoveredAccounts.get();
    if (!setEquals(circuitAccounts.toSet(), cachedAccounts)) {
      UserPreferencesVPN().addCachedDiscoveredAccounts(circuitAccounts);
    }
  }

  // Discovery new account information for the identity.
  // This method performs potentially slow network activity.
  Future<AccountStore> _discoverAccounts() async {
    // Discover new accounts for this identity
    if (discoverAccounts) {
      logDetail("account_store: Discovering accounts");

      discoveredAccounts = [];

      // Discover accounts for the active identity on supported V1 chains.
      StoredEthereumKey signer = identity.get();
      try {
        // Small amount of data with high latency, let's do them in parallel.
        await Future.wait(Chains.map.values.where((e) => e.supportsLogs).map(
              (e) => _discoverV1Accounts(chain: e, signer: signer),
            ));
        notifyListeners();
        logDetail("account_store: After discovering v1 accounts: discovered = $discoveredAccounts");
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
        logDetail("account_store: Saving discovered accounts: $discoveredAccounts");
        await UserPreferencesVPN().addCachedDiscoveredAccounts(discoveredAccounts);
      }
    }

    return this;
  }

  // discover and add accounts to the discovered accounts list
  Future<void> _discoverV1Accounts(
      {required Chain chain, required StoredEthereumKey signer}) async {
    try {
      var found = await OrchidEthereumV1()
          .discoverAccounts(chain: chain, signer: signer);
      logDetail("account_store: events found ${found.length} accounts on: ${chain.name}");
      discoveredAccounts += found;
    } catch (err) {
      log("account_store: Error discovering accounts on ${chain.name}: $err");
    }
  }
}
