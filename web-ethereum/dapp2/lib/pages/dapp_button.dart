import 'package:flutter/material.dart';
import 'package:orchid/common/app_buttons.dart';

class DappButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget trailing;

  const DappButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var height = 42.0;
    return Container(
        height: height,
        child: RoundedRectButton(
          text: text,
          textColor: Colors.black,
          lineHeight: 1.2,
          trailing: trailing,
          onPressed: onPressed,
        ));
  }
}
