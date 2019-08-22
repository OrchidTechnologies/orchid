import 'package:flutter/material.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_text.dart';

class TrafficViewDetail extends StatefulWidget {
  FlowEntry flow;

  TrafficViewDetail(this.flow);

  @override
  _TrafficViewDetailState createState() => _TrafficViewDetailState(flow);
}

class _TrafficViewDetailState extends State<TrafficViewDetail> {
  FlowEntry flow;

  _TrafficViewDetailState(this.flow);

  @override
  Widget build(BuildContext context) {
    var protStyle = AppText.logStyle;//.copyWith(fontSize: 12.0);
    return TitledPage(
        title: "Connection Detail",
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ListTile(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Source Addr: ${flow.src_addr}', style: protStyle),
                  SizedBox(height: 2),
                  Text('Source Port : ${flow.src_port}', style: protStyle),
                  SizedBox(height: 2),
                  Text('Destination Addr: ${flow.dst_addr}', style: protStyle),
                  SizedBox(height: 2),
                  Text('Destination Port: ${flow.dst_port}', style: protStyle),
                ],
              ),
            ),
          ),
        ));
  }
}
