import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_action_button.dart';

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
    return OrchidActionButton(
      text: text,
      onPressed: onPressed ?? () {},
      enabled: onPressed != null,
    );
  }
}
