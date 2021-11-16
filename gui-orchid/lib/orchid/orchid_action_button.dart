import 'package:flutter/material.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'orchid_text.dart';

// Large floating rounded rect button with optional radial purple gradient
class OrchidActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double gradientRadius;

  // TODO: Remove and behave like a regular button relying on onPress
  final bool enabled;

  const OrchidActionButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    // TODO: Remove and behave like a regular button relying on onPress
    @required this.enabled,
    this.gradientRadius = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Gradient radialGradient = RadialGradient(
      radius: gradientRadius,
      colors: [Color(0xFFB88DFC), Color(0xFF8C61E1)],
    );

    return AbsorbPointer(
      absorbing: !enabled,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 294,
          height: 52,
          child: GradientBorder(
            strokeWidth: 1.5,
            radius: 16,
            gradient: OrchidGradients.verticalTransparentGradient,
            child: FlatButton(
                color: Color(0xffaca3bc),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    gradient: enabled ? radialGradient : null,
                  ),
                  child: Center(
                      child: Text(text, style: OrchidText.button.black)),
                ),
                // If onPressed is null this does not render the background color
                onPressed: onPressed),
          ),
        ),
      ),
    );
  }
}
