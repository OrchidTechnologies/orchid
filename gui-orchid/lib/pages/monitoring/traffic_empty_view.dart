import 'package:flutter/material.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/localization.dart';

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
                    child: StreamBuilder<bool>(
                        stream: UserPreferencesVPN().monitoringEnabled.stream(),
                        builder: (context, snapshot) {
                          if (snapshot.data == null) {
                            return Container();
                          }
                          bool monitoring = snapshot.data!;
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
                                        ? context.s.analyzingYourConnections
                                        : context.s.analyzeYourConnections,
                                    textAlign: TextAlign.center,
                                    style: OrchidText.medium_24_050),
                                SizedBox(height: 20),
                                Text(
                                  !monitoring
                                      ? context.s.networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets +
                                          '  ' +
                                          context.s.networkAnalysisRequiresVpnPermissionsButDoesNotByItself +
                                          '  ' +
                                          context.s.toGetTheBenefitsOfNetworkPrivacyYouMustConfigure +
                                          '\n\n' +
                                          context.s.turningOnThisFeatureWillIncreaseTheBatteryUsageOf
                                      : context.s.nothingToDisplayYet,
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
