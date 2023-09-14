import 'package:flutter/material.dart';

class RoundedRect extends StatelessWidget {
  final Widget? child;
  final double? radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  const RoundedRect({
    Key? key,
    this.child,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth ?? 2.0,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(radius ?? 16.0),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
