import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/material.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid_circular_progress.dart';
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
    this.backgroundColor,
    this.height,
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

// Extend DappButton with a transaction status indicator.
class DappTransactionButton extends DappButton {
  final bool txPending;

  const DappTransactionButton({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? trailing,
    TextStyle? textStyle,
    double? width,
    double? height,
    Color? backgroundColor,
    required this.txPending,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          trailing: trailing,
          textStyle: textStyle,
          width: width,
          height: height,
          backgroundColor: backgroundColor,
        );

  @override
  Widget build(BuildContext context) {
    return DappButton(
      text: txPending ? "Waiting for Transaction" : text,
      trailing: txPending ? OrchidCircularProgressIndicator.smallIndeterminate().left(16) : trailing,
      onPressed: onPressed,
      textStyle: textStyle,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
    );
  }
}
