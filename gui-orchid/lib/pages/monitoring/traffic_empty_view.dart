import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import '../../common/app_colors.dart';
import '../../common/app_text.dart';

class TrafficEmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    S s = S.of(context);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Center(
          child: SafeArea(
            child: Padding(
                padding: EdgeInsets.only(left: 36, right: 36),
                child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: StreamBuilder<bool>(
                        stream: UserPreferences().monitoringEnabled.stream(),
                        builder: (context, snapshot) {
                          if (snapshot.data == null) {
                            return Container();
                          }
                          bool monitoring = snapshot.data;
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey<String>(
                                  "welcome:$monitoring:$orientation"),
                              children: <Widget>[
                                Spacer(flex: 2),
                                AppText.header(
                                    text: "Analyze Your Connections",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.0),
                                SizedBox(height: 20),
                                AppText.body(
                                    text: !monitoring
                                        ? "Network analysis uses your device's VPN facility to capture packets and analyze your traffic.  Network analysis requires VPN permissions but does not by itself protect your data or hide your IP address.  To get the benefits of network privacy you must configure and activate a VPN connection from the home screen."
                                                "\n\n   " +
                                            "Turning on this feature will increase the battery usage of the Orchid App."
                                        : s.nothingToDisplayYet,
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
