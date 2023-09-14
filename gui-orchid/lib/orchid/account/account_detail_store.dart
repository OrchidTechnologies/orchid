import 'package:flutter/cupertino.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import '../../api/orchid_eth/orchid_account_detail.dart';

/// Hosts a pool of account detail pollers that is populated on-demand as
/// individual accounts are requested by the get method.
/// The store listens to all of its cached pollers and fires its account detail
/// changed callback when any them updates.
class AccountDetailStore {
  final Map<Account, AccountDetailPoller> _accountDetailMap = {};

  /// Invoked when any of the pollers updates
  final VoidCallback onAccountDetailChanged;

  AccountDetailStore({required this.onAccountDetailChanged});

  /// Load data updating caches
  Future<void> refresh() async {
    _accountDetailMap.forEach((key, value) async {
      await value.refresh();
    });
  }

  /// Return a cached or new account detail poller for the account.
  AccountDetailPoller get(Account account) {
    var poller = _accountDetailMap[account];
    if (poller == null) {
      poller = AccountDetailPoller(account: account);
      poller.addListener(_accountDetailChanged);
      poller.startPolling();
      _accountDetailMap[account] = poller;
    }
    return poller;
  }

  /// Stop polling for the specified account
  void remove(Account account) {
    var poller = _accountDetailMap.remove(account);
    if (poller != null) {
      poller.removeListener(_accountDetailChanged);
      poller.cancel();
    }
  }

  void _accountDetailChanged() {
    if (onAccountDetailChanged != null) {
      onAccountDetailChanged();
    }
  }

  void _disposeAccountDetailMap() {
    _accountDetailMap.forEach((key, value) {
      value.removeListener(_accountDetailChanged);
      value.dispose();
    });
  }

  void dispose() {
    _disposeAccountDetailMap();
  }
}
