import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

/// The logging settings page
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
  bool _loggingEnabled = false;

  @override
  void initState() {
    super.initState();

    OrchidLogAPI logger = OrchidAPI().logger();

    logger.getEnabled().then((bool value) {
      setState(() {
        _loggingEnabled = value;
      });
    });

    void Function() fetchLog = () {
      logger.get().then((String text) {
        setState(() {
          _logText = text;
        });
      });
    };

    // Fetch the initial log state
    fetchLog();

    // Listen for log changes
    _logListener = logger.logChanged.listen((_) {
      fetchLog();
    });
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

    return SafeArea(
      child: Center(
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
                    value: _loggingEnabled,
                    onChanged: (bool value) {
                      _loggingEnabled = value;
                      OrchidAPI().logger().setEnabled(value);
                    },
                  ),
                ),
              ),

              Container(
                height: 1,
                color: AppColors.grey_1.withAlpha((0.12 * 255).round()),
              ),

              // Privacy description
              Padding(
                  padding:
                      EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                  child: AppText.body(
                    color: Color(0xff524862),
                    textAlign: TextAlign.left,
                    text: privacyText,
                  )),

              // The log text view
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 12, bottom: 32),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(
                        _logText,
                        textAlign: TextAlign.left,
                        style: AppText.logStyle,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      border:
                          Border.all(width: 2.0, color: AppColors.neutral_5),
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
                        child: RoundTitledRaisedButton(
                            title: "Copy",
                            imageName: "assets/images/business.png",
                            onPressed: _onCopyButton)),
                    Padding(
                        padding: const EdgeInsets.only(left: 0, right: 0),
                        child: RoundTitledRaisedButton(
                            title: "Delete",
                            imageName: "assets/images/business.png",
                            onPressed: _confirmDelete)),
                    Padding(
                        padding: const EdgeInsets.all(0),
                        child: RoundTitledRaisedButton(
                            title: "Save",
                            imageName: "assets/images/business.png",
                            onPressed: null)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() {
    Clipboard.setData(ClipboardData(text: _logText));
  }

  void _performDelete() {
    OrchidAPI().logger().clear();
  }

  void _onSave() {}

  void _confirmDelete() {
    Dialogs.showConfirmationDialog(
        context: context,
        //title: "Delete Log Data",
        body: "Clear all log data?",
        cancelText: "CANCEL",
        actionText: "DELETE",
        action: () {
          _performDelete();
        });
  }
}
