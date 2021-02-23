import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';

// An observable list of identities and active accounts.
class AccountStore extends ChangeNotifier {

  /// Identity
  List<StoredEthereumKey> identities = [];

  /// The active identity, determined by the active account record
  StoredEthereumKey get activeIdentity {
    return StoredEthereumKey.find(identities, activeAccount?.identityUid);
  }

  /// Accounts designated by the user as active
  List<Account> activeAccounts = [];

  /// If true accounts are discovered on-chain for the active identity,
  /// otherwise only the saved active accounts are loaded.
  final bool discoverAccounts;

  /// Accounts discovered on chain
  List<Account> discoveredAccounts = [];

  AccountStore({this.discoverAccounts = true});

  /// All accounts known for the active identity.
  /// This list is not ordered.
  List<Account> get accounts {
    Set<Account> set = Set.from(discoveredAccounts);
    if (activeAccount != null) {
      set.add(activeAccount);
    }
    return set.toList();
  }

  /// The active account
  Account get activeAccount {
    return activeAccounts.isNotEmpty ? activeAccounts.first : null;
  }

  /// Set the active account for the given chain and identity: (signer, chain -> funder)
  /// chainId and funder may be null to indicate an identity preference without
  /// a current account selection.
  void setActiveAccount(Account account) async {
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

    // Refresh everything
    load();
  }

  /// Set an active identity
  void setActiveIdentity(StoredEthereumKey identity) async {
    // Look for an existing designated active account for this identity
    List<Account> accounts = await UserPreferences().activeAccounts.get();
    Account toActivate = accounts.firstWhere(
      (account) => account.identityUid == identity.uid,
      orElse: () => null,
    );
    // Activate the found account or simply activate the identity
    setActiveAccount(toActivate ?? Account(identityUid: identity.uid));
  }

  // Load available identities and user selected active account information
  Future<AccountStore> load() async {
    // Load available identities
    identities = await UserPreferences().getKeys();

    // Load active accounts
    activeAccounts = await UserPreferences().activeAccounts.get();

    // Clear discovered if we are changing identities
    if (activeIdentity == null ||
        (discoveredAccounts.isNotEmpty &&
            discoveredAccounts.first.identityUid != activeIdentity.uid)) {
      discoveredAccounts = [];
    }
    notifyListeners();

    if (discoverAccounts && activeIdentity != null) {
      // Discover accounts for the active identity on V0 Ethereum.
      discoveredAccounts =
          await OrchidEthereumV0().discoverAccounts(signer: activeIdentity);
      notifyListeners();

      // Discover accounts for the active identity on V1 chains.
      discoveredAccounts += await OrchidEthereumV1()
          .discoverAccounts(chain: Chains.xDAI, signer: activeIdentity);
      notifyListeners();
    }

    return this;
  }

  Future<void> removeIdentity(StoredEthereumKey identity) async {
    // Remove the key
    await UserPreferences().removeKey(identity.ref());

    // Remove any active account or identity selection using that key
    var activeAccounts = await UserPreferences().activeAccounts.get();
    activeAccounts.removeWhere((a) => a.identityUid == identity.uid);
    await UserPreferences().activeAccounts.set(activeAccounts);

    // Refresh
    await load();
  }

  Future<void> addIdentity(StoredEthereumKey identity) async {
    await UserPreferences().addKey(identity);
    identities = await UserPreferences().getKeys();
    setActiveIdentity(identity);

    // Refresh
    await load();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
