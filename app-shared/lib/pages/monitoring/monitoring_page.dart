import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/monitoring/traffic_view.dart';
import 'package:orchid/pages/onboarding/onboarding_vpn_permission_page.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_transitions.dart';

// TODO: Remove if this remains unused.
// This page wraps the traffic monitor and offers a switch to enable the VPN.
// It also guards the state of the vpn extension installation.
class MonitoringPage extends StatefulWidget {
  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  List<StreamSubscription> _rxSubscriptions = List();

  @override
  void initState() {
    super.initState();
    // Show the initial walkthrough screens if needed.
    //AppOnboarding().showPageIfNeeded(context);
    _initListeners();
  }

  /// Listen for changes in Orchid network status.
  void _initListeners() {
    OrchidAPI().logger().write("Traffic Monitor: Init listeners...");

    //_monitorVPNStatus();

    // Monitor connection status
    _rxSubscriptions
        .add(OrchidAPI().connectionStatus.listen((OrchidConnectionState state) {
      OrchidAPI().logger().write("Connection status changed: $state");
      // Update the UI
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
      child: Container(child: TrafficView()),
    );
  }

  Switch _buildSwitch() {
    var currentValue = OrchidAPI().connectionStatus.value ??
        OrchidConnectionState.Invalid;
    bool switchOn = false;
    switch (currentValue) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
      case OrchidConnectionState.Disconnecting:
        switchOn = true;
    }
    return Switch(
        activeColor: AppColors.purple_5,
        // TODO: We should replace this switch with something that represents the
        // TODO: connecting state as well.
        // Note: The switch has some weird requirements that complicate this logic.
        // Note: If the user toggles it to "on" we must rebuild it with the "true"
        // Note: value before it can be toggled off again programmatically.
        // Note: This makes a failed "connecting" state problematic.  So I have
        // Note: inverted the logic to show connected immediately and fall back.
        value: switchOn,
        onChanged: (bool newValue) {
          _switchChanged(currentValue, newValue);
        });
  }

  void _switchChanged(OrchidConnectionState currentConnectionState, bool desiredEnabled) {
    switch (currentConnectionState) {
      case OrchidConnectionState.Disconnecting:
        // TODO: We should reject the switch change in this case.
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
        if (desiredEnabled == true) {
          _checkPermissionAndEnableConnection();
        }
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
        if (desiredEnabled == false) {
          _disableConnection();
        }
        break;
    }
  }

  void _checkPermissionAndEnableConnection() {
    // Get the most recent status, blocking if needed.
    _rxSubscriptions
        .add(OrchidAPI().vpnPermissionStatus.take(1).listen((installed) async {
      debugPrint("vpn: current perm: $installed");
      if (installed) {
        debugPrint("vpn: already installed");
        OrchidAPI().setConnected(true);
        setState(() {});
      } else {
        bool ok = await OrchidAPI().requestVPNPermission();
        if (ok) {
          debugPrint("vpn: user chose to install");
          // Note: It appears that trying to enable the connection too quickly
          // Note: after installing the vpn permission / config fails.
          // Note: Introducing a short artificial delay.
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            OrchidAPI().setConnected(true);
          });
        } else {
          debugPrint("vpn: user skipped");
        }
      }
    }));
  }

  void _disableConnection() {
    OrchidAPI().setConnected(false);
  }

  // Continously monitor VPN permission status and show the permission page as needed.
  void _monitorVPNStatus() {
    _rxSubscriptions.add(
        OrchidAPI().vpnPermissionStatus.distinct().listen((bool installed) {
      OrchidAPI().logger().write("VPN Perm status changed: $installed");
      if (!installed) {
        _showVPNPermissionPage();
      }
    }));
  }

  void _showVPNPermissionPage(
      {bool allowSkip = false, Function(bool) onComplete}) {
    var route = AppTransitions.downToUpTransition(OnboardingVPNPermissionPage(
      allowSkip: allowSkip,
      onComplete: onComplete,
    ));
    Navigator.push(context, route);
  }

  @override
  void dispose() {
    super.dispose();
    _rxSubscriptions.forEach((sub) {
      sub.cancel();
    });
  }
}
