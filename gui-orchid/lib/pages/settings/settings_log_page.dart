import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/titled_page_base.dart';

/// The logging settings page
class SettingsLogPage extends StatefulWidget {
  @override
  _SettingsLogPage createState() => _SettingsLogPage();
}

class _SettingsLogPage extends State<SettingsLogPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: s.logging, child: buildPage(context));
  }

  String _logText = "...";
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _logText = s.loading;
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
    var privacyText = s.thisDebugLogIsNonpersistentAndClearedWhenQuittingThe +
        "  " +
        s.itMayContainSecretOrPersonallyIdentifyingInformation;

    return SafeArea(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The logging control switch
            Container(
              height: 56,
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.all(Radius.circular(4.0)),
              //   border: Border.all(width: 2.0, color: Colors.white.withOpacity(0.3)),
              // ),
              child: PageTile(
                title: s.loggingEnabled,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 0.5,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),

            // Privacy description
            Padding(
                padding:
                    EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 0),
                child: AppText.body(
                  color: Colors.white,
                  textAlign: TextAlign.left,
                  text: privacyText,
                )),

            // The log text view
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 12, bottom: 24),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      _logText,
                      softWrap: true,
                      textAlign: TextAlign.left,
                      style: AppText.logStyle.copyWith(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 2.0, color: AppColors.neutral_5),
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
                      child: RoundTitledRaisedImageButton(
                          title: s.copy,
                          imageName: 'assets/images/business.png',
                          onPressed: _onCopyButton)),
                  Padding(
                      padding: const EdgeInsets.only(left: 0, right: 0),
                      child: RoundTitledRaisedImageButton(
                          title: s.clear,
                          imageName: 'assets/images/business.png',
                          onPressed: _confirmDelete)),
                  /*
                  Padding(
                      padding: const EdgeInsets.all(0),
                      child: RoundTitledRaisedButton(
                          title: 'Save',
                          imageName: 'assets/images/business.png',
                          onPressed: null)),
                   */
                ],
              ),
            )
          ],
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
    AppDialogs.showConfirmationDialog(
        context: context,
        bodyText: s.clearAllLogData,
        cancelText: s.cancel.toUpperCase(),
        actionText: s.delete.toUpperCase(),
        commitAction: () {
          _performDelete();
        });
  }

  S get s {
    return S.of(context);
  }
}
