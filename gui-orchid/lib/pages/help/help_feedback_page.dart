import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accommodate_keyboard.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:rxdart/rxdart.dart';
import 'package:email_validator/email_validator.dart';

class HelpFeedbackPage extends StatefulWidget {
  @override
  _HelpFeedbackPageState createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  // TODO: Is there a better way to bridge TextEditingController to rxdart?
  final _emailTextController = TextEditingController();
  final _emailText = BehaviorSubject<String>();
  final _bodyTextController = TextEditingController();
  final _bodyText = BehaviorSubject<String>();
  bool _sendLog = true;
  bool _readyToSend = false;

  @override
  void initState() {
    super.initState();

    _emailTextController.addListener(() {
      // suppress extraneous change events
      if (_emailTextController.text != _emailText.value) {
        _emailText.add(_emailTextController.text);
      }
    });
    _bodyTextController.addListener(() {
      if (_bodyTextController.text != _bodyText.value) {
        _bodyText.add(_bodyTextController.text);
      }
    });

    // Validate the form data and update the send button.
    Rx.combineLatest2(_emailText, _bodyText,
        (String emailText, String bodyText) {
      bool emailValid = EmailValidator.validate(emailText);
      return emailValid && bodyText.length > 3;
    }).listen((enabled) {
      setState(() {
        debugPrint("status changed: $enabled");
        _readyToSend = enabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss the keyboard on tap outside of the text areas.
    // (The body text has a "Return" button instead of a "Done").
    return TapClearsFocus(
        child: TitledPage(title: "Feedback", child: buildPage(context)));
  }

  Widget buildPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AccommodateKeyboard(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(height: 35),

              // Email field
              new AppLabeledTextField(
                  controller: _emailTextController,
                  labelText: "Email address",
                  // TODO: Why isn't this working?
                  validator: (String email) {
                    debugPrint("validator invoked");
                    if (!EmailValidator.validate(email)) {
                      return "Invalid email";
                    }
                  },
                  textInputType: TextInputType.emailAddress),
              SizedBox(height: 5),
              Text("Optional. So we can contact you about this issue.",
                  style: AppText.noteStyle),
              SizedBox(height: 23),

              // Report text field
              Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                height: 100,
                decoration: AppTextField.textFieldEnabledDecoration,
                child: TextField(
                  controller: _bodyTextController,
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
                  value: _sendLog,
                  onChanged: (bool value) {
                    _sendLog = value;
                  },
                ),
                Text("Send Log", style: AppText.switchLabelStyle)
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 48.0, right: 12.0),
                child: Text(
                    "Your log files will help us diagnose and fix and issue you have."
                    " Your log files do not contain and personal or identifying information."
                    " They do contain your IP address.",
                    style:
                        AppText.noteStyle.copyWith(color: AppColors.neutral_3)),
              ),
              Spacer(),
              SizedBox(height: 20),

              // Send button
              Container(
                width: 320,
                height: 43,
                child: RoundedRectButton(
                    text: "SEND", onPressed: _readyToSend ? _send : null),
              ),
              SizedBox(height: 41)
            ],
          ),
        ),
      ),
    );
  }

  void _send() async {
    setState(() {
      // dismiss the keyboard if present
      FocusScope.of(context).requestFocus(FocusNode());
      _readyToSend = false;
    });
    _showFeedbackSentDialog();
  }

  Future<void> _showFeedbackSentDialog() {
    return AppDialogs.showAppDialog(
        context: context,
        title: "Feedback Sent!",
        bodyText: "Your feedback has been submitted.");
  }
}
