import 'dart:async';
import 'dart:math';
import 'package:orchid/vpn/monitoring/restart_manager.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orchid/vpn/monitoring/analysis_db.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_scroll.dart';
import 'package:collection/collection.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/common/wrapped_switch.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/localization.dart';

import 'clear_traffic_action_button.dart';
import 'traffic_empty_view.dart';
import 'traffic_view_detail.dart';

class TrafficView extends StatefulWidget {
  final ClearTrafficActionButtonController clearTrafficController;

  TrafficView({
    Key? key,
    ClearTrafficActionButtonController? clearTrafficController,
    WrappedSwitchController? monitoringEnabledController,
  })  : this.clearTrafficController =
            clearTrafficController ?? ClearTrafficActionButtonController(),
        super(key: key);

  @override
  _TrafficViewState createState() => _TrafficViewState();

  static Color colorForProtocol(String? protocol) {
    final yellow = Color(0xffFFF282);
    final teal = Color(0xff6EFAC8);
    final purpleDark = Color(0xffB8B3DD);
    final purpleBright = Color(0xffFF6F97);

    if (protocol == null) {
      return Colors.white;
    }
    if (protocol.contains("DNS")) {
      return purpleDark;
    }
    if (protocol.contains("TLS")) {
      return teal;
    }
    if (protocol.contains("HTTP")) {
      return purpleBright;
    }
    return yellow;
  }
}

