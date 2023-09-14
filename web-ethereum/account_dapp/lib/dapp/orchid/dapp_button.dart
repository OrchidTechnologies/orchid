import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_action_button.dart';

class DappButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const DappButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.trailing,
    this.textStyle,

    /// use double.infinity for an expandable button, null for the default width
    this.width,
    this.backgroundColor, this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrchidActionButton(
      text: text,
      textStyle: textStyle,
      onPressed: onPressed ?? () {},
      enabled: onPressed != null,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      trailing: trailing,
    );
  }
}
