import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/monitoring/traffic_view.dart';

import '../app_colors.dart';
import '../app_text.dart';

class TrafficViewDetail extends StatefulWidget {
  final FlowEntry flow;

  TrafficViewDetail(this.flow);

  @override
  _TrafficViewDetailState createState() => _TrafficViewDetailState(flow);
}

class _TrafficViewDetailState extends State<TrafficViewDetail> {
  FlowEntry flow;

  _TrafficViewDetailState(this.flow);

  @override
  Widget build(BuildContext context) {
    var protStyle = AppText.logStyle.copyWith(color: AppColors.rneutral_1);
    var hostname = (flow.hostname == null || flow.hostname.isEmpty)
        ? flow.dst_addr
        : flow.hostname;
    var date =
        DateFormat("MM/dd/yyyy HH:mm:ss.SSS").format(flow.start.toLocal());
    return TitledPage(
        title: "Connection Detail",
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: TrafficView.colorForProtocol(flow.protocol),
                ),
                child: Text("${flow.protocol}",
                    style: AppText.textLabelStyle
                        .copyWith(fontSize: 14.0, color: AppColors.rneutral_1)),
              ),
              SizedBox(height: 12),
              Text("Host: $hostname",
                  // Note: I'd prefer ellipses but they brake soft wrap control.
                  // Note: (Watch for the case of "-" dashes in domain names.)
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppText.textLabelStyle.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.rneutral_1)),
              SizedBox(height: 8),
              Text("Time: $date", style: protStyle),
              SizedBox(height: 2),
              Text('Source Addr: ${flow.src_addr}', style: protStyle),
              SizedBox(height: 2),
              Text('Source Port : ${flow.src_port}', style: protStyle),
              SizedBox(height: 2),
              Text('Destination Addr: ${flow.dst_addr}', style: protStyle),
              SizedBox(height: 2),
              Text('Destination Port: ${flow.dst_port}', style: protStyle),
            ],
          ),
        ));
  }
}
