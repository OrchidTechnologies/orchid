import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';

// TODO: A major aspect of this class is to maintain the notion of an
// TODO: "active account" (implying the "active identity"). We no longer use
// TODO: this for circuit building and it currently only serves to remember
// TODO: the last identity viewed in the UI on the account manager.
// TODO: We should probably simplify this to being only about account discovery.
/// An observable list of identities and active accounts on those identities.
class AccountStore extends ChangeNotifier {
  /// If true the account store attempts to find all accounts for the user's
  /// identities.  This involves loading previously cached accounts as well as
  /// actively searching for new ones on-chain.
  /// If false only the saved user-selected active accounts for the user's one
  /// or more identities is loaded.
  final bool discoverAccounts;

  /// Identity
  List<StoredEthereumKey> identities = [];

  /// The active identity, determined by the active account record
  StoredEthereumKey get activeIdentity {
    var selectedAccount =
        activeAccounts.isNotEmpty ? activeAccounts.first : null;
    return StoredEthereumKey.find(identities, selectedAccount?.identityUid);
  }

  // TODO: Currently maintained only for use in migration to new circuit builder
  // TODO: and for holding the last viewed identity.
  /// Accounts designated by the user as active.
  /// The first account in this list designates the active identity.
  List<Account> activeAccounts = [];

  /// Accounts discovered on chain for the active identity
  List<Account> discoveredAccounts = [];

  /// Cached accounts previously discovered on chain for the active identity
  List<Account> cachedDiscoveredAccounts = [];

  AccountStore({this.discoverAccounts = true});

  /// All accounts known for the active identity, unordered.
  List<Account> get accounts {
    // Cached
    Set<Account> set = Set.from(cachedDiscoveredAccounts);

    // TODO: needed?
    // Discovered
    set.addAll(discoveredAccounts);

    // Stored active
    // if (activeAccount != null) {
    //   set.add(activeAccount);
    // }
    return set.toList();
  }

  /*
  /// The active account
  Account get activeAccount {
    if (activeAccounts.isEmpty || activeAccounts.first.isIdentityPlaceholder) {
      return null;
    }
    return activeAccounts.first;
  }
   */

  /*
  /// Set the active account for the given chain and identity: (signer, chain -> funder)
  /// chainId and funder may be null to indicate an identity preference without
  /// a current account selection.
  Future<void> _setActiveAccount(Account account) async {
    if (account == activeAccount) {
      return;
    }
    List<Account> accounts = await UserPreferences().activeAccounts.get();

    // Remove any placeholder identity selection of the identity with no active account
    accounts.removeWhere((a) => a.isIdentityPlaceholder);

    // Remove any existing active account for this identity and chain
    accounts.removeWhere((a) =>
        a.identityUid == account.identityUid && a.chainId == account.chainId);

    // Add the account back
    accounts.insert(0, account);
    activeAccounts = accounts;
    await UserPreferences().activeAccounts.set(accounts);

    return _accountsChanged();
  }
   */

  Future<void> setActiveIdentityByAccount(Account _account) async {
    var account = Account(identityUid: _account.identityUid);
    await UserPreferences().activeAccounts.set([account]);
    activeAccounts = [account]; // todo
    return await _accountsChanged();
  }

  /// Set an active identity
  Future<void> setActiveIdentity(StoredEthereumKey identity) async {
    // return _setActiveAccount(toActivate ?? Account(identityUid: identity.uid));
    var account = Account(identityUid: identity.uid);
    return setActiveIdentityByAccount(account);

    /*
    // Look for an existing designated active account for this identity
    List<Account> accounts = await UserPreferences().activeAccounts.get();
    Account toActivate = accounts.firstWhere(
      (account) => account.identityUid == identity.uid,
      orElse: () => null,
    );
    // Activate the found account or simply activate the identity
    return _setActiveAccount(toActivate ?? Account(identityUid: identity.uid));
     */
  }

