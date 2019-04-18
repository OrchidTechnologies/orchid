import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:rxdart/rxdart.dart';

/// A controller for the [VPNCredentialsEntry] supporting observation of validation
/// and triggering of save functionality.
class VPNCredentialsEntryController {
  BehaviorSubject<bool> readyToSave = BehaviorSubject<bool>.seeded(false);
  Future<bool> Function() save;

  void dispose() {
    readyToSave.close();
  }
}

/// A form for entering (partner) VPN credentials and interacting with the
/// Orchid API.  Use [VPNCredentialsEntryController] to observe the state of
/// input validation and trigger the save operation (e.g. in support of an external
/// "save" button)
class VPNCredentialsEntry extends StatefulWidget {
  final VPNCredentialsEntryController controller;

  VPNCredentialsEntry({@required this.controller});

  @override
  _VPNCredentialsEntryState createState() => _VPNCredentialsEntryState();
}

class _VPNCredentialsEntryState extends State<VPNCredentialsEntry> {
  // Text field state
  final _userNameTextController = TextEditingController();
  final _userNameText = BehaviorSubject<String>();
  final _passwordTextController = TextEditingController();
  final _passwordText = BehaviorSubject<String>();

  // If the user has stored a vpn config this is the public portion.
  VPNConfigPublic _vpnConfigPublic;

  @override
  void initState() {
    super.initState();

    widget.controller.save = _save;

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
      widget.controller.readyToSave.add(enabled);
    });

    // Get any current configuration.
    OrchidAPI().getExitVPNConfig().then((VPNConfigPublic config) {
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
  Widget build(BuildContext context) {
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

  Future<bool> _save() {
    // dismiss the keyboard if present
    FocusScope.of(context).requestFocus(FocusNode());

    // Save the credentials
    var private = VPNConfigPrivate(userPassword: _passwordTextController.text);
    String vpnConfig = null;
    VPNConfigPublic public = VPNConfigPublic(
        id: "vpnConfig",
        userName: _userNameTextController.text,
        vpnConfig: vpnConfig);

    return OrchidAPI()
        .setExitVPNConfig(VPNConfig(private: private, public: public))
        .then((bool saved) {
      debugPrint("vpn config save result: $saved");
      widget.controller.readyToSave.add(false);
      if (saved) {
        _vpnConfigPublic = public;
        return _showCredentialsSavedDialog().then((_) {
          return true;
        });
      } else {
        _showCredentialsSaveFailedDialog().then((_) {
          return false;
        });
      }
    });
  }

  Future<void> _showCredentialsSavedDialog() {
    return Dialogs.showAppDialog(
        context: context,
        title: "VPN Credentials Saved!",
        body: "Your credentials have been saved.");
  }

  Future<void> _showCredentialsSaveFailedDialog() {
    return Dialogs.showAppDialog(
        context: context,
        title: "Whoops!",
        body:
        "Orchid was unable to save your credentials.\n\nPlease check and make sure the information you entered was correct.");
  }
}
