import 'package:flutter/material.dart';
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

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(20),
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
