import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/log_file.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class SettingsLogPage extends StatefulWidget {
  @override
  _SettingsLogPage createState() => _SettingsLogPage();
}

class _SettingsLogPage extends State<SettingsLogPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Logging", child: buildPage(context));
  }

  String _logText = "Loading ...";
  StreamSubscription<void> _logListener;

  @override
  void initState() {
    super.initState();

    // Listen for changes in the log file
    _logListener = LogFile().logChanged.listen((_) {
      LogFile().get().then((String text) {
        setState(() {
          _logText = text;
        });
      });
    });
    LogFile().logChanged.add(null); // trigger an update
  }


  @override
  void dispose() {
    super.dispose();
    if (_logListener != null) {
      _logListener.cancel();
      _logListener = null;
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    var privacyText =
        "Your log file is stored locally and contains your IP address but does not contain personal or identifying information.";

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            // The logging control switch
            Container(
              color: AppColors.white,
              height: 56,
              child: PageTile(
                title: "Logging enabled",
                imageName: "assets/images/assignment.png",
                onTap: () {},
                trailing: Switch(
                  activeColor: AppColors.purple_3,
                  value: true,
                  //onChanged: (bool value) {},
                  onChanged: null,
                ),
              ),
            ),

            Container(height: 1, color: AppColors.grey_1.withAlpha((0.12*255).round()),),

            // Privacy description
            Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                child: AppText.body(
                  color: Color(0xff524862),
                  textAlign: TextAlign.left,
                  text: privacyText,
                )),

            // The log text view
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 32),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      _logText,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: "VT323", fontSize: 16.0),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 2.0, color: AppColors.neutral_5),
                  ),
                ),
              ),
            ),

            // The buttons row
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(0),
                      child: button(
                          title: "Copy",
                          imageName: "assets/images/business.png",
                          onPressed: _onCopyButton)),
                  Padding(
                      padding: const EdgeInsets.only(left: 0, right: 0),
                      child: button(
                          title: "Delete",
                          imageName: "assets/images/business.png",
                          onPressed: _confirmDelete)),
                  Padding(
                      padding: const EdgeInsets.all(0),
                      child: button(
                          title: "Save",
                          imageName: "assets/images/business.png",
                          onPressed: null /*_onSave*/)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget button({String title, String imageName, VoidCallback onPressed}) {
    return Column(
      children: <Widget>[
        RaisedButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.all(0),
          color: AppColors.purple_3,
          child: Column(
            children: <Widget>[
              Image.asset(imageName,
                  color: AppColors.white, width: 40, height: 40),
            ],
          ),
          onPressed: onPressed,
          shape: new CircleBorder(),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
              //height: 1.333,
              fontSize: 13,
              color: AppColors.purple_3),
        )
      ],
    );
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() {
    Clipboard.setData(ClipboardData(text: _logText));
  }

  void _performDelete() {
    LogFile().clear();
  }

  void _onSave() {}

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Delete Log Data"),
          content: new Text("Remove all log data?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                _performDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
