import 'package:flutter/cupertino.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';

import 'account_detail_poller.dart';

/// This class hosts a cache of account detail pollers that is populated as
/// account detail is requested for accounts by the get method.
/// It currently fires its callback when any of the pollers updates.
class AccountDetailStore {
  final Map<Account, AccountDetailPoller> _accountDetailMap = {};

  /// Invoked when any of the pollers updates
  final VoidCallback onAccountDetailChanged;

  AccountDetailStore({this.onAccountDetailChanged});

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
