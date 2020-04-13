import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/common/accommodate_keyboard.dart';
import 'package:orchid/pages/common/name_value_setting.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/connect/connect_page.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
//import 'package:orchid/pages/settings/developer_settings.dart';

/// The developer settings page
class SettingsDevPage extends StatefulWidget {
  @override
  _SettingsDevPage createState() => _SettingsDevPage();
}

class _SettingsDevPage extends State<SettingsDevPage> {
  @override
  Widget build(BuildContext context) {
    // Dismiss the keyboard on tap outside of the text areas.
    // (The body text has a "Return" button instead of a "Done").
    return new TapClearsFocus(
        child: TitledPage(title: "Developer", child: buildPage(context)));
  }

  String _mockAPIStatus() {
    return OrchidAPI.mockAPI ? "enabled" : "disabled";
  }

  List<NameValueSetting> _developerSettings = [];

  @override
  void initState() {
    super.initState();

    var api = OrchidAPI();

  //    api.getDeveloperSettings().then((Map<String, String> settingsMap) {
  //      setState(() {
  //        _developerSettings = DeveloperSettings.fromMap(settingsMap,
  //            onChanged: api.setDeveloperSetting);
  //      });
  //    });
  }

  @override
  Widget buildPage(BuildContext context) {
    return AccommodateKeyboard(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 16),

            // The mock API control switch
            _buildSwitch(
                title: "Mock API: " + _mockAPIStatus(),
                initialValue: OrchidAPI.mockAPI,
                onChanged: (bool value) {
                  setState(() {
                    OrchidAPI.mockAPI = value;
                    OrchidAPI().logger().write("Mock API: " + _mockAPIStatus());
                  });
                }),

            // experimental scrolling
            _buildSwitch(
                title: "Connect Screen Scrolls",
                initialValue: QuickConnectPage.allowScrolling,
                onChanged: (bool value) {
                  setState(() {
                    QuickConnectPage.allowScrolling = value;
                  });
                }),

            // Allow running the onboarding flow again.
            _buildButton(
                label: "Re-run onboarding",
                onPressed: () => _rerunOnboarding()),

            SizedBox(height: 16),

            // Dynamic set of controls driven by the developer settings API
            Column(children: _developerSettings)
          ],
        ),
      ),
    );
  }

  Container _buildButton({String label, VoidCallback onPressed}) {
    return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20, top: 8.0),
        child: RaisedButton(child: Text(label), onPressed: onPressed));
  }

  Padding _buildSwitch(
      {String title, bool initialValue, ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        height: 56,
        child: PageTile(
          //color: AppColors.white,
          color: Colors.transparent,
          title: title,
          onTap: () {},
          trailing: Switch(
            activeColor: AppColors.purple_3,
            value: initialValue,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  void _rerunOnboarding() async {
    await AppOnboarding().reset();
    AppOnboarding().showPageIfNeeded(context);
  }
}
