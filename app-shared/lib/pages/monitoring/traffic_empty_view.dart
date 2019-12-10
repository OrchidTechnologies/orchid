import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import '../app_colors.dart';
import '../app_text.dart';

class TrafficEmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Center(
          child: SafeArea(
            child: Padding(
                padding: EdgeInsets.only(left: 36, right: 36),
                child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: StreamBuilder<OrchidConnectionState>(
                        stream: OrchidAPI().connectionStatus,
                        builder: (context, snapshot) {
                          var state = OrchidAPI().connectionStatus.value;
                          bool connected;
                          switch (state) {
                            case OrchidConnectionState.Invalid:
                            case OrchidConnectionState.NotConnected:
                              connected = false;
                              break;
                            case OrchidConnectionState.Connecting:
                            case OrchidConnectionState.Connected:
                            case OrchidConnectionState.Disconnecting:
                              connected = true;
                              break;
                          }

                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey<String>(
                                  "welcome:$connected:$orientation"),
                              children: <Widget>[
                                Spacer(flex: 1),
                                AppText.header(
                                    text: "Welcome to Orchid",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28.0),
                                SizedBox(height: 20),
                                AppText.body(
                                    text: !connected
                                        ? "This release is Orchid’s advanced VPN client, supporting multi-hop and local traffic analysis.\n\n   To get started, enable the VPN.   "
                                        : "Nothing to display yet. Traffic will appear here when there’s something to show.",
                                    fontSize: 15.0,
                                    color: AppColors.neutral_1),
                                Spacer(flex: 1),
                                Visibility(
                                  visible: orientation == Orientation.portrait,
                                  child: Image.asset(
                                    "assets/images/analysisBunny.png",
                                    height: 330,
                                  ),
                                ),
                                Spacer(flex: 1),
                              ],
                            ),
                          );
                        }))),
          ),
        );
      },
    );
  }
}
