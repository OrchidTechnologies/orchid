import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accomodate_keyboard.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class HelpFeedbackPage extends StatefulWidget {
  @override
  _HelpFeedbackPageState createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Feedback", child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AccommodateKeyboard(
        child: Column(
          children: <Widget>[
            SizedBox(height: 35),

            // Email entry
            new AppLabeledTextField(labelText: "Email address"),
            SizedBox(height: 5),
            Text("Optional. So we can contact you about this issue.",
                style: AppText.noteStyle),
            SizedBox(height: 23),

            // Report text entry
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              height: 100,
              decoration: AppTextField.textFieldEnabledDecoration,
              child: TextField(
                style: AppText.logStyle,
                maxLines: null,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        "Bug? Feature suggestion? Issue? Complement? Let us know!",
                    hintMaxLines: 10),
              ),
            ),
            SizedBox(height: 29),
            
            // Log switch
            Row(children: <Widget>[
              Switch(
                activeColor: AppColors.purple_3,
                value: true,
                onChanged: (bool value) {},
              ),
              Text("Send Log", style: AppText.switchLabelStyle)
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 48.0, right: 12.0),
              child: Text(
                  "Your log files will help us diagnose and fix and issue you have."
                  " Your log files do not contain and personal or identifying information."
                  " They do contain your IP address.",
                      style: AppText.noteStyle.copyWith(color: AppColors.neutral_3)
              ),
            ),
            Spacer(),
            SizedBox(height: 20),

            // Send button
            Container(
              width: 320,
              height: 43,
              child: RoundedRectRaisedButton(
                text: "SEND",
                //onPressed: () {},
                onPressed: null
              ),
            ),
            SizedBox(height: 41)
          ],
        ),
      ),
    );
  }
}
