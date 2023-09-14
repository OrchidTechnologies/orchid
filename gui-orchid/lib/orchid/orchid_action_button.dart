import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

// Large floating rounded rect button with optional radial purple gradient
class OrchidActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double gradientRadius;
  final TextStyle? textStyle;

  /// use double.infinity for an expandable button, null for the default width
  final double? width;
  final double? height;

  final Color? backgroundColor;
  final Color? textColor;

  final Widget? trailing;

  // TODO: Remove and behave like a regular button relying on onPress
  final bool? enabled;

  const OrchidActionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.gradientRadius = 3.0,
    this.textStyle,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.trailing,
    @deprecated
    this.enabled,
  }) : super(key: key);

  bool get isEnabled => enabled ?? (onPressed != null);

  @override
  Widget build(BuildContext context) {
    return width == double.infinity
        ? _buildButton()
        : FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: width ?? 294,
        height: height ?? 50,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    Gradient? radialGradient = backgroundColor == null
        ? RadialGradient(
      radius: gradientRadius,
      colors: [Color(0xFFB88DFC), Color(0xFF8C61E1)],
    )
        : null;
    final label = Text(text, style: textStyle ?? OrchidText.button.black);

    final ButtonStyle buttonStyle = TextButton.styleFrom(
      primary: Colors.black87,
      minimumSize: Size(88, 36),
      padding: EdgeInsets.zero,
      backgroundColor: isEnabled ? null : (backgroundColor ?? Color(0xffaca3bc)),
    );

    final textButton = TextButton(
      style: buttonStyle,
      onPressed: isEnabled ? onPressed : null,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              label,
              trailing ?? Container(),
            ],
          ).padx(8),
        ),
      ),
    );

    return GradientBorder(
      strokeWidth: 1.5,
      radius: 16,
      gradient: OrchidGradients.verticalTransparentGradient,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isEnabled ? radialGradient : null,
                ),
              ),
            ),
            textButton,
          ],
        ),
      ),
    );
  }
}

class OrchidOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;

  const OrchidOutlineButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Color backgroundColor = OrchidColors.dark_background;
    final enabled = onPressed != null;
    Color backgroundColor = Colors.transparent;
    Color _borderColor = borderColor ??
        (enabled ? OrchidColors.tappable : OrchidColors.disabled);
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
                      color: _borderColor, width: 2, style: BorderStyle.solid),
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
