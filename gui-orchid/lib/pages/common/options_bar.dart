import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';

class OptionsBar extends StatelessWidget {
  final Color color;
  final VoidCallback menuPressed;
  final VoidCallback morePressed;

  OptionsBar(
      {@required this.color,
      @required this.menuPressed,
      @required this.morePressed});

  @override
  Widget build(BuildContext context) {
    var drawerButton = IconButton(
      icon: Icon(Icons.menu),
      color: color,
      padding: EdgeInsets.all(0),
      tooltip: S.of(context).settings,
      onPressed: menuPressed,
    );

    var moreButton = Container(
        child: IconButton(
      icon: Icon(Icons.more_vert),
      color: color,
      padding: EdgeInsets.all(0),
      tooltip: S.of(context).more,
      onPressed: morePressed,
    ));

    return Container(
        margin: EdgeInsets.only(left: 12, right: 12),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[drawerButton, moreButton],
        ));
  }
}
