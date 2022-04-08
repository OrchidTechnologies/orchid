import 'package:orchid/dapp.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/orchid/orchid_chain_selection.dart';
import 'dapp_header_popup_button.dart';

class DappChainSelectorButton extends StatefulWidget {
  final ChainSelectionCallback onSelection;
  final Chain selected;
  final bool enabled;

  /// If true the button will be an icon button
  final bool iconOnly;

  DappChainSelectorButton({
    Key key,
    this.selected,
    this.onSelection,
    this.iconOnly = false,
    this.enabled,
  }) : super(key: key);

  @override
  State<DappChainSelectorButton> createState() =>
      _DappChainSelectorButtonState();
}

class _DappChainSelectorButtonState extends State<DappChainSelectorButton> {
  final _width = 273.0;
  final _textStyle = OrchidText.medium_16_025.semibold.copyWith(height: 1.8);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return DappHeaderPopupMenuButton<Chain>(
        width: _width,
        height: 40,
        selected: _buttonSelected,
        onSelected: (Chain chain) {
          setState(() {
            _buttonSelected = false;
          });
        },
        onCanceled: () {
          setState(() {
            _buttonSelected = false;
          });
        },
        itemBuilder: (itemBuilderContext) {
          setState(() {
            _buttonSelected = true;
          });
          return _buildItems(context);
        },
        child: widget.selected != null
            ? _buildTitleSelected()
            : _buildTitleUnselected(context));
  }

  Widget _buildTitleUnselected(BuildContext context) {
    if (widget.iconOnly)
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.square(
            dimension: 25, child: OrchidAsset.chain.unknown_chain),
      );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(context.s.chooseChain, style: _textStyle).left(4),
        Icon(_buttonSelected ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white)
            .right(16),
      ],
    ).left(16);
  }

  Widget _buildTitleSelected() {
    return Row(
      mainAxisAlignment: widget.iconOnly
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        _buildChainRow(
          chain: widget.selected,
          style: _textStyle,
          iconOnly: widget.iconOnly,
        ),
        if (!widget.iconOnly)
          Icon(_buttonSelected ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white),
      ],
    ).padx(widget.iconOnly ? 0 : 16);
  }

  List<Chain> chains =
      Chains.map.values.where((e) => e != Chains.GanacheTest).toList();

  List<PopupMenuEntry<Chain>> _buildItems(BuildContext context) {
    List<PopupMenuEntry<Chain>> items = [];
    items.addAll(chains.map(_buildChainMenuItem).toList());
    return items.separatedWith(PopupMenuDivider(height: 1.0));
  }

  PopupMenuItem<Chain> _buildChainMenuItem(Chain chain) {
    final selected = chain == widget.selected;
    return _ColorPopupMenuItem<Chain>(
      padding: EdgeInsets.zero,
      color: selected ? OrchidColors.selected_color_dark : null,
      value: chain,
      height: 50.0,
      enabled: widget.enabled,
      child: SizedBox(
        width: _width,
        child: _buildChainRow(
          chain: chain,
          style: OrchidText.body2,
        ),
      ).left(24),
      onTap: () {
        // Close the menu item
        // Navigator.pop(context);
        widget.onSelection(chain);
      },
    );
  }

  Widget _buildChainRow({
    Chain chain,
    TextStyle style,
    bool iconOnly = false,
  }) {
    final size = 20.0;
    return Container(
      child: Row(
        mainAxisAlignment:
            iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          SizedBox(width: size, height: size, child: chain.icon),
          if (!iconOnly)
            Text(
              chain.name,
              // overflow: TextOverflow.ellipsis,
              style: style,
            ).left(16),
        ],
      ),
    );
  }
}

/// Support a background color for individual menu items
class _ColorPopupMenuItem<T> extends PopupMenuItem<T> {
  final Color color;
  final double height;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _ColorPopupMenuItem({
    Key key,
    T value,
    bool enabled = true,
    Widget child,
    this.color,
    this.height,
    this.onTap,
    this.padding,
  }) : super(
          key: key,
          value: value,
          enabled: enabled,
          height: height,
          onTap: onTap,
          padding: padding,
          child: child,
        );

  @override
  _DappPopupMenuItemState<T> createState() => _DappPopupMenuItemState<T>();
}

class _DappPopupMenuItemState<T>
    extends PopupMenuItemState<T, _ColorPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      child: super.build(context),
    );
  }
}
