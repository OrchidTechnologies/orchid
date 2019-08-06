import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/common/side_drawer.dart';
import 'package:orchid/pages/monitoring/traffic_view.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
import 'package:orchid/pages/onboarding/onboarding_vpn_permission_page.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_transitions.dart';

class MonitoringPage extends StatefulWidget {
  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {

  @override
  void initState() {
    super.initState();
    // Show the initial walkthrough screens if needed.
    AppOnboarding().showPageIfNeeded(context);
    _initListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orchid Monitoring"),
        actions: <Widget>[_buildSwitch()],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
        child: Container(
            margin: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: TrafficView()),
      ),
      drawer: SideDrawer(),
    );
  }

  Switch _buildSwitch() {
    var _currentStatus = OrchidAPI().connectionStatus.value ?? OrchidConnectionState.NotConnected;
    return Switch(
      activeColor: AppColors.purple_5,
      // TODO: We should replace this switch with something that represents the
      // TODO: connecting state as well.
      // Note: The switch has some weird requirements that complicate this logic.
      // Note: If the user toggles it to "on" we must rebuild it with the "true"
      // Note: value before it can be toggled off again programmatically.
      // Note: This makes a failed "connecting" state problematic.  So I have
      // Note: inverted the logic to show connected immediately and fall back.
      value: _currentStatus != OrchidConnectionState.NotConnected,
      onChanged: (bool newSwitchValue) {
        switch (_currentStatus) {
          case OrchidConnectionState.NotConnected:
            if (newSwitchValue == true) {
              OrchidAPI().setConnected(true);
            }
            break;
          case OrchidConnectionState.Connecting:
          case OrchidConnectionState.Connected:
            if (newSwitchValue == false) {
              OrchidAPI().setConnected(false);
            }
            break;
        }
      },
    );
  }

  /// Listen for changes in Orchid network status.
  void _initListeners() {
    OrchidAPI().logger().write("Init listeners...");

    // Monitor VPN permission status
    OrchidAPI().vpnPermissionStatus.listen((bool installed) {
      OrchidAPI().logger().write("VPN Perm status changed: $installed");

      // Ignore changes until the first walkthrough has been completed
      //bool walkthroughCompleted = await UserPreferences().getWalkthroughCompleted();

      if (!installed /*&& walkthroughCompleted*/) {
        String currentPage = ModalRoute.of(context).settings.name;
        OrchidAPI().logger().write("Current page: $currentPage");
        var route = AppTransitions.downToUpTransition(
            OnboardingVPNPermissionPage(allowSkip: false));
        Navigator.push(context, route);
      }
    });

    // Monitor connection status
    OrchidAPI().connectionStatus.listen((OrchidConnectionState state) {
      OrchidAPI().logger().write("Connection status changed: $state");
      // Update the UI
      setState(() { });
    });
  }
}
