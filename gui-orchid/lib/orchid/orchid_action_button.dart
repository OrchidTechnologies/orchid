import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

// Large floating rounded rect button with optional radial purple gradient
class OrchidActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double gradientRadius;
  final TextStyle textStyle;

  /// use double.infinity for an expandable button, null for the default width
  final double width;
  final double height;

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
    this.height,
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
                height: height ?? 40,
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
      child: FlatButtonDeprecated(
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
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, style: textStyle ?? OrchidText.button.black)
                      .padx(8)),
            ),
          ),
          // If onPressed is null this does not render the background color
          onPressed: onPressed),
    );
  }
}

class OrchidOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OrchidOutlineButton({
    Key key,
    @required this.text,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Color backgroundColor = OrchidColors.dark_background;
    final enabled = onPressed != null;
    Color backgroundColor = Colors.transparent;
    Color borderColor = enabled ? OrchidColors.tappable : OrchidColors.disabled;
    Color textColor = enabled ? OrchidColors.tappable : OrchidColors.disabled;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 294,
        height: 52,
        child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: borderColor, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.all(Radius.circular(16)))),
          onPressed: onPressed,
          child: Text(
            text,
            style: OrchidText.button.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
