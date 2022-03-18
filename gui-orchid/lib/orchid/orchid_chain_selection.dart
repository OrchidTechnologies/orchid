import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';

typedef ChainSelectionCallback = void Function(Chain chain);

class ChainSelectionDropdown extends StatefulWidget {
  final ChainSelectionCallback onSelection;
  final Chain selected;
  final bool enabled;

  ChainSelectionDropdown({
    Key key,
    @required this.onSelection,
    this.selected,
    this.enabled = true,
  }) : super(key: key);

  @override
  _ChainSelectionDropdownState createState() => _ChainSelectionDropdownState();
}

class _ChainSelectionDropdownState extends State<ChainSelectionDropdown> {
  List<Chain> _chains;

  @override
  void initState() {
    super.initState();
    _chains = Chains.map.values.where((e) => e != Chains.GanacheTest).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      decoration:
          widget.enabled ? OrchidTextField.textFieldEnabledDecoration : null,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Container(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: OrchidColors.dark_background,
              focusColor: OrchidColors.purple_menu,
            ),
            child: DropdownButton<Chain>(
              hint: Text(s.chooseChain, style: OrchidText.button),
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
    List<DropdownMenuItem<Chain>> items = [];

    if (_chains != null) {
      items.addAll(_chains.map((chain) {
        return new DropdownMenuItem<Chain>(
          value: chain,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: SizedBox(width: 24, height: 24, child: chain.icon),
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
    }

    return items;
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
