import 'package:orchid/orchid/orchid.dart';

/// Rounded rect popup menu button with the Orchid theme including a selected state.
class OrchidPopupMenuButton<T> extends StatelessWidget {
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuCanceled? onCanceled;
  final PopupMenuItemBuilder<T> itemBuilder;
  final Widget? child;
  final bool selected;
  final double? width, height;
  final bool showBorder;
  final Offset? offset;
  final Color? backgroundColor;

  // When true the button shows a disabled appearance (but continues to trigger the menu).
  final bool disabledAppearance;
  final bool enabled;

  const OrchidPopupMenuButton({
    Key? key,
    required this.itemBuilder,
    required this.selected,
    this.onSelected,
    this.onCanceled,
    this.child,
    this.width,
    required this.height,
    this.showBorder = false,
    this.offset,
    this.enabled = true,
    this.disabledAppearance = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var buttonColor = backgroundColor ??
        (selected ? OrchidColors.new_purple_divider : OrchidColors.new_purple);
    buttonColor = disabledAppearance ? OrchidColors.disabled : buttonColor;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: buttonColor,
        border: showBorder ? Border.all(color: Colors.white) : null,
        borderRadius: BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
      child: Theme(
        data: ThemeData(
          dividerTheme:
              DividerThemeData(color: OrchidColors.new_purple_divider),
          // Turn off Inkwell effect
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<T>(
          enabled: enabled,
          padding: EdgeInsets.zero,
          offset: offset ?? Offset(0, 40.0 + 12.0),
          // The color of the dropdown menu item background
          color: OrchidColors.new_purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16.0),
            ),
          ),
          child: child,
          onSelected: onSelected,
          onCanceled: onCanceled,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
