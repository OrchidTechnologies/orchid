import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:rxdart/rxdart.dart';
import 'package:jsparser/jsparser.dart';

import '../app_colors.dart';
import '../app_text.dart';

/// A page presenting a full screen editable text box for the Orchid config file.
class AdvancedConfigurationPage extends StatefulWidget {
  @override
  _AdvancedConfigurationPageState createState() =>
      _AdvancedConfigurationPageState();
}

class _AdvancedConfigurationPageState extends State<AdvancedConfigurationPage> {
  String _configFileTextLast = "";
  BehaviorSubject<bool> _readyToSave = BehaviorSubject<bool>.seeded(false);
  final _configFileTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    OrchidAPI().getConfiguration().then((text) {
      setState(() {
        _configFileTextLast = text;
        _configFileTextController.text = text;
      });
    });

    _configFileTextController.addListener(() {
      var dirty = _configFileTextController.text != _configFileTextLast;
      _readyToSave.add(dirty);
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = s.advancedConfiguration;
    return TapClearsFocus(
        child: TitledPage(title: title, child: buildPage(context)));
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(0),
                    child: RoundTitledRaisedImageButton(
                        title: s.copy,
                        icon: Icon(Icons.copy, color: Colors.white, size: 20),
                        onPressed: _onCopy)),
                Padding(
                    padding: const EdgeInsets.all(0),
                    child: RoundTitledRaisedImageButton(
                        title: s.paste,
                        icon: Icon(Icons.paste, color: Colors.white, size: 20),
                        onPressed: _onPaste)),
                Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0),
                    child: RoundTitledRaisedImageButton(
                        title: s.clear,
                        icon: Icon(Icons.clear, color: Colors.white, size: 20),
                        onPressed: _onClear)),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 24),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SingleChildScrollView(
                      child: TextFormField(
                    autocorrect: false,
                    autofocus: false,
                    smartQuotesType: SmartQuotesType.disabled,
                    smartDashesType: SmartDashesType.disabled,
                    keyboardType: TextInputType.multiline,
                    style: AppText.logStyle.copyWith(color: AppColors.grey_2),
                    controller: _configFileTextController,
                    maxLines: 99999,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelStyle: AppText.textLabelStyle,
                    ),
                  )),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 2.0, color: AppColors.neutral_5),
                  ),
                ),
              ),
            ),

            // Save button
            Center(
              child: Container(
                child: StreamBuilder<Object>(
                    stream: _readyToSave.stream,
                    builder: (context, snapshot) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RoundedRectButton(
                              text: s.saveButtonTitle,
                              onPressed: _readyToSave.value ? _onSave : null),
                        ],
                      );
                    }),
              ),
            ),

            SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: _configFileTextController.text));
  }

  void _onPaste() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    setState(() {
      _configFileTextController.text = data.text;
    });
  }

  void _onClear() {
    setState(() {
      _configFileTextController.text = '';
    });
  }

  void _onSave() {
    var newConfig = _configFileTextController.text;
    try {
      // Just parse it to the AST to catch gross syntax errors.
      if (newConfig.trim().isNotEmpty) {
        parsejs(newConfig, filename: 'program.js');
      }
    } catch (err) {
      print("Error parsing config: $err");
      AppDialogs.showConfigurationChangeFailed(context,
          errorText: err.toString());
      return;
    }
    OrchidAPI().setConfiguration(newConfig).then((bool saved) {
      _readyToSave.add(false);
      if (saved) {
        UserPreferences().setUserConfig(newConfig);
        _configFileTextLast = newConfig;
        AppDialogs.showConfigurationChangeSuccess(context);
      } else {
        _readyToSave.add(true);
        AppDialogs.showConfigurationChangeFailed(context);
      }
    });
  }

  void dispose() {
    super.dispose();
    _readyToSave.close();
  }

  S get s {
    return S.of(context);
  }
}
