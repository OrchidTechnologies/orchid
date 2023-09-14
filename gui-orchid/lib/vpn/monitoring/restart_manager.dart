import 'dart:async';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:rxdart/rxdart.dart';
import '../../api/orchid_log.dart';
import '../../api/orchid_platform.dart';

/// Manage automated restarts of the VPN extension.
///
/// There is no prescribed way to "restart" the vpn extension (on iOS at least)
/// and simply invoking stop and start in succession seems unwise. This class
/// attempts to mitigate the issue by watching the disconnect progress  before
/// restarting.
///
/// Note: As of the time of this implementation we must restart the VPN extension
/// in order for changes to the configuration file to take effect.  If in the future
/// this no longer necessary then this functionality can be removed.
///
class OrchidRestartManager {
  static OrchidRestartManager _shared = OrchidRestartManager._init();

  final BehaviorSubject<bool> restarting = BehaviorSubject.seeded(false);

  OrchidRestartManager._init();

  factory OrchidRestartManager() {
    return _shared;
  }

  StreamSubscription<bool>? _enableVPNListener;
  bool _initialized = false;

  /// Monitor user preferences and start or stop the VPN extension.
  initVPNControlListener() async {
    if (_enableVPNListener != null) {
      return;
    }
    // Listen for changes in monitoring preferences
    _enableVPNListener = CombineLatestStream.combine2(
      // The initial values are both valid on startup and distinct
      UserPreferencesVPN().routingEnabled.stream().distinct(),
      UserPreferencesVPN().monitoringEnabled.stream().distinct(),
      (routing, monitoring) {
        log("restart_manager: enable vpn listener: routing=$routing, monitoring=$monitoring");
        return routing || monitoring;
      },
    ).listen((desiredRunning) async {
      await OrchidAPI().publishConfiguration();

      // On startup check the state of the world
      if (!_initialized) {
        _onStartup(desiredRunning);
        _initialized = true;
      } else {
        _onPreferenceChange(desiredRunning);
      }
    });
  }

  // On startup we will assume that the config is as we left it and only
  // reassert if we should be running or stopped (never restart).
  Future<void> _onStartup(bool desiredRunning) async {
    log("restart_manager: on startup: desired running = $desiredRunning");
    var api = OrchidAPI();
    switch (api.vpnExtensionStatus.value) {
      case OrchidVPNExtensionState.Invalid:
      // should probably re-check here
      case OrchidVPNExtensionState.Disconnecting:
      case OrchidVPNExtensionState.NotConnected:
        // stopping or stopped
        if (desiredRunning) {
          _start();
        }
        break;
      case OrchidVPNExtensionState.Connecting:
      case OrchidVPNExtensionState.Connected:
        // starting or started
        if (!desiredRunning) {
          _stop();
        }
        break;
    }
  }

  // On preference change we assume that the config has changed and we should
  // start, restart, or stop as necessary.
  Future<void> _onPreferenceChange(bool desiredRunning) async {
    log("restart_manager: on preference change: desired running = $desiredRunning");
    if (desiredRunning) {
      _startOrRestart();
    } else {
      _stop();
    }
  }

  Future<void> _startOrRestart() async {
    var api = OrchidAPI();
    switch (api.vpnExtensionStatus.value) {
      case OrchidVPNExtensionState.Invalid:
      case OrchidVPNExtensionState.NotConnected:
        _start();
        break;
      case OrchidVPNExtensionState.Disconnecting:
      case OrchidVPNExtensionState.Connecting:
      case OrchidVPNExtensionState.Connected:
        _restart();
        break;
    }
  }

  /// Restart cleanly the vpn extension.
  Future<void> _restart() async {
    log("restart_manager: restart");
    if (restarting.value) {
      return;
    }
    restarting.add(true);

    var api = OrchidAPI();
    // Stop the extension if needed.
    switch (api.vpnExtensionStatus.value) {
      case OrchidVPNExtensionState.Invalid:
      case OrchidVPNExtensionState.NotConnected:
      case OrchidVPNExtensionState.Disconnecting:
        log("restart_manager: no stop needed");
        break;
      case OrchidVPNExtensionState.Connecting:
      case OrchidVPNExtensionState.Connected:
        log("restart_manager: stop needed, stopping.");
        _stop();
        break;
    }

    _waitForDown();
  }

