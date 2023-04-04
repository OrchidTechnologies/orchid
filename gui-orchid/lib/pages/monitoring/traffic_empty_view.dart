// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_text.dart';

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
                                  'welcome:$monitoring:$orientation'),
                              children: <Widget>[
                                Spacer(flex: 1),
                                Visibility(
                                  visible: orientation == Orientation.portrait,
                                  child: OrchidAsset.svg.inspector_icon,
                                ),
                                Spacer(flex: 1),
                                Text(
                                    monitoring
                                        ? s.analyzingYourConnections
                                        : s.analyzeYourConnections,
                                    textAlign: TextAlign.center,
                                    style: OrchidText.medium_24_050),
                                SizedBox(height: 20),
                                Text(
                                  !monitoring
                                      ? s.networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets +
                                          '  ' +
                                          s.networkAnalysisRequiresVpnPermissionsButDoesNotByItself +
                                          '  ' +
                                          s.toGetTheBenefitsOfNetworkPrivacyYouMustConfigure +
                                          '\n\n' +
                                          s.turningOnThisFeatureWillIncreaseTheBatteryUsageOf
                                      : s.nothingToDisplayYet,
                                  textAlign: TextAlign.center,
                                  style: OrchidText.body1.copyWith(height: 1.5),
                                ),
                                Spacer(flex: 4),
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
