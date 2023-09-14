import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/orchid/menu/orchid_selector_menu.dart';

typedef ChainSelectorCallback = void Function(Chain chain);

class OrchidChainSelectorMenu extends StatelessWidget {
  final ChainSelectorCallback onSelection;
  final Chain? selected;
  final bool enabled;

  /// If true the button will be an icon button
  final bool iconOnly;

  final double width;

  final List<Chain> chains =
      Chains.map.values.where((e) => e != Chains.GanacheTest).toList();

  OrchidChainSelectorMenu({
    Key? key,
    this.selected,
    required this.onSelection,
    this.iconOnly = false,
    this.enabled = true,
    this.width = OrchidSelectorMenu.DEFAULT_WIDTH
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrchidSelectorMenu<Chain>(
      // items
      items: chains,
      titleUnselected: context.s.chooseChain,
      titleIconUnselected: OrchidAsset.chain.unknown_chain,
      titleForItem: (chain) => chain.name,
      iconForItem: (chain) => chain.icon,

      // pass through
      selected: selected,
      onSelection: onSelection,
      titleIconOnly: iconOnly,
      enabled: enabled,
      width: width,
      // support testing
      highlightSelected: selected?.isKnown ?? true,
    );
  }
}