  void _waitForDown() async {
    log("restart_manager: wait for down");

    // TODO: Remove this once the Android native channel correctly reflects the OS VPN status
    if (OrchidPlatform.isAndroid) {
      log("restart_manager: XXX ARTIFICIAL DELAY: 5 sec");
      await Future.delayed(Duration(seconds: 5));
    }

    var api = OrchidAPI();
    // Wait for a non-connected state before restarting.
    StreamSubscription<OrchidVPNExtensionState>? sub;
    sub = api.vpnExtensionStatus.stream
        .timeout(Duration(seconds: 30))
        .listen((state) async {
      switch (state) {
        case OrchidVPNExtensionState.Invalid:
        case OrchidVPNExtensionState.Connecting:
        case OrchidVPNExtensionState.Connected:
        case OrchidVPNExtensionState.Disconnecting:
          log("restart_manager: still waiting for restart (down): $state");
          break;
        case OrchidVPNExtensionState.NotConnected:
          await _start();
          _waitForUp();
          sub?.cancel();
          break;
      }
    });
    sub.onError((err, stack) {
      log("restart_manager: Error waiting for vpn to restart (down): $err");
      sub?.cancel();
      restarting.add(false);
    });
  }

  void _waitForUp() async {
    log("restart_manager: wait for up");

    // TODO: Remove this once the Android native channel correctly reflects the OS VPN status
    if (OrchidPlatform.isAndroid) {
      log("restart_manager: XXX ARTIFICIAL DELAY: 5 sec");
      await Future.delayed(Duration(seconds: 5));
    }

    var api = OrchidAPI();
    StreamSubscription<OrchidVPNExtensionState>? sub;
    sub = api.vpnExtensionStatus.stream
        .timeout(Duration(seconds: 30))
        .listen((state) async {
      switch (state) {
        case OrchidVPNExtensionState.Invalid:
        case OrchidVPNExtensionState.Connecting:
        case OrchidVPNExtensionState.Disconnecting:
        case OrchidVPNExtensionState.NotConnected:
          log("restart_manager: still waiting for restart (up): $state");
          break;
        case OrchidVPNExtensionState.Connected:
          log("restart_manager: restart complete");
          restarting.add(false);
          sub?.cancel();
          break;
      }
    });
    sub.onError((err, stack) {
      log("restart_manager: Error waiting for vpn to restart (up): $err");
      sub?.cancel();
      restarting.add(false);
    });
  }

  // Start the extension
  Future<void> _start() {
    log("restart_manager: starting extension");
    return _checkPermissionAndSetVPNEnabled();
  }

  // Stop the extension
  Future<void> _stop() {
    log("restart_manager: stopping extension");
    return OrchidAPI().setVPNExtensionEnabled(false);
  }

  Future<void> _checkPermissionAndSetVPNEnabled() async {
    // Get the most recent status, blocking if needed.
    OrchidAPI().vpnPermissionStatus.take(1).listen((installed) async {
      log("restart_manager: current extension install state: $installed");
      if (installed) {
        log("restart_manager: already installed, enabling");
        return OrchidAPI().setVPNExtensionEnabled(true);
      } else {
        bool ok = await OrchidAPI().requestVPNPermission();
        if (ok) {
          log("restart_manager: user chose to install");
          // Note: It appears that trying to enable the connection too quickly
          // Note: after installing the vpn permission / config fails.
          // Note: Introducing a short artificial delay.
          return Future.delayed(Duration(milliseconds: 500)).then((_) {
            log("restart_manager: starting extension");
            OrchidAPI().setVPNExtensionEnabled(true);
          });
        } else {
          log("restart_manager: user skipped");
        }
      }
    });
  }

  /*
  /// Return true if the new settings for one or more of the specified features
  /// would require a restart.
  Future<bool> wouldRequireRestart({bool forMonitoring, bool forRouting}) async {
    var isMonitoring = await UserPreferences().monitoringEnabled.value;
    var isRouting = await UserPreferences().routingEnabled.value;

    if (forMonitoring )
    if (forMonitoring != null) {
      return forMonitoring || isRouting;
    }
    if (forRouting != null) {
      return forRouting || isMonitoring;
    }
  }
   */

  void dispose() {
    _enableVPNListener?.cancel();
    _enableVPNListener = null;
  }
}
