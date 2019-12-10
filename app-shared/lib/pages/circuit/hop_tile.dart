import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  const HopTile({
    Key key,
    this.title,
    this.onTap,
    this.image,
    this.textColor,
    this.color,
    this.gradient,
    this.showDragHandle = true,
    this.showFlowDividerBottom = false,
    this.showFlowDividerTop = false,
    this.showTopDivider = false,
    this.showBottomDivider = true,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Optional top flow divider
        if (showFlowDividerTop)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Image.asset("assets/images/expandMore.png"),
          ),

        // Optional top border divider
        if (showTopDivider)
          _divider(),

        // Main tile body
        Container(
          decoration: BoxDecoration(color: color, gradient: gradient),
          // Allow the tile background to extend into the safe area but not the content
          child: SafeArea(
            child: ListTile(
                onTap: onTap,
                key: key,
                title: Text(
                  title,
                  style: AppText.listItem.copyWith(color: textColor),
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
                            child: Icon(Icons.chevron_right),
                          ),
                      ],
                    )),
          ),
        ),

        // Optional bottom border divider
        if (showBottomDivider)
          _divider(),

        // Optional bottom flow divider
        if (showFlowDividerBottom)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Image.asset("assets/images/expandMore.png"),
          )
      ],
    );
  }

  Widget _divider() {
    return Container(height: 1.0, color: Color(0xffd5d7e2));
  }
}