class _TrafficViewState extends State<TrafficView>
    with TickerProviderStateMixin {
  // Query state
  var _searchTextController = TextEditingController();
  String _query = "";
  String? _lastQuery;
  List<FlowEntry>? _pendingResultList;
  List<FlowEntry>? _resultList;
  Timer? _pollTimer;

  // Scrolling state
  final int _scrollToTopDurationMs = 700;
  ScrollPhysics _scrollPhysics = OrchidScrollPhysics();
  double _renderedRowHeight = 54;
  bool _updatesPaused = false;
  DateTime? _lastScroll;
  ValueNotifier<bool> _newContent = ValueNotifier(false);

  // TODO: We used to be able to use PrimaryScrollController.of(context)
  // TODO: which allowed us to tap in the header to scroll to top.
  // TODO: Determine what changed and fix this.
  var _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ScreenOrientation.all();

    // Update on search text
    _searchTextController.addListener(() {
      // Ignore repeated values from text controller.
      if (_searchTextController.text == _query) {
        return;
      }
      _query =
          _searchTextController.text.isEmpty ? "" : _searchTextController.text;
      _performQuery();
    });

    // Update periodically
    _pollTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _performQuery();
    });

    // Update first view
    _performQuery();

    // Update if the db signals a change
    AnalysisDb().update.listen((_) {
      _performQuery();
    });

    initStateAsync();
  }

  void initStateAsync() async {
    // monitoringEnabledController.onChange = _monitoringSwitchChanged;
    // monitoringEnabledController.controlledState.value =
    UserPreferencesVPN().monitoringEnabled.get();
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.traffic,
      constrainWidth: false,
      // decoration: BoxDecoration(),
      actions: [
        ClearTrafficActionButton(controller: widget.clearTrafficController),
      ],
      child: buildContent(),
    );
  }

  Widget buildContent() {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Visibility(
              visible: _uiInitialized(),
              replacement: Container(),
              child: Visibility(
                visible: _showEmptyView(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: TrafficEmptyView(),
                ),
                replacement: Column(
                  children: <Widget>[
                    _buildSearchView(),
                    _buildNewContentIndicator(),
                    Expanded(
                        child: Container(
                      foregroundDecoration: BoxDecoration(
                        gradient: OrchidGradients.fadeOutBottomGradient,
                      ),
                      child: _buildResultListView(),
                    ))
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
            child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: _buildVisibleAnalyzeButton(),
          ),
        )),
      ],
    );
  }

  Widget _buildVisibleAnalyzeButton() {
    return OrientationBuilder(builder: (BuildContext context, Orientation _) {
      var orientation = MediaQuery.of(context).orientation;
      return Visibility(
        visible: orientation == Orientation.portrait,
        child: _buildMonitorButton(),
      );
    });
  }

  // Build the analyze toggle button. This switch does not reflect current state of the
  // VPN but only the user preference that monitoring be enabled.
  Widget _buildMonitorButton() {
    return StreamBuilder<bool>(
        stream: OrchidRestartManager().restarting.stream,
        builder: (context, snapshot) {
          var restarting = snapshot.data ?? false;
          return StreamBuilder<bool>(
              stream: UserPreferencesVPN().monitoringEnabled.stream(),
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return Container();
                }
                bool currentMonitoringEnabled = snapshot.data!;
                // Toggle the value
                var desiredMonitoringEnabled = !currentMonitoringEnabled;
                var text = restarting
                    ? "(${s.restarting})"
                    : (currentMonitoringEnabled
                        ? s.stopAnalysis
                        : s.startAnalysis);
                return OrchidActionButton(
                    enabled: !restarting,
                    text: text,
                    onPressed: () {
                      _confirmMonitoringSwitchChange(desiredMonitoringEnabled);
                    });
              });
        });
  }

  Widget _buildSearchView() {
    var textStyle = OrchidText.body2.copyWith(height: 1.5);
    return Container(
      padding: EdgeInsets.only(bottom: 12.0, top: 12.0),
      child: TextFormField(
        autocorrect: false,
        smartQuotesType: SmartQuotesType.disabled,
        smartDashesType: SmartDashesType.disabled,
        controller: _searchTextController,
        cursorColor: Colors.white,
        // style: TextStyle(color: Colors.white),
        style: textStyle,
        decoration: InputDecoration(
          // fillColor: Colors.black,
          // filled: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(width: 1, color: Colors.white)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(width: 2, color: OrchidColors.interactive_pink)),
          // hintText: s.search,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Icon(Icons.search_outlined,
                // todo: want to change the color on focus
                // color: FocusScope.of(context).hasFocus ? Color(0xff766D86) : Colors.white),
                color: Colors.white),
          ),
          // hintStyle: TextStyle(color: AppColors.neutral_5),
          suffixIcon: _searchTextController.text.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        invalidateResults();
                        _searchTextController.clear();
                        FocusScope.of(context).requestFocus(FocusNode());
                      }),
                ),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildResultListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: onScrollNotification,
      child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) =>
              Divider(height: 8),
          padding: EdgeInsets.only(bottom: 125),
          key: PageStorageKey('traffic list view'),

          // TODO: We used to be able to set this to primary, which allowed
          // TODO: us to tap in the header to scroll to top.  But the primary
          // TODO: scroll controller now seems to be null here.
          // TODO: Determine what changed and fix this.
          //primary: true,
          controller: _scrollController,
          //
          physics: _scrollPhysics,
          itemCount: _resultList?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            // should not be access if result list is null
            FlowEntry flow = _resultList![index];
            return _buildListTile(flow);
          }),
    );
  }

  Widget _buildListTile(FlowEntry flow) {
    var hostname = (flow.hostname == null || flow.hostname!.isEmpty)
        ? flow.dst_addr
        : flow.hostname;
    var date =
        DateFormat('MM/dd/yyyy HH:mm:ss.SSS').format(flow.start.toLocal());

    // Note: Setting the background color on the container vs. the ListTile
    // Note: changes the clipping behavior. (bug?)
    return Container(
      height: _renderedRowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TrafficView.colorForProtocol(flow.protocol),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        // tileColor: TrafficView.colorForProtocol(flow.protocol),
        key: PageStorageKey<int>(flow.rowId),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return TrafficViewDetail(flow);
          }));
        },
        title: Row(
          children: [
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 8),
                  Text("$hostname:${flow.dst_port != 0 ? flow.dst_port : ""}",
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: OrchidText.body2.black),
                  SizedBox(height: 4),
                  Text("$date", style: OrchidText.caption.black),
                ],
              ),
            ),
            Spacer(),
            Text("${flow.protocol}",
                textAlign: TextAlign.right, style: OrchidText.body1.black),
            SizedBox(width: 8)
          ],
        ),
      ),
    );
  }

  Widget _buildNewContentIndicator() {
    var textColor = Colors.black;
    var upArrow = Icon(Icons.arrow_upward, color: textColor, size: 16);
    return ValueListenableBuilder<bool>(
        valueListenable: _newContent,
        builder: (context, newContent, child) {
          return AnimatedCrossFade(
            duration: Duration(milliseconds: 300),
            crossFadeState: newContent
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: GestureDetector(
              onTap: _scrollToNewContent,
              child: Container(
                  color: OrchidColors.tappable,
                  alignment: Alignment.center,
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      upArrow,
                      SizedBox(width: 12),
                      Text(
                        s.newContent,
                        style: OrchidText.body1.black.copyWith(height: 2.0),
                      ),
                      SizedBox(width: 12),
                      upArrow,
                    ],
                  )),
            ),
            secondChild: Container(
              height: 0,
            ),
          );
        });
  }

  /// Fetch results from the analysis db, utilizing search text for the query.
  Future<void> _performQuery() async {
    Completer<void> completer = Completer();
    AnalysisDb().query(filterText: _query).then((List<FlowEntry> results) {
      if (_query != _lastQuery) {
        invalidateResults();
        _lastQuery = _query;
      }

      updateResults(List.from(results)); // copy
      completer.complete();
    });
    return completer.future;
  }

  /// Queue updated results for potential animated update to the list.
  void updateResults(List<FlowEntry> results) {
    _pendingResultList = results;
    applyPendingUpdates();
    widget.clearTrafficController.enabled.value = !_showEmptyView();
  }

  /// Indicate that the query context has changed and the result list should be
  /// replaced rather than updated.
  void invalidateResults() {
    _resultList = null;
    _updatesPaused = false;
  }

  // Apply updates to the list only when it is settled at the top. The effect
  // is that updates are paused when the user scrolls down into the list and
  // resumed when the list is returned to the top.
  void applyPendingUpdates() {
    // If no update nothing to do.
    if (_pendingResultList == null) {
      return;
    }

    // If the update is identical do the current data ignore it.
    if (_resultList != null) {
      var ids1 = _pendingResultList!.map((row) {
        return row.rowId;
      }).toList();
      var ids2 = _resultList!.map((row) {
        return row.rowId;
      }).toList();
      if (ListEquality().equals(ids1, ids2)) {
        return;
      }
    }

    // If no current results (e.g. invalidated by search) or the list has
    // shrunk through some other means just do a plain update.
    if (_resultList == null || _pendingResultList!.length < _resultList!.length) {
      if (mounted) {
        setState(() {
          _resultList = _pendingResultList;
        });
      }
      _newContent.value = false;
      return;
    }

    // If paused defer update
    if (_updatesPaused) {
      // If paused long enough show new content indicator
      var pauseTime = DateTime.now().difference(_lastScroll ?? DateTime.now());
      if (pauseTime > Duration(seconds: 3)) {
        _newContent.value = true;
      }
      return;
    }

    // Apply an animated update
    setState(() {
      // Update the data
      int delta = max(0, _pendingResultList!.length - _resultList!.length);
      _resultList = _pendingResultList ?? _resultList;
      _pendingResultList = null;

      // TODO: We used to be able to grab PrimaryScrollController.of(context) here
      // TODO: which allowed us to tap in the header to scroll to top.  Now null.
      // TODO: Determine what changed and fix this.
      //var scrollController = PrimaryScrollController.of(context);
      var scrollController = _scrollController;

      // Maintain position
      if (scrollController.hasClients) {
        scrollController
            .jumpTo(scrollController.offset + delta * _renderedRowHeight);

        // Animate in the new data
        Future.delayed(Duration(milliseconds: 150)).then((_) {
          try {
            scrollController
                .animateTo(0,
                    duration: Duration(milliseconds: _scrollToTopDurationMs),
                    curve: Curves.ease)
                .then((_) {
              _newContent.value = false;
            });
          } catch (err) {}
        });
      }
    });
  }

  /// Update scrolling dependent state including pausing updates when required.
  bool onScrollNotification(ScrollNotification notif) {
    var atTop = notif.metrics.pixels == notif.metrics.minScrollExtent;
    _updatesPaused = !atTop;
    if (!_updatesPaused) {
      applyPendingUpdates();
    }
    _lastScroll = DateTime.now();
    return false;
  }

  /// Return true if there is no data to be displayed and the empty state view should
  /// be shown.  Note that this does not include empty query results.
  bool _showEmptyView() {
    return _resultList != null && _resultList!.isEmpty && _query.length < 1;
  }

  bool _uiInitialized() {
    return _lastQuery != null;
  }

  /// Update the list with new content and scroll to the top
  void _scrollToNewContent() {
    _updatesPaused = false;
    applyPendingUpdates();
  }

  // Currently unused
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _pollTimer?.cancel();
  }

  // If the monitoring switch change would require a restart then confirm.
  void _confirmMonitoringSwitchChange(bool enabled) async {
    var enablingText =
        s.changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly;
    // cannot be null
    if (UserPreferencesVPN().routingEnabled.get()!) {
      AppDialogs.showConfirmationDialog(
          context: context,
          title: s.confirmRestart,
          bodyText: enablingText,
          commitAction: () {
            _monitoringSwitchChanged(enabled);
          });
    } else {
      _monitoringSwitchChanged(enabled);
    }
  }

  void _monitoringSwitchChanged(bool enabled) async {
    log('vpn: traffic monitoring enabled: $enabled');
    UserPreferencesVPN().monitoringEnabled.set(enabled);
    // monitoringEnabledController.controlledState.value = enabled;
  }
}
