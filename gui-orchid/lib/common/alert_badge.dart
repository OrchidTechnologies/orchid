import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Fixed size alert badge that can be hidden without changing size.
class SizedAlertBadge extends StatelessWidget {
  final bool visible;
  final double size;
  final double insets;
  final bool maintainSize;
  Color badgeColor;

  SizedAlertBadge({
    Key key,
    @required this.visible,
    this.size = 26,
    this.insets = 6,
    this.maintainSize = true,
    this.badgeColor,
  }) : super(key: key) {
    this.badgeColor = badgeColor ?? Colors.red.shade900;
  }

  @override
  Widget build(BuildContext context) {
    if (!visible && !maintainSize) {
      return Container();
    }
    return Container(
      // color: Colors.green,
      width: size,
      height: size,
      child: Center(
        child: Visibility(
            visible: visible,
            child: Badge(
              elevation: 0,
              badgeColor: badgeColor,
              badgeContent: Text("!",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              padding: EdgeInsets.all(insets),
              toAnimate: false,
            )),
      ),
    );
  }
}

