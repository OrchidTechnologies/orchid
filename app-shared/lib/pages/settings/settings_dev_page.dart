import 'package:flutter/material.dart';
import 'package:orchid/api/log_file.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/onboarding/app_onboarding.dart';

class SettingsDevPage extends StatefulWidget {
  @override
  _SettingsDevPage createState() => _SettingsDevPage();
}

class _SettingsDevPage extends State<SettingsDevPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Developer", child: buildPage(context));
  }

  String _mockAPIStatus() {
    return OrchidAPI.mockAPI ? "enabled" : "disabled";
  }

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The logging control switch
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 16.0),
          child: Container(
            color: AppColors.white,
            height: 56,
            child: PageTile(
              title: "Mock API " + _mockAPIStatus(),
              //imageName: "assets/images/assignment.png",
              onTap: () {},
              trailing: Switch(
                activeColor: AppColors.purple_3,
                value: OrchidAPI.mockAPI,
                onChanged: (bool value) {
                  setState(() {
                    OrchidAPI.mockAPI = !OrchidAPI.mockAPI;
                    LogFile().write("Mock API: " + _mockAPIStatus());
                  });
                },
              ),
            ),
          ),
        ),

        // Allow running the onboarding flow again.
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 20, top: 8.0),
          child: RaisedButton(
              child: Text("Re-run onboarding"),
              onPressed: () {
                _rerunOnboarding();
              }),
        ),
      ],
    );
  }

  void _rerunOnboarding() async {
    await AppOnboarding().reset();
    AppOnboarding().showPageIfNeeded(context);
  }
}
