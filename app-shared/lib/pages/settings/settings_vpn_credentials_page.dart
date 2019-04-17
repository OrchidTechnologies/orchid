import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accomodate_keyboard.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:rxdart/rxdart.dart';

class SettingsVPNCredentialsPage extends StatefulWidget {
  @override
  _SettingsVPNCredentialsPage createState() => _SettingsVPNCredentialsPage();
}

class _SettingsVPNCredentialsPage extends State<SettingsVPNCredentialsPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "VPN credentials", child: buildPage(context));
  }

  final _api = OrchidAPI();

  // Text field state
  final _userNameTextController = TextEditingController();
  final _userNameText = BehaviorSubject<String>();
  final _passwordTextController = TextEditingController();
  final _passwordText = BehaviorSubject<String>();
  bool _saveButtonEnabled = false;

  // If the user has stored a vpn config this is the public portion.
  VPNConfigPublic _vpnConfigPublic;

  @override
  void initState() {
    super.initState();

    _userNameTextController
        .addListener(() => _userNameText.add(_userNameTextController.text));
    _passwordTextController
        .addListener(() => _passwordText.add(_passwordTextController.text));

    // Validate the form data and update the save button.
    Observable.combineLatest2(_userNameText, _passwordText,
        (String userName, String password) {
      // TODO: update validation
      return userName.length > 2 && password.length > 2;
    }).listen((enabled) {
      setState(() {
        _saveButtonEnabled = enabled;
      });
    });

    // Get any current configuration.
    _api.getExitVPNConfig().then((VPNConfigPublic config) {
      if (config == null) {
        return;
      }
      _userNameTextController.text = config.userName;
      setState(() {
        this._vpnConfigPublic = config;
      });
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AccommodateKeyboard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          screenWidth > 640 ? Spacer(flex: 1) : Container(),
          Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 15),
              child: AppText.body(
                textAlign: TextAlign.left,
                text:
                    "For Alpha, we have partnered with [VPN Partner]. Enter your login credentials below and when you connect Orchid will pair you with the best available server.",
              )),

          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    style: AppText.bodyStyle,
                    text: "Don't have a [VPN Partner] account?\n",
                  ),
                  LinkTextSpan(
                    text: "Sign up for a free trial.",
                    style: AppText.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.teal_3),
                    url: 'https://orchid.com',
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16),
            child: AppText.header(
                textAlign: TextAlign.left,
                text: "[VPN Partner] credentials",
                fontSize: 16.0),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: buildForm(context),
          ),

          // Move Save to the bottom
          Spacer(),
          SizedBox(height: 24),

          Spacer(flex: 3),
          // Save button
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 62),
              child: RoundedRectRaisedButton(
                  text: "SAVE",
                  onPressed: _saveButtonEnabled ? _onSaveButtonPressed : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildForm(BuildContext context) {
    return Column(
      children: <Widget>[
        // username
        buildFormField(
            context: context,
            hintText: "Username",
            controller: _userNameTextController),
        // password
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: buildPasswordFormField(
              context: context,
              hintText: _vpnConfigPublic == null ? "Password" : "xxxxxxxxxx",
              controller: _passwordTextController),
        ),
      ],
    );
  }

  Widget buildPasswordFormField(
      {BuildContext context,
      String hintText,
      TextEditingController controller}) {
    return buildFormField(
        context: context,
        hintText: hintText,
        controller: controller,
        obscureText: true,
        trailing: Container(
            margin: EdgeInsets.only(right: 13.0),
            child: Image.asset("assets/images/visibility.png")));
  }

  Widget buildFormField(
      {BuildContext context,
      String hintText,
      Widget trailing,
      TextEditingController controller,
      bool obscureText = false}) {
    return Container(
        decoration: BoxDecoration(
            color: Color(0xfffbfbfe),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Color(0xffd5d7e2), width: 2.0)),
        height: 56,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  obscureText: obscureText,
                  controller: controller,
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: AppText.hintStyle),
                  onChanged: null,
                  focusNode: null,
                ),
              ),
            ),
            trailing != null ? trailing : SizedBox(),
          ],
        ));
  }

  void _onSaveButtonPressed() {
    // dismiss the keyboard if present
    FocusScope.of(context).requestFocus(FocusNode());

    // Save the credentials
    var private = VPNConfigPrivate(userPassword: _passwordTextController.text);
    String vpnConfig = null;
    var public = VPNConfigPublic(
        id: "vpnConfig",
        userName: _userNameTextController.text,
        vpnConfig: vpnConfig);
    _api
        .setExitVPNConfig(VPNConfig(private: private, public: public))
        .then((bool saved) {
      debugPrint("vpn config saved");
      setState(() {
        _saveButtonEnabled = false;
      });
      if (saved) {
        _vpnConfigPublic = public;
        _showCredentialsSavedDialog(context);
      } else {
        _showCredentialsSaveFailedDialog(context);
      }
    });
  }

  void _showCredentialsSavedDialog(@required BuildContext context) {
    Dialogs.showAppDialog(
        context: context,
        title: "VPN Credentials Saved!",
        body: "Your credentials have been saved.");
  }

  void _showCredentialsSaveFailedDialog(@required BuildContext context) {
    Dialogs.showAppDialog(
        context: context,
        title: "Whoops!",
        body:
            "Orchid was unable to save your credentials.\n\nPlease check and make sure the information you entered was correct.");
  }
}
