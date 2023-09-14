import 'package:flutter/material.dart';

class FlatButtonDeprecated extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final OutlinedBorder? shape;
  final color; // background color
  final EdgeInsets? padding;

  const FlatButtonDeprecated({
    Key? key,
    required this.child,
    this.onPressed,
    this.shape,
    this.color,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      primary: Colors.black87,
      minimumSize: Size(88, 36),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.0),
      shape: shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
          ),
      backgroundColor: color,
    );
    return TextButton(
      style: flatButtonStyle,
      onPressed: onPressed,
      child: child,
    );
  }
}

class RaisedButtonDeprecated extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final OutlinedBorder? shape;
  final color; // background color
  final double? elevation;
  final EdgeInsets? padding;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Color? disabledColor;

  const RaisedButtonDeprecated({
    Key? key,
    required this.child,
    this.onPressed,
    this.shape,
    this.color,
    this.elevation,
    this.padding,
    this.materialTapTargetSize,
    this.disabledColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      onPrimary: Colors.black87,
      primary: Colors.grey[300],
      minimumSize: Size(88, 36),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16),
      shape: shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
      backgroundColor: color,
      elevation: elevation,
      tapTargetSize: materialTapTargetSize,
      disabledBackgroundColor: disabledColor,
    );
    return ElevatedButton(
      style: raisedButtonStyle,
      onPressed: onPressed,
      child: child,
    );
  }
}
