import 'package:flutter/material.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/link_text.dart';

class WelcomeDialog {
  static Future<void> show({
    @required BuildContext context,
  }) {
    var bodyStyle = TextStyle(fontSize: 16, color: Color(0xff504960));
    var richText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text:
                "Connecting to the Orchid network requires an Orchid account.  Visit ",
            style: bodyStyle),
        LinkTextSpan(
          text: "Orchid.com/join",
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://orchid.com/join',
        ),
      ],
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: Text("Welcome to Orchid!", style: AppText.dialogTitle),
          content: RichText(text: richText),
          actions: <Widget>[
            FlatButton(
              child: Text("OK", style: AppText.dialogButton),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
