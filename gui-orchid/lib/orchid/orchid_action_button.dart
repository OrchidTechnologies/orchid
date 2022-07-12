import 'package:flutter/material.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'orchid_text.dart';

// Large floating rounded rect button with optional radial purple gradient
class OrchidActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double gradientRadius;
  final TextStyle textStyle;

  /// use double.infinity for an expandable button, null for the default width
  final double width;

  final Color backgroundColor;
  final Color textColor;

  // TODO: Remove and behave like a regular button relying on onPress
  final bool enabled;

  const OrchidActionButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    // TODO: Remove and behave like a regular button relying on onPress
    @required this.enabled,
    this.gradientRadius = 3.0,
    this.textStyle,
    this.width,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: width == double.infinity
          ? _buildButton()
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width ?? 294,
                height: 40,
                child: _buildButton(),
              ),
            ),
    );
  }

  GradientBorder _buildButton() {
    Gradient radialGradient = backgroundColor == null
        ? RadialGradient(
            radius: gradientRadius,
            colors: [Color(0xFFB88DFC), Color(0xFF8C61E1)],
          )
        : null;
    return GradientBorder(
      strokeWidth: 1.5,
      radius: 16,
      gradient: OrchidGradients.verticalTransparentGradient,
      child: FlatButton(
          color: backgroundColor ?? Color(0xffaca3bc),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              gradient: enabled ? radialGradient : null,
            ),
            child: Center(
                child: Text(text, style: textStyle ?? OrchidText.button.black)),
          ),
          // If onPressed is null this does not render the background color
          onPressed: onPressed),
    );
  }
}
