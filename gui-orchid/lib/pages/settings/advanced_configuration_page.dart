import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/pages/circuit/config_change_dialogs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:orchid/util/localization.dart';

import '../../common/app_colors.dart';
import '../../common/app_text.dart';

/// A page presenting a full screen editable text box for the Orchid config file.
class AdvancedConfigurationPage extends StatefulWidget {
  @override
  _AdvancedConfigurationPageState createState() =>
      _AdvancedConfigurationPageState();
}

class _AdvancedConfigurationPageState extends State<AdvancedConfigurationPage> {
  String _configFileTextLast = "";

  // TODO: Remove this uncessecary observable
  BehaviorSubject<bool> _readyToSave = BehaviorSubject<bool>.seeded(false);

  final _configFileTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    var text = UserPreferencesUI().userConfig.get() ?? '';
    setState(() {
      _configFileTextLast = text;
      _configFileTextController.text = text;
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
                        icon: Icon(Icons.copy, color: Colors.black, size: 20),
                        padding: 16,
                        onPressed: _onCopy)),
                Padding(
                    padding: const EdgeInsets.all(0),
                    child: RoundTitledRaisedImageButton(
                        title: s.paste,
                        icon: Icon(Icons.paste, color: Colors.black, size: 20),
                        padding: 16,
                        onPressed: _onPaste)),
                Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0),
                    child: RoundTitledRaisedImageButton(
                        title: s.clear,
                        icon: Icon(Icons.clear, color: Colors.black, size: 20),
                        padding: 16,
                        onPressed: _onClear)),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 24),
                child: OrchidConfigTextBox(
                    textController: _configFileTextController),
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
                          OrchidActionButton(
                            text: s.saveButtonTitle,
                            onPressed: _onSave,
                            enabled: _readyToSave.value,
                          )
                        ],
                      );
                    }),
              ),
            ),

            SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: _configFileTextController.text));
  }

  void _onPaste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _configFileTextController.text = data!.text!;
      });
    }
  }

  void _onClear() {
    setState(() {
      _configFileTextController.text = '';
    });
  }

  void _onSave() async {
    // validate
    var newConfig = _configFileTextController.text;
    try {
      // Just parse it to the AST to catch gross syntax errors.
      // if (newConfig.trim().isNotEmpty) {
      //   parsejs(newConfig, filename: 'program.js');
      // }
    } catch (err) {
      print("Error parsing config: $err");
      ConfigChangeDialogs.showConfigurationChangeFailed(context,
          errorText: err.toString());
      return;
    }

    // save
    try {
      await UserPreferencesUI().userConfig.set(newConfig);
      setState(() {
        _configFileTextLast = newConfig;
      });
      _readyToSave.add(false);
      await OrchidAPI().publishConfiguration();
      ConfigChangeDialogs.showConfigurationChangeSuccess(context);
    } catch (err) {
      log("failed to save config: $err");
      ConfigChangeDialogs.showConfigurationChangeFailed(context);
    }
  }

  void dispose() {
    super.dispose();
    _readyToSave.close();
  }
}

class OrchidConfigTextBox extends StatelessWidget {
  final TextEditingController _textController;
  final bool readOnly;

  const OrchidConfigTextBox({
    Key? key,
    required TextEditingController textController,
    this.readOnly = false,
  })  : _textController = textController,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
          child: Theme(
        data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
          selectionColor: OrchidColors.purple_ff8c61e1,
          cursorColor: OrchidColors.purple_bright,
        )),
        child: TextFormField(
          readOnly: readOnly,
          autocorrect: false,
          autofocus: false,
          smartQuotesType: SmartQuotesType.disabled,
          smartDashesType: SmartDashesType.disabled,
          keyboardType: TextInputType.multiline,
          style: AppText.logStyle.copyWith(color: Colors.white),
          controller: _textController,
          maxLines: 99999,
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
        ),
      )),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        border: Border.all(width: 2.0, color: AppColors.neutral_5),
      ),
    );
  }
}
