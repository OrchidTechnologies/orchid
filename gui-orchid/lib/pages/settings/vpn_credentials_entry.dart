import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/app_text_field.dart';
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
  final _vpnConfigFileTextController = TextEditingController();
  final _vpnConfigFileText = BehaviorSubject<String>.seeded(null);

  // If the user has stored a vpn config this is the public portion.
  VPNConfigPublic _vpnConfigPublic;

  @override
  void initState() {
    super.initState();

    _passwordTextController.addListener(() {
      setState(() {}); // Update the UI on focus changes
    });

    widget.controller.save = _save;

    _userNameTextController.addListener(() {
      if (_userNameTextController.text != _userNameText.value) {
        _userNameText.add(_userNameTextController.text);
      }
    });
    _passwordTextController.addListener(() {
      if (_passwordTextController.text != _passwordText.value) {
        _passwordText.add(_passwordTextController.text);
      }
    });

    _vpnConfigFileTextController.addListener(() {
      if (_vpnConfigFileTextController.text != _vpnConfigFileText.value) {
        _vpnConfigFileText.add(_vpnConfigFileTextController.text);
      }
    });

    // Validate the form data and update the save button.
    Rx.combineLatest3(_userNameText, _passwordText, _vpnConfigFileText,
        (String userName, String password, String vpnConfigFileText) {
      debugPrint("config text: $vpnConfigFileText");
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
      _vpnConfigFileTextController.text = config.vpnConfig;
      setState(() {
        this._vpnConfigPublic = config;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[

          // Username
          AppLabeledTextField(
              labelText: s.username, controller: _userNameTextController),
          SizedBox(height: 12),

          // Password
          AppPasswordField(
              labelText: s.password,
              // TODO: We need the password field's focus node to do this
              // Switch the label to a hint text showing fake obscured password.
              //hintText: _vpnConfigPublic == null ? null : "xxxxxxxxxx",
              controller: _passwordTextController),
          SizedBox(height: 12),

          // VPN config text file
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 0, maxHeight: 365),
            child: IntrinsicHeight(
              child: AppLabeledTextField(
                  //hintText: "Paste OVPN file contents",
                  labelText: s.pasteYourOVPN,
                  maxLines: null, // unlimited
                  controller: _vpnConfigFileTextController),
            ),
          ),

          // Instructional text associated with the above text field
          // TODO: If we use this again integrate it into AppLebeledTextField
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 5.0),
              child: Text(s.optional,
                  textAlign: TextAlign.left,
                  style: AppText.noteStyle.copyWith(color: AppColors.neutral_1)),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> _save() {
    // dismiss the keyboard if present
    FocusScope.of(context).requestFocus(FocusNode());

    // Save the credentials
    var private = VPNConfigPrivate(userPassword: _passwordTextController.text);
    VPNConfigPublic public = VPNConfigPublic(
        id: "vpnConfig",
        userName: _userNameTextController.text,
        vpnConfig: _vpnConfigFileTextController.text);

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
    return AppDialogs.showAppDialog(
        context: context,
        title: "VPN Credentials Saved!",
        bodyText: "Your credentials have been saved.");
  }

  Future<void> _showCredentialsSaveFailedDialog() {
    return AppDialogs.showAppDialog(
        context: context,
        title: "Whoops!",
        bodyText:
            "Orchid was unable to save your credentials.\n\nPlease check and make sure the information you entered was correct.");
  }
}
