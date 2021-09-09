import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A sized alert badge that can be hidden without changing size.
/// Note that Badge can wrap a child directly without affecting the size.
class SizedAlertBadge extends StatelessWidget {
  final bool visible;
  final double size;
  final double insets;
  final bool maintainSize;
  final Color badgeColor;

  SizedAlertBadge({
    Key key,
    @required this.visible,
    this.size = 26,
    this.insets = 6,
    this.maintainSize = true,
    Color badgeColor,
  })  : this.badgeColor = badgeColor ?? Colors.red.shade900,
        super(key: key);

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
