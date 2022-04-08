import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/util/localization.dart';

typedef ChainSelectionCallback = void Function(Chain chain);

class ChainSelectionDropdown extends StatefulWidget {
  final ChainSelectionCallback onSelection;
  final Chain selected;
  final bool enabled;
  final BoxDecoration buttonDecoration;
  final Color canvasColor;
  final TextStyle textStyle;
  final double iconSize;

  ChainSelectionDropdown({
    Key key,
    @required this.onSelection,
    this.selected,
    this.enabled = true,
    this.buttonDecoration,
    this.canvasColor,
    this.textStyle,
    this.iconSize,
  }) : super(key: key);

  @override
  _ChainSelectionDropdownState createState() => _ChainSelectionDropdownState();
}

class _ChainSelectionDropdownState extends State<ChainSelectionDropdown> {
  @override
  Widget build(BuildContext context) {
    final defaultCanvasColor = OrchidColors.dark_background;
    final defaultButtonDecoration =
        widget.enabled ? OrchidTextField.textFieldEnabledDecoration : null;
    final defaultTextStyle = OrchidText.button;

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      decoration: widget.buttonDecoration ?? defaultButtonDecoration,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Container(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: widget.canvasColor ?? defaultCanvasColor,
              focusColor: OrchidColors.purple_menu,
            ),
            child: DropdownButton<Chain>(
              borderRadius: BorderRadius.circular(16),
              hint: Text(context.s.chooseChain, style: widget.textStyle ?? defaultTextStyle)
                  .top(4),
              isExpanded: true,
              icon: !widget.enabled ? Icon(Icons.add, size: 0) : null,
              // suppress the underline
              underline: Container(),
              value: widget.selected,
              items: _getDropdownItems(),
              onChanged: widget.onSelection,
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<Chain>> _getDropdownItems() {
    List<Chain> chains = Chains.map.values.where((e) => e != Chains.GanacheTest).toList();
    final size = widget.iconSize ?? 24;

    List<DropdownMenuItem<Chain>> items = [];
    items.addAll(chains.map((chain) {
      return new DropdownMenuItem<Chain>(
        value: chain,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: SizedBox(width: size, height: size, child: chain.icon),
            ),
            Flexible(
              child: Text(
                chain.name,
                // overflow: TextOverflow.ellipsis,
                style: OrchidText.button,
              ),
            ),
          ],
        ),
      );
    }).toList());

    return items;
  }
}
