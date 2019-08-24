import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:orchid/pages/common/orchid_scroll.dart';

import '../app_colors.dart';
import '../app_text.dart';
import 'traffic_empty_view.dart';
import 'traffic_view_detail.dart';

class TrafficView extends StatefulWidget {
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

class _TrafficViewState extends State<TrafficView> {
  var _searchTextController = TextEditingController();
  String _query = "";
  List<FlowEntry> _resultList;
  Timer _pollTimer;
  ScrollPhysics _scrollPhysics = OrchidScrollPhysics();

  @override
  void initState() {
    super.initState();

    // Update on search text
    _searchTextController.addListener(() {
      _query =
          _searchTextController.text.isEmpty ? "" : _searchTextController.text;
      _performQuery();
    });

    // Update periodically
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _performQuery();
    });

    // Update first view
    _performQuery();

//    AnalysisDb().update.listen((_) { _performQuery(); });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Visibility(visible: _showEmptyView(), child: TrafficEmptyView()),
          Visibility(
            visible: !_showEmptyView(),
            child: Column(
              children: <Widget>[_buildSearchView(), _buildResultListView()],
            ),
          )
        ],
      ),
    );
  }

  /// Return true if there is no data to be displayed and the empty state view should
  /// be shown.  Note that this does not include empty query results.
  bool _showEmptyView() {
    return _resultList != null && _resultList.isEmpty && _query.length < 1;
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
                    _searchTextController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  }),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Future<void> _performQuery() async {
    Completer<void> completer = Completer();
    AnalysisDb().query(filterText: _query).then((results) {
      setState(() {
        _resultList = results;
      });
      completer.complete();
    });
    return completer.future;
  }

  Widget _buildResultListView() {
    return Flexible(
      child: RefreshIndicator(
        onRefresh: () {
          return _performQuery();
        },
        child: ListView.separated(
            physics: _scrollPhysics,
            separatorBuilder: (BuildContext context, int index) =>
                Divider(height: 0),
            key: PageStorageKey('traffic list view'),
            primary: true,
            itemCount: _resultList?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              FlowEntry item = _resultList[index];
              var hostname = (item.hostname == null || item.hostname.isEmpty)
                  ? item.dst_addr
                  : item.hostname;
              var date = DateFormat("MM/dd/yyyy HH:mm:ss.SSS")
                  .format(item.start.toLocal());
              return Theme(
                data: ThemeData(accentColor: AppColors.purple_3),
                child: Container(
                  decoration: BoxDecoration(
                      color: TrafficView.colorForProtocol(item.protocol),
                  ),
                  child: ListTile(
                    key: PageStorageKey<int>(item.rowId), // unique key
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 10,
                              child: Text("$hostname",
                                  // Note: I'd prefer ellipses but they brake soft wrap control.
                                  // Note: (Watch for the case of "-" dashes in domain names.)
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: AppText.textLabelStyle
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ),
                            Spacer(),
                            Text("${item.protocol}",
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
                        return TrafficViewDetail(item);
                      }));
                    },
                  ),
                ),
              );
            }),
      ),
    );
  }

  // Currently unused
  void dispose() {
    super.dispose();
    _pollTimer.cancel();
  }
}

