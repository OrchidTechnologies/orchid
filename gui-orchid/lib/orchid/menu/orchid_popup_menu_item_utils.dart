import 'package:orchid/orchid/orchid.dart';

class OrchidPopupMenuItemUtils {
  static PopupMenuItem listMenuItem({
    required BuildContext context,
    required bool selected,
    String? title,
    Widget? body,
    required VoidCallback onTap,
    required TextStyle textStyle,
  }) {
    return PopupMenuItem(
      padding: EdgeInsets.zero,
      child: ListTile(
        selected: selected,
        selectedTileColor: OrchidColors.selected_color_dark,
        title: body ?? Text(title ?? '', style: textStyle),
        onTap: () {
          // Close the menu item
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}
