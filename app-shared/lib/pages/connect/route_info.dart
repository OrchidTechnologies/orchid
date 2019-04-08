import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_colors.dart';

/// Displays a three hop route with a re-route button.
class RouteInfo extends StatefulWidget {
  @override
  _RouteInfoState createState() => _RouteInfoState();
}

class _RouteInfoState extends State<RouteInfo> {
  static var borderColor = Color(0xffbea9d3);
  static var border = Border.all(width: 2.0, color: borderColor);

  OrchidRoute _route;

  @override
  void initState() {
    OrchidAPI().routeStatus.listen((route) {
      setState(() {
        _route = route;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_route == null || _route.nodes.length < 3) {
      return Container(height: 136, width: 261);
    }
    return Container(
        height: 136,
        width: 261,
        child: Column(
          children: <Widget>[
            row(context,
                imageName: "assets/images/entrance.png",
                ip: _route.nodes[0].ip.string),
            verticalConnector(context),
            row(context,
                imageName: "assets/images/relay.png",
                ip: _route.nodes[1].ip.string),
            verticalConnector(context),
            row(context,
                imageName: "assets/images/exit.png",
                ip: _route.nodes[2].ip.string),
          ],
        ));
  }

  Widget row(BuildContext context, {String imageName, String ip}) {
    var ipTextStyle = TextStyle(
      color: AppColors.grey_7,
      fontSize: 12.0,
      letterSpacing: 0.03,
    );
    return Row(
      children: <Widget>[
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Color(0x26eae1f9),
                border: border,
                shape: BoxShape.circle),
            child: Center(
              child: Image.asset(
                imageName,
                color: AppColors.grey_7,
                width: 18,
                height: 18,
              ),
            )),
        horizontalConnector(context),
        Container(
          width: 214,
          height: 22,
          child: Center(
              child: AnimatedSwitcher(
            transitionBuilder: (widget, anim) {
              //var tween = Tween<Offset>(begin: Offset(0.0, -0.5), end: Offset.zero).animate(anim);
              //return SlideTransition(position: tween, child: widget);
              return FadeTransition(opacity: anim, child: widget);
            },
            duration: Duration(milliseconds: 500),
            child: Text(
              ip,
              key: ValueKey(ip),
              style: ipTextStyle,
            ),
          )),
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
            color: Color(0x1eeae1f9),
          ),
        )
      ],
    );
  }

  Widget verticalConnector(BuildContext context) {
    return Expanded(
        child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
          margin: EdgeInsets.only(left: 16.0), width: 2.0, color: borderColor),
    ));
  }

  Widget horizontalConnector(BuildContext context) {
    return Expanded(child: Container(height: 2.0, color: borderColor));
  }
}
