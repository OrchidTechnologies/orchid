import 'package:orchid/orchid.dart';

/// Rounded rect popup menu button with the dapp theme.
class DappHeaderPopupMenuButton<T> extends StatelessWidget {
  final PopupMenuItemSelected<T> onSelected;
  final PopupMenuCanceled onCanceled;
  final PopupMenuItemBuilder<T> itemBuilder;
  final Widget child;
  final bool selected;
  final double width, height;
  final bool showBorder;
  final Offset offset;

  const DappHeaderPopupMenuButton({
    Key key,
    @required this.itemBuilder,
    @required this.selected,
    this.onSelected,
    this.onCanceled,
    this.child,
    this.width,
    this.height,
    this.showBorder = false,
    this.offset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: selected
            ? OrchidColors.new_purple_divider
            : OrchidColors.new_purple,
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
          padding: EdgeInsets.zero,
          offset: offset ?? Offset(0, 40.0 + 12.0),
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
