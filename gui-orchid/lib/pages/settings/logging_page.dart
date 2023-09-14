import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_switch.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';

/// The logging settings page
class LoggingPage extends StatefulWidget {
  @override
  _LoggingPageState createState() => _LoggingPageState();
}

class _LoggingPageState extends State<LoggingPage> {
  List<LogLine> _filteredLogLines = [];
  int _lastFilteredId = -1;
  bool _loggingEnabled = false;

  // errors, hour, rpc
  var _selectedFilters = [false, false, false];
  var _loading = false;

  bool get isFiltered {
    return _selectedFilters.reduce((a, b) => a || b);
  }

  OrchidLogAPI get logger {
    return OrchidLogAPI.defaultLogAPI;
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _loggingEnabled = logger.enabled;
    });

    // Fetch the initial log state
    _updateLog(filtersChanged: true);

    // Listen for log changes
    logger.logChanged.addListener(_updateLog);
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
        title: s.logging, constrainWidth: false, child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    var privacyText = s.thisDebugLogIsNonpersistentAndClearedWhenQuittingThe +
        "  " +
        s.itMayContainSecretOrPersonallyIdentifyingInformation;

    return SafeArea(
      child: Center(
        child: OrientationBuilder(
            builder: (BuildContext context, Orientation builderOrientation) {
          var orientation = MediaQuery.of(context).orientation;
          var showControls =
              (orientation == Orientation.portrait) || OrchidPlatform.isWeb;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The logging control switch
              if (showControls) _buildSwitch(),

              if (showControls)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Colors.grey.withOpacity(0.5)),
                ),

              // Privacy description
              if (showControls)
                Padding(
                  padding:
                      EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 0),
                  child: Text(privacyText).caption,
                ),

              if (showControls) pady(4),
              if (showControls) _buildFilterPanel(),

              // The log text view
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 12, bottom: 0),
                  child: _buildLogView(),
                ),
              ),

              if (showControls) pady(8),
              if (showControls)
                Center(
                  child: Text(
                    "${_filteredLogLines.length} ${s.lines}" +
                        (isFiltered ? ' ' + '(' + s.filtered + ')' : ''),
                    style: OrchidText.caption
                        .copyWith(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              pady(16),

              // The buttons row
              if (showControls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.all(0),
                          child: RoundTitledRaisedImageButton(
                              title: s.copy,
                              icon: Icon(Icons.copy,
                                  color: Colors.black, size: 20),
                              padding: 16,
                              onPressed: _onCopyButton)),
                      Padding(
                          padding: const EdgeInsets.all(0),
                          child: RoundTitledRaisedImageButton(
                              title: s.clear,
                              icon: Icon(Icons.clear,
                                  color: Colors.black, size: 20),
                              padding: 16,
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

  Container _buildLogView() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: _loading
          ? Center(
              child:
                  OrchidCircularProgressIndicator.smallIndeterminate(size: 20),
            )
          : Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor:
                      MaterialStateProperty.all(Colors.white.withOpacity(0.4)),
                  // isAlwaysShown: true,
                ),
              ),
              child: _buildLogViewList(),
            ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 2.0, color: AppColors.neutral_5),
      ),
    );
  }

  final scrollController = ScrollController();

  Widget _buildLogViewList() {
    final style = AppText.logStyle.size(10).white;
    return ListView.builder(
      controller: scrollController,
      itemCount: _filteredLogLines.length,
      itemBuilder: (context, index) {
        final line = _filteredLogLines[index];
        final timeStamp = line.date.toIso8601String();
        return RichText(
          softWrap: true,
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              TextSpan(text: timeStamp + ': ', style: style.purpleBright),
              TextSpan(text: line.text, style: style),
            ],
          ),
        );
      },
      // separatorBuilder: (BuildContext context, int index) {
      //   return Divider(height: 16, color: Colors.white.withOpacity(0.4));
      // },
    );
  }

  Container _buildSwitch() {
    return Container(
      height: 56,
      child: PageTile(
        title: s.loggingEnabled,
        onTap: () {},
        trailing: OrchidSwitch(
          value: _loggingEnabled,
          onChanged: (bool value) {
            _loggingEnabled = value;
            logger.enabled = value;
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
            _updateLog(filtersChanged: true);
          },
          children: [
            _buildFilterButton(s.errors, _filterErrors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFilterButton(s.lastHour, _filterLastHour),
            ),
            _buildFilterButton(s.rpc, _filterRPC),
          ]),
    );
  }

  Container _buildFilterButton(String text, int index) {
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

  void _updateLog({bool filtersChanged = false}) async {
    if (filtersChanged) {
      _filteredLogLines = [];
      _lastFilteredId = -1;
    }

    var lines = logger.get();

    if (!isFiltered || lines.isEmpty) {
      setState(() {
        _filteredLogLines = List.from(lines);
      });
      return;
    }

    // drop old
    _filteredLogLines.removeWhere((e) => e.id < lines.first.id);

    // filter new
    var toFilter = lines.where((e) => e.id > _lastFilteredId).toList();
    // print("YYY: lines=${lines.length}, lastId=$_lastFilteredId, toFilter=${toFilter.length}");

    // var start = DateTime.now();
    try {
      if (toFilter.length > 20) {
        _filteredLogLines += await _filterBackground(toFilter);
      } else {
        _filteredLogLines +=
            _filterLog(_FilterLogArgs(toFilter, _selectedFilters));
      }
    } catch (err) {
      print("filter logs error: $err");
    }
    // print("YYY: filtered log view in ${DateTime.now().difference(start).inMilliseconds}ms");

    _lastFilteredId = lines.last.id;
    setState(() {});
  }

  Future<List<LogLine>> _filterBackground(List<LogLine> lines) async {
    setState(() {
      _loading = true;
    });

    final result =
        await compute(_filterLog, _FilterLogArgs(lines, _selectedFilters));

    setState(() {
      _loading = false;
    });
    return result;
  }

  @override
  void dispose() {
    logger.logChanged.removeListener(_updateLog);
    super.dispose();
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() {
    Clipboard.setData(ClipboardData(text: _filteredLogLines.join('\n')));
  }

  void _performDelete() {
    logger.clear();
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

}

// filters
final _filterErrors = 0;
final _filterLastHour = 1;
final _filterRPC = 2;
final _errorExp = RegExp(r'.*[Ee][Rr][Rr][Oo][Rr].*');
final _rpcExp = RegExp(r'.*[Rr][Pp][Cc].*');

class _FilterLogArgs {
  List<LogLine> lines;
  List<bool> selectedFilters;

  _FilterLogArgs(this.lines, this.selectedFilters);
}

// This is structured as a top level function so that it can be called in an isolate.
List<LogLine> _filterLog(_FilterLogArgs args) {
  List<LogLine> lines = args.lines;
  List<bool> selectedFilters = args.selectedFilters;

  bool errors = selectedFilters[_filterErrors];
  final isError = (LogLine line) {
    return line.text.contains(_errorExp);
  };

  bool rpc = selectedFilters[_filterRPC];
  final isRpc = (LogLine line) {
    return line.text.contains(_rpcExp);
  };

  bool hour = selectedFilters[_filterLastHour];
  final isHour = (LogLine line) {
    try {
      return line.date.isAfter(DateTime.now().subtract(Duration(hours: 1)));
    } catch (err) {
      return false;
    }
  };

  var filtered = lines.map((line) {
    return ((!errors || isError(line)) &&
            (!rpc || isRpc(line)) &&
            (!hour || isHour(line)))
        ? line
        : null;
  }).whereType<LogLine>();
  return filtered.toList();
}
