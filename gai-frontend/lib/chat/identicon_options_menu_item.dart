import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';

// TODO: Port this back to the orchid lib for the account dapp, etc.
// Note: so much boilerplate for these..
class IdenticonOptionsMenuItem extends StatelessWidget {
  const IdenticonOptionsMenuItem({
    super.key,
    required TextStyle textStyle,
    required this.expanded,
  }) : _textStyle = textStyle;

  final TextStyle _textStyle;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return UserPreferencesUI().useBlockiesIdenticons.builder(
      (useBlockies) {
        if (useBlockies == null) {
          return Container();
        }
        return ExpandingPopupMenuItem(
          expanded: expanded,
          title: context.s.identiconStyle,
          currentSelectionText:
              (!expanded ? (useBlockies ? context.s.blockies : context.s.jazzicon) : ''),
          expandedContent: _identiconOptions(context, useBlockies),
          expandedHeight: 108,
          textStyle: _textStyle,
        );
      },
    );
  }

  Widget _identiconOptions(BuildContext context, bool useBlockies) {
    final pref = UserPreferencesUI().useBlockiesIdenticons;
    // const checkmark = '\u2713';
    // String check(bool checked) => checked ? ' $checkmark ' : '   ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PopupMenuDivider(height: 1.0),
        _listMenuItem(
          context: context,
          selected: useBlockies,
          title: context.s.blockies,
          // selected: false,
          // title: check(useBlockies) + context.s.blockies,
          onTap: () async {
            await pref.set(true);
          },
        ),
        const PopupMenuDivider(height: 1.0),
        _listMenuItem(
          context: context,
          selected: !useBlockies,
          title: context.s.jazzicon,
          // selected: false,
          // title: check(!useBlockies) + context.s.jazzicon,
          onTap: () async {
            await pref.set(false);
          },
        ),
      ],
    );
  }

  PopupMenuItem _listMenuItem({
    required BuildContext context,
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return OrchidPopupMenuItemUtils.listMenuItem(
      context: context,
      selected: selected,
      title: title,
      onTap: onTap,
      textStyle: _textStyle,
    );
  }
}
