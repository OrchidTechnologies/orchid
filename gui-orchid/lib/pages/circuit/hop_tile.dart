import 'package:badges/badges.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/pages/common/formatting.dart';

import '../app_text.dart';

/// A tile representing a network or logical hop on the circuit page.
class HopTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Image image;
  final Color textColor;
  final Color color;
  final Gradient gradient;
  final bool showDragHandle;
  final bool showFlowDividerBottom;
  final bool showFlowDividerTop;
  final bool showTopDivider;
  final bool showBottomDivider;
  final Widget trailing;
  final bool dottedBorder;
  final Color borderColor;
  final bool showAlertBadge;

  const HopTile({
    Key key,
    this.title,
    this.onTap,
    this.image,
    this.textColor,
    this.color,
    this.gradient,
    this.showDragHandle = false,
    this.showFlowDividerBottom = false,
    this.showFlowDividerTop = false,
    this.showTopDivider = false,
    this.showBottomDivider = false,
    this.trailing,
    this.dottedBorder = false,
    this.borderColor,
    this.showAlertBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Optional top flow divider
            if (showFlowDividerTop) buildFlowDivider(),

            // Optional top border divider
            if (showTopDivider) _divider(),

            // Main tile body and background
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: dottedBorder
                  ? DottedBorder(
                      color: borderColor ?? textColor,
                      strokeWidth: 2.0,
                      dashPattern: [8, 10],
                      radius: Radius.circular(10),
                      borderType: BorderType.RRect,
                      child: _buildListTile())
                  : Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          color: color,
                          gradient: gradient),
                      child: _buildListTile(),
                    ),
            ),

            // Optional bottom border divider
            if (showBottomDivider) _divider(),

            // Optional bottom flow divider
            if (showFlowDividerBottom) buildFlowDivider()
          ],
        ),
      ),
    );
  }

  static Padding buildFlowDivider({EdgeInsetsGeometry padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 16, bottom: 16),
      child: Image.asset("assets/images/path.png"),
    );
  }

  ListTile _buildListTile() {
    return ListTile(
        onTap: onTap,
        key: key,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.listItem.copyWith(color: textColor),
            ),
            if (showAlertBadge) ...[
              padx(8),
              Badge(
                badgeContent: Text("!",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                padding: EdgeInsets.all(8),
                toAnimate: false,
              )
            ]
          ],
        ),
        leading: image,
        trailing: trailing ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showDragHandle) Icon(Icons.menu),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.chevron_right, color: textColor),
                  ),
              ],
            ));
  }

  Widget _divider() {
    return Container(height: 1.0, color: Color(0xffd5d7e2));
  }
}
