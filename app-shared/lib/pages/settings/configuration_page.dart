import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:rxdart/rxdart.dart';

import '../app_colors.dart';
import '../app_text.dart';

/// A page presenting a full screen editable text box for the Orchid config file.
class ConfigurationPage extends StatefulWidget {
  @override
  _ConfigurationPageState createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final String title = "Configuration";

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
    return TapClearsFocus(child: TitledPage(title: title, child: buildPage(context)));
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 24),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SingleChildScrollView(
                      child: TextFormField(
                        autocorrect: false,
                        autofocus: false,
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
                      return RoundedRectRaisedButton(
                          text: "SAVE",
                          onPressed: _readyToSave.value ? _save : null);
                    }),
              ),
            ),

            SizedBox(height: 24)
          ],
        ),
      ),
    );
  }

  void _save() {
    var newConfig = _configFileTextController.text;
    OrchidAPI().setConfiguration(newConfig).then((bool saved) {
      _readyToSave.add(false);
      if (saved) {
        UserPreferences().setUserConfig(newConfig);
        _configFileTextLast = newConfig;
        Dialogs.showConfigurationChangeSuccess(context);
      } else {
        _readyToSave.add(true);
        Dialogs.showConfigurationChangeFailed(context);
      }
    });
  }

  void dispose() {
    super.dispose();
    _readyToSave.close();
  }
}
