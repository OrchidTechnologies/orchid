import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';

typedef ChainSelectionCallback = void Function(Chain chain);

class ChainSelectionDropdown extends StatefulWidget {
  final ChainSelectionCallback onSelection;
  final Chain initialSelection;
  final bool enabled;

  ChainSelectionDropdown({
    Key key,
    @required this.onSelection,
    this.initialSelection,
    this.enabled = true,
  }) : super(key: key);

  @override
  _ChainSelectionDropdownState createState() => _ChainSelectionDropdownState();
}

class _ChainSelectionDropdownState extends State<ChainSelectionDropdown> {
  List<Chain> _chains;
  Chain _selectedChain;

  @override
  void initState() {
    super.initState();

    _chains = Chains.map.values.where((e) => e != Chains.GanacheTest).toList();

    // If an initial key selection is provided use it
    if (widget.initialSelection != null) {
      this._selectedChain = widget.initialSelection;
    } //else {
      // this._selectedChain = Chains.Ethereum;
    // }

    initStateAsync();
  }

  void initStateAsync() async {}

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
              hint: Text("Choose Chain", style: OrchidText.button),
              isExpanded: true,
              icon: !widget.enabled ? Icon(Icons.add, size: 0) : null,
              underline: Container(),
              // suppress the underline
              value: _selectedChain,
              items: _getDropdownItems(),
              onChanged: (Chain item) {
                setState(() {
                  _selectedChain = item;
                });
                widget.onSelection(item);
              },
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