  // Called when the list of identities or active accounts is changed to
  // update the account store internal state and publish changes throughout the UI.
  Future<void> _accountsChanged() async {
    // Update the account list but don't wait for any new account discovery.
    // (Falling through to publish the important change in active account selection)
    await load(waitForDiscovered: false);

    // The active account preference may be observed directly but we also need
    // to publish the updated circuit configuration.
    OrchidAPI().circuitConfigurationChanged.add(null);
    await OrchidAPI().updateConfiguration();
    //print( "accounts changed: config = ${await OrchidVPNConfig.generateConfig()}");
  }

  // Load available identities and user active account information
  // Optionally return the future without waiting for network discovery to complete.
  // (Only applicable if discoverAccounts is true.)
  Future<AccountStore> load({bool waitForDiscovered = true}) async {
    await _loadStored();
    if (waitForDiscovered) {
      await _loadDiscovered();
    } else {
      _loadDiscovered();
    }
    return this;
  }

  // Load the locally persisted and cached account information.
  // This method can be awaited without potential long delays for network activity.
  Future<AccountStore> _loadStored() async {
    // Load available identities
    identities = await UserPreferences().getKeys();

    // TODO: Currently maintained only for use in migration to new circuit builder
    // TODO: and for holding the last viewed identity.
    // Load active accounts
    activeAccounts = await UserPreferences().activeAccounts.get();

    // Clear discovered if we are changing identities
    if (activeIdentity == null ||
        (discoveredAccounts.isNotEmpty &&
            discoveredAccounts.first.identityUid != activeIdentity.uid)) {
      discoveredAccounts = [];
      cachedDiscoveredAccounts = [];
    }

    // Load cached previously discovered accounts for this identity
    if (discoverAccounts && activeIdentity != null) {
      var cached = await UserPreferences().cachedDiscoveredAccounts.get();
      cachedDiscoveredAccounts = cached
          .where((account) => account.identityUid == activeIdentity.uid)
          .toList();
      log("account_store: loaded cached discovered accounts: "
          "cached = $cached, filtered = $cachedDiscoveredAccounts");
    }
    notifyListeners();
    return this;
  }

  // Discovery new account information for the active identity.
  // This method performs potentially slow network activity.
  Future<AccountStore> _loadDiscovered() async {
    // Discover new accounts for this identity
    try {
      if (discoverAccounts && activeIdentity != null) {
        log("account_store: Discovering accounts");

        // Discover accounts for the active identity on V1 chains.
        discoveredAccounts = await OrchidEthereumV1()
            .discoverAccounts(chain: Chains.xDAI, signer: activeIdentity);
        notifyListeners();
        log("account_store: After discovering v1 accounts: discovered = $discoveredAccounts");

        // Discover accounts for the active identity on V0 Ethereum.
        discoveredAccounts +=
            await OrchidEthereumV0().discoverAccounts(signer: activeIdentity);
        notifyListeners();

        // Cache any newly discovered accounts
        if (discoveredAccounts.isNotEmpty) {
          log("account_store: Saving discovered accounts: $discoveredAccounts");
          await UserPreferences()
              .addCachedDiscoveredAccounts(discoveredAccounts);
        }
      }
    } catch (err) {
      log("account_store: Error in account discovery: $err");
    }

    return this;
  }

  Future<void> deleteIdentity(StoredEthereumKey identity) async {
    // Remove the key
    await UserPreferences().removeKey(identity.ref());

    // Remove any active account or identity selection using that key
    var activeAccounts = await UserPreferences().activeAccounts.get();
    activeAccounts.removeWhere((a) => a.identityUid == identity.uid);
    await UserPreferences().activeAccounts.set(activeAccounts);

    _accountsChanged();
  }

  Future<void> addIdentity(StoredEthereumKey identity) async {
    await UserPreferences().addKey(identity);
    identities = await UserPreferences().keys.get();

    // setActiveIdentity(identity);
    _accountsChanged();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
