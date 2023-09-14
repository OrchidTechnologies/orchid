import 'package:orchid/orchid/orchid.dart';
import 'package:intl/intl.dart';
import 'package:orchid/vpn/monitoring/analysis_db.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/pages/monitoring/traffic_view.dart';

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
    var protocolStyle = OrchidText.body1;
    var hostname = (flow.hostname == null || flow.hostname!.isEmpty)
        ? flow.dst_addr
        : flow.hostname;
    var date =
        DateFormat('MM/dd/yyyy HH:mm:ss.SSS').format(flow.start.toLocal());
    var protocolColor = TrafficView.colorForProtocol(flow.protocol);
    return TitledPage(
        title: s.connectionDetail,
        constrainWidth: false,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: protocolColor,
                  ),
                  child: Text(
                    "${flow.protocol}",
                    style: OrchidText.highlight.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  s.host + ": $hostname",
                  // Note: I'd prefer ellipses but they brake soft wrap control.
                  // Note: (Watch for the case of "-" dashes in domain names.)
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: OrchidText.highlight.copyWith(color: protocolColor),
                ),
                SizedBox(height: 8),
                Text(s.time + ": $date", style: protocolStyle),
                SizedBox(height: 2),
                Text(s.sourcePort + ": ${flow.src_port}", style: protocolStyle),
                SizedBox(height: 2),
                Text(s.destination + ": ${flow.dst_addr}",
                    style: protocolStyle),
                SizedBox(height: 2),
                Text(s.destinationPort + ": ${flow.dst_port}",
                    style: protocolStyle),
              ],
            ),
          ),
        ));
  }
}
