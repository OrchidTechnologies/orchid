// @dart=2.9
import 'dart:async';
import 'dart:core';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'account_store.dart';

/// A thin wrapper around the user's list of identities that supports searching
/// for new accounts across all signers.
///
/// AccountFinder.shared = AccountFinder()
///     .withPollingInterval(Duration(seconds: 30))
///     .find((accounts) async { ... });
///
/// Note: This could be generalized to an API providing continuous notification of
/// Note: "new accounts" to the UI but currently mainly supports finding the first
/// Note: account while onboading new users.
class AccountFinder {
  /// This is not a factory API but if there is a long running account finder
  /// it may be stashed here to allow adjustment to the polling interval.
  static AccountFinder shared;

  Function(Set<Account>) _callback;
  Duration _duration;
  Timer _pollTimer;

  bool get _pollOnce => _duration == null;

  /// The polling interval may be updated while running
  AccountFinder setPollingInterval(Duration duration) {
    _duration = duration;
    if (_pollTimer != null && _pollTimer.isActive) {
      _restart();
    }
    return this;
  }

  AccountFinder withPollingInterval(Duration duration) {
    return setPollingInterval(duration);
  }

  /// Reset the timer and begin polling if duration is set.
  AccountFinder _start() {
    if (_duration != null) {
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_duration, _poll);
    }
    _poll(null); // kick one off immediately
    return this;
  }

  AccountFinder _restart() {
    return _start();
  }

  /// Perform an immediate poll
  AccountFinder refresh() {
    return _restart();
  }

  /// Find accounts for all keys on all chains that support eth_getLogs.
  /// If a poll interval has been set this method will search until one or more accounts
  /// are found after a complete scan of all supported chains.  The callback will be executed
  /// once and the finder will be cancelled.
  /// If no polling interval is set this will perform one complete scan and return any results.
  AccountFinder find(Function(Set<Account>) callback) {
    _callback = callback;
    _start();
    return this;
  }

  void _poll(_) async {
    log("account finder: polling for accounts");
    var keys = UserPreferences().keys.get();
    Set<Account> found = {};
    for (var key in keys) {
      try {
        var store = await AccountStore(identity: key.ref())
            .load(waitForDiscovered: true);
        found.addAll(store.accounts);
      } catch (err) {
        log("account finder: error polling identity: $key");
      }
    }

    // If we found something or are only polling once execute the callback
    if (found.isNotEmpty || _pollOnce) {
      log("account finder: found accounts: $found");
      if (_callback != null) {
        _callback(found);
      }
      cancel();
    }
  }

  void cancel() {
    _pollTimer?.cancel();
    _callback = null;
  }

  void dispose() {
    cancel();
  }
}
