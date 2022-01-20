import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

/// The logging settings page
class LoggingPage extends StatefulWidget {
  @override
  _LoggingPageState createState() => _LoggingPageState();
}

class _LoggingPageState extends State<LoggingPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(
        title: s.logging, constrainWidth: false, child: buildPage(context));
  }

  String _logText = "...";

  StreamSubscription<void> _logListener;
  bool _loggingEnabled = false;

  // filters
  final filterErrors = 0;
  final filterLastHour = 1;
  final filterRPC = 2;
  var _selectedFilters = [false, false, false];

  bool get isFiltered {
    return _selectedFilters.reduce((a, b) => a || b);
  }

  @override
  void initState() {
    super.initState();

    OrchidLogAPI logger = OrchidAPI().logger();

    logger.getEnabled().then((bool value) {
      setState(() {
        _loggingEnabled = value;
      });
    });

    // Fetch the initial log state
    _updateLog();

    // Listen for log changes
    _logListener = logger.logChanged.listen((_) {
      _updateLog();
    });
  }

  void initStateAsync() async {}

  Widget buildPage(BuildContext context) {
    var privacyText = s.thisDebugLogIsNonpersistentAndClearedWhenQuittingThe +
        "  " +
        s.itMayContainSecretOrPersonallyIdentifyingInformation;

    return SafeArea(
      child: Center(
        child: OrientationBuilder(
            builder: (BuildContext context, Orientation builderOrientation) {
          var orientation = MediaQuery.of(context).orientation;
          var portrait = orientation == Orientation.portrait;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The logging control switch
              if (portrait) _buildSwitch(),

              if (portrait)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Colors.grey.withOpacity(0.5)),
                ),

              // Privacy description
              if (portrait)
                Padding(
                  padding:
                      EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 0),
                  child: Text(privacyText).caption,
                ),

              if (portrait)
              pady(4),
              if (portrait)
              _buildFilterPanel(),

              // The log text view
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 12, bottom: 0),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      reverse: true,
                      // Note: SelectableText does not support softWrap
                      child: Text(
                        _logText,
                        softWrap: true,
                        textAlign: TextAlign.left,
                        style: AppText.logStyle
                            .copyWith(fontSize: 10, color: Colors.white),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      border:
                          Border.all(width: 2.0, color: AppColors.neutral_5),
                    ),
                  ),
                ),
              ),

              if (portrait)
              pady(8),
              if (portrait)
              Center(
                child: Text(
                  "$_lineCount lines" + (isFiltered ? ' ' + "(filtered)" : ''),
                  style: OrchidText.caption
                      .copyWith(color: Colors.white.withOpacity(0.5)),
                ),
              ),
              pady(16),

              // The buttons row
              if (portrait)
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
                  ],
                ),
              )
            ],
          );
        }),
      ),
    );
  }

  Container _buildSwitch() {
    return Container(
      height: 56,
      child: PageTile(
        title: s.loggingEnabled,
        onTap: () {},
        trailing: Switch(
          activeColor: OrchidColors.active,
          inactiveThumbColor: OrchidColors.inactive,
          inactiveTrackColor: OrchidColors.inactive,
          value: _loggingEnabled,
          onChanged: (bool value) {
            _loggingEnabled = value;
            OrchidAPI().logger().setEnabled(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Center(
      child: ToggleButtons(
          fillColor: Colors.transparent,
          isSelected: _selectedFilters,
          onPressed: (index) {
            setState(() {
              _selectedFilters[index] = !_selectedFilters[index];
            });
            _updateLog();
          },
          children: [
            _buildFilterButton("Errors", filterErrors, null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFilterButton("Last Hour", filterLastHour, null),
            ),
            _buildFilterButton("RPC", filterRPC, null),
          ]),
    );
  }

  Container _buildFilterButton(
      String text, int index, VoidCallback onSelected) {
    return Container(
        decoration: BoxDecoration(
            color:
                _selectedFilters[index] ? OrchidColors.enabled : Colors.black,
            border: Border.all(color: OrchidColors.tappable),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(text).button,
        ));
  }

  int _lineCount = 0;

  void _updateLog() async {
    OrchidLogAPI logger = OrchidAPI().logger();
    var text = await logger.get();
    setState(() {
      _logText = '';
    });
    try {
      _logText = _filterLog(text);
    } catch (err) {
      print(err);
    }
    setState(() {});
  }

  String _filterLog(String text) {
    bool errors = _selectedFilters[filterErrors];
    final errorExp = RegExp(r'.*[Ee][Rr][Rr].*');
    var isError = (line) {
      return line.contains(errorExp);
    };

    bool hour = _selectedFilters[filterLastHour];
    var isHour = (line) {
      try {
        return DateTime.parse(line.substring(0, 19))
            .isAfter(DateTime.now().subtract(Duration(hours: 1)));
      } catch (err) {
        return false;
      }
    };

    bool rpc = _selectedFilters[filterRPC];
    final rpcExp = RegExp(r'.*[Rr][Pp][Cc].*');
    var isRpc = (line) {
      return line.contains(rpcExp);
    };

    var lines = LineSplitter.split(text);
    var filtered = lines.map((line) {
      return ((!errors || isError(line)) &&
              (!rpc || isRpc(line)) &&
              (!hour || isHour(line)))
          ? line
          : null;
    });
    filtered = filtered.where((line) => line != null);
    _lineCount = filtered.length;
    return filtered.join('\n');
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

  /// Copy the log data to the clipboard
  void _onCopyButton() {
    Clipboard.setData(ClipboardData(text: _logText));
  }

  void _performDelete() {
    OrchidAPI().logger().clear();
  }

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
