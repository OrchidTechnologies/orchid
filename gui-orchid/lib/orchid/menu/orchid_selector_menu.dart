import 'package:orchid/orchid/orchid.dart';
import 'color_popup_menu_item.dart';
import 'orchid_popup_menu_button.dart';

/// A popup menu style selector that renders text items with optional icons
/// and manages item selection and menu button appearance when open and closed.
class OrchidSelectorMenu<T> extends StatefulWidget {
  final ValueChanged<T>? onSelection;
  final T? selected;
  final bool enabled;
  final double width;

  /// The list of items and generators for display
  final List<T> items;
  final Widget Function(T item)? iconForItem;
  final String Function(T item) titleForItem;

  /// The title to display when no item is selected
  final String titleUnselected;

  /// The title icon to display when no item is selected in icon only mode.
  final Widget? titleIconUnselected;

  /// If true display the title instead of the title
  final bool titleIconOnly;

  // highlight the selected item in the menu
  final bool highlightSelected;

  static const double DEFAULT_WIDTH = 273.0;

  OrchidSelectorMenu({
    Key? key,
    this.selected,
    this.onSelection,
    this.enabled = true,
    this.width = DEFAULT_WIDTH,
    required this.titleUnselected,
    this.titleIconUnselected,
    this.titleIconOnly = false,
    required this.items,
    this.iconForItem,
    required this.titleForItem,
    this.highlightSelected = true,
  }) : super(key: key);

  @override
  State<OrchidSelectorMenu<T>> createState() => _OrchidSelectorMenuState<T>();
}

class _OrchidSelectorMenuState<T> extends State<OrchidSelectorMenu<T>> {
  bool _menuOpen = false;

  double get _width => widget.width;
  final _textStyle = OrchidText.medium_16_025.semibold.copyWith(height: 1.8);

  @override
  Widget build(BuildContext context) {
    return OrchidPopupMenuButton<T>(
      // disabledAppearance: !widget.enabled,
      width: _width,
      height: 40,
      selected: _menuOpen,
      onSelected: (_) {
        setState(() {
          _menuOpen = false;
        });
      },
      onCanceled: () {
        setState(() {
          _menuOpen = false;
        });
      },
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _menuOpen = true;
        });
        return _buildItems();
      },
      child: widget.selected != null
          ? _buildTitleSelected()
          : _buildTitleUnselected(context),
    );
  }

  Widget _buildTitleUnselected(BuildContext context) {
    if (widget.titleIconOnly)
      return FittedBox(
        fit: BoxFit.scaleDown,
        child:
            SizedBox.square(dimension: 25, child: widget.titleIconUnselected),
      );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.titleUnselected,
          style: _textStyle,
        ).left(4),
        Icon(_menuOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white)
            .right(16),
      ],
    ).left(16);
  }

  Widget _buildTitleSelected() {
    return Row(
      mainAxisAlignment: widget.titleIconOnly
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _buildItemRow(
            // widget select is not null here
            value: widget.selected!,
            style: _textStyle,
            iconOnly: widget.titleIconOnly,
          ),
        ),
        if (!widget.titleIconOnly)
          Icon(_menuOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white),
      ],
    ).padx(widget.titleIconOnly ? 0 : 16);
  }

  List<PopupMenuEntry<T>> _buildItems() {
    List<PopupMenuEntry<T>> entries = [];
    entries.addAll(widget.items.map(_buildMenuItem).toList());
    return entries.separatedWith(PopupMenuDivider(height: 1.0));
  }

  PopupMenuItem<T> _buildMenuItem(T value) {
    final selected = value == widget.selected && widget.highlightSelected;
    return ColorPopupMenuItem<T>(
      padding: EdgeInsets.zero,
      color: selected ? OrchidColors.selected_color_dark : null,
      value: value,
      height: 50.0,
      enabled: widget.enabled,
      child: SizedBox(
        // PopupMenuItem has a max width of popup_menu_.kMenuMaxWidth (about 280pt).
        // Setting the width to infinity does not produce the max.
        width: _width == double.infinity ? 999.0 : _width,
        child: _buildItemRow(
          value: value,
          style: OrchidText.body2,
        ),
      ).padx(16),
      onTap: () {
        // Close the menu item
        // Navigator.pop(context);
        if (widget.onSelection != null) {
          widget.onSelection!(value);
        }
      },
    );
  }

  Widget _buildItemRow({
    required T value,
    TextStyle? style,
    bool iconOnly = false,
  }) {
    final size = 20.0;
    final icon = widget.iconForItem == null ? null : widget.iconForItem!(value);
    final title = widget.titleForItem(value);
    return Row(
      mainAxisAlignment:
          iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        SizedBox(width: size, height: size, child: icon),
        if (!iconOnly)
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: style,
            ).left(16),
          ),
      ],
    );
  }
}
