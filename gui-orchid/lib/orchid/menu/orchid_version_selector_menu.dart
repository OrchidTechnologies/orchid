import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/menu/orchid_selector_menu.dart';

typedef VersionSelectorCallback = void Function(int version);

class OrchidVersionSelectorMenu extends StatelessWidget {
  final VersionSelectorCallback onSelection;
  final int? selected;
  final bool enabled;

  final double width;

  final List<int> versions = [0, 1];

  OrchidVersionSelectorMenu({
    Key? key,
    this.selected,
    required this.onSelection,
    this.enabled = true,
    this.width = OrchidSelectorMenu.DEFAULT_WIDTH,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrchidSelectorMenu<int>(
      // items
      items: versions,
      titleUnselected: context.s.version,
      titleForItem: (item) => item.toString(),

      // pass through
      selected: selected,
      onSelection: onSelection,
      enabled: enabled,
      width: width,
      // highlightSelected: selected?.isKnown,
    );
  }
}
