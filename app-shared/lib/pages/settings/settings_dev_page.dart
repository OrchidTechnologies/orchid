import 'package:flutter/material.dart';
import 'package:orchid/pages/app_transitions.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';

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
              child: Text("Re-run walkthrough"),
              onPressed: () {
                Navigator.push(context,
                    AppTransitions.downToUpTransition(WalkthroughPages()));
              }),
        ),
      ],
    );
  }
}
