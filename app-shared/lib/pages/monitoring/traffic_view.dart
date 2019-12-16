import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/orchid_scroll.dart';
import 'package:collection/collection.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_text.dart';
import 'traffic_empty_view.dart';
import 'traffic_view_detail.dart';

class TrafficView extends StatefulWidget {
  final ClearTrafficActionButtonController clearTrafficController;

  const TrafficView({Key key, this.clearTrafficController}) : super(key: key);

  @override
  _TrafficViewState createState() => _TrafficViewState();

  static Color colorForProtocol(String protocol) {
    const opacity = 0.2;
    if (protocol == null) {
      return Colors.white;
    }
    if (protocol.contains("DNS")) {
      return Colors.grey.withOpacity(opacity);
    }
    if (protocol.contains("TLS")) {
      return Colors.lightGreen.withOpacity(opacity);
    }
    if (protocol.contains("HTTP")) {
      return Colors.red.withOpacity(opacity);
    }
    return Colors.yellow.withOpacity(opacity);
  }
}

class _TrafficViewState extends State<TrafficView>
    with TickerProviderStateMixin {
  // Query state
  var _searchTextController = TextEditingController();
  String _query = "";
  String _lastQuery;
  List<FlowEntry> _pendingResultList;
  List<FlowEntry> _resultList;
  Timer _pollTimer;

  // Scrolling state
  final int _scrollToTopDurationMs = 700;
  ScrollPhysics _scrollPhysics = OrchidScrollPhysics();
  double _renderedRowHeight = 60;
  bool _updatesPaused = false;
  DateTime _lastScroll;
  ValueNotifier<bool> _newContent = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Visibility(
              visible: _uiInitialized(),
              replacement: Container(),
              child: Visibility(
                visible: _showEmptyView(),
                child: TrafficEmptyView(),
                replacement: Column(
                  children: <Widget>[
                    _buildSearchView(),
                    _buildNewContentIndicator(),
                    _buildResultListView()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    return Container(
      padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: TextFormField(
        autocorrect: false,
        controller: _searchTextController,
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: TextStyle(color: AppColors.neutral_5),
          suffixIcon: _searchTextController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    invalidateResults();
                    _searchTextController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  }),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildResultListView() {
    return Flexible(
      child: NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification,
        child: ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                Divider(height: 0),
            key: PageStorageKey('traffic list view'),
            primary: true,
            physics: _scrollPhysics,
            itemCount: _resultList?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              FlowEntry flow = _resultList[index];
              var hostname = (flow.hostname == null || flow.hostname.isEmpty)
                  ? flow.dst_addr
                  : flow.hostname;
              var date = DateFormat("MM/dd/yyyy HH:mm:ss.SSS")
                  .format(flow.start.toLocal());
              return Theme(
                data: ThemeData(accentColor: AppColors.purple_3),
                child: Container(
                  height: _renderedRowHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TrafficView.colorForProtocol(flow.protocol),
                  ),
                  child: IntrinsicHeight(
                    child: ListTile(
                      key: PageStorageKey<int>(flow.rowId), // unique key
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 10,
                                child: Text(
                                    "$hostname:${flow.dst_port != 0 ? flow.dst_port : ""}",
                                    // Note: I'd prefer ellipses but they brake soft wrap control.
                                    // Note: (Watch for the case of "-" dashes in domain names.)
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: AppText.textLabelStyle
                                        .copyWith(fontWeight: FontWeight.bold)),
                              ),
                              Spacer(),
                              Text("${flow.protocol}",
                                  textAlign: TextAlign.right,
                                  style: AppText.textLabelStyle.copyWith(
                                      fontSize: 14.0,
                                      color: AppColors.neutral_3)),
                              SizedBox(width: 8)
                            ],
                          ),
                          SizedBox(height: 4),
                          Text("$date",
                              style: AppText.logStyle.copyWith(fontSize: 12.0)),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                          return TrafficViewDetail(flow);
                        }));
                      },
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _buildNewContentIndicator() {
    var color = AppColors.neutral_2;
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
                  decoration: BoxDecoration(
                    //border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.5) )),
                    color: Colors.blueGrey.withOpacity(0.3),
                  ),
                  alignment: Alignment.center,
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.arrow_upward,
                        color: color.withOpacity(0.5),
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text("New Content",
                          style: AppText.textLabelStyle
                              .copyWith(color: color, fontSize: 14.0)),
                      SizedBox(width: 12),
                      Icon(
                        Icons.arrow_upward,
                        color: color.withOpacity(0.5),
                        size: 16,
                      ),
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
      var ids1 = _pendingResultList.map((row) {
        return row.rowId;
      }).toList();
      var ids2 = _resultList.map((row) {
        return row.rowId;
      }).toList();
      if (ListEquality().equals(ids1, ids2)) {
        return;
      }
    }

    // If no current results (e.g. invalidated by search) or the list has
    // shrunk through some other means just do a plain update.
    if (_resultList == null || _pendingResultList.length < _resultList.length) {
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
      int delta = max(0, _pendingResultList.length - _resultList.length);
      _resultList = _pendingResultList ?? _resultList;
      _pendingResultList = null;

      // Maintain position
      var scrollController = PrimaryScrollController.of(context);
      var offset = scrollController.hasClients ? scrollController.offset : 0;
      scrollController.jumpTo(offset + delta * _renderedRowHeight);

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
    return _resultList != null && _resultList.isEmpty && _query.length < 1;
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
    _pollTimer.cancel();
  }
}

class ClearTrafficActionButtonController {
  // Tri-state enabled status
  ValueNotifier<bool> enabled = ValueNotifier(null);
}

class ClearTrafficActionButton extends StatelessWidget {
  final ClearTrafficActionButtonController controller;

  const ClearTrafficActionButton({this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: controller.enabled,
        builder: (context, enabledOrNull, child) {
          bool enabled = enabledOrNull ?? false;
          return Visibility(
            visible: enabledOrNull != null,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.3,
              child: FlatButton(
                child: Text("Clear", style: AppText.actionButtonStyle),
                onPressed: enabled
                    ? () {
                        _confirmDelete(context);
                      }
                    : null,
              ),
            ),
          );
        });
  }

  void _confirmDelete(BuildContext context) {
    Dialogs.showConfirmationDialog(
        context: context,
        title: "Delete all data?",
        body: "This will delete all recorded traffic data within the app.",
        cancelText: "CANCEL",
        actionText: "OK",
        action: () async {
          await AnalysisDb().clear();
        });
  }
}
