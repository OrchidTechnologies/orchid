import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_text_field.dart';

typedef FunderSelectionCallback = void Function(FunderSelectionItem key);

class FunderSelectionDropdown extends StatefulWidget {
  final FunderSelectionCallback onSelection;
  final FunderSelectionItem initialSelection;
  bool enabled;
  final StoredEthereumKeyRef signer;

  // Fixed options
  static final pasteKeyOption =
      FunderSelectionMenuOption(displayStringGenerator: (context) {
    // return S.of(context).paste;
    return "Paste Address";
  });

  FunderSelectionDropdown({
    Key key,
    @required this.signer,
    @required this.onSelection,
    this.initialSelection,
    this.enabled = false,
  }) : super(key: key) {
    if (signer == null) {
      enabled = false;
    }
  }

  @override
  _FunderSelectionDropdownState createState() =>
      _FunderSelectionDropdownState();
}

class _FunderSelectionDropdownState extends State<FunderSelectionDropdown> {
  StoredEthereumKey _signer;
  List<EthereumAddress> _funderAddresses = [];
  FunderSelectionItem _selectedItem;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _signer = await widget.signer.get();
    var cached = await UserPreferences().cachedDiscoveredAccounts.get();
    _funderAddresses = cached
        .where((account) => account.identityUid == _signer.uid)
        .map((account) => account.funder)
        .toList();

    // If the cached accounts list does not include the selected funder add it.
    // This can happen if the user pasted a prospective account that hasn't been
    // funded yet.
    if (widget.initialSelection?.funder != null &&
        !_funderAddresses.contains(widget.initialSelection?.funder)) {
      _funderAddresses.add(widget.initialSelection.funder);
    }

    // If an initial key selection is provided use it
    if (widget.initialSelection != null) {
      this._selectedItem = widget.initialSelection;
    }

    // Update all state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      decoration:
          widget.enabled ? AppTextField.textFieldEnabledDecoration : null,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Container(
          child: DropdownButton<FunderSelectionItem>(
            hint: Text("Choose Address"),
            isExpanded: true,
            icon: !widget.enabled ? Icon(Icons.add, size: 0) : null,
            //underline: !widget.enabled ? Container() : null,
            underline: Container(),
            // suppress the underline
            value: _selectedItem,
            items: _getDropdownItems(),
            onChanged: (FunderSelectionItem item) {
              setState(() {
                _selectedItem = item;
              });
              widget.onSelection(item);
            },
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<FunderSelectionItem>> _getDropdownItems() {
    List<DropdownMenuItem<FunderSelectionItem>> items = [];

    if (_funderAddresses != null) {
      items.addAll(_funderAddresses.map((funder) {
        return new DropdownMenuItem<FunderSelectionItem>(
          value: FunderSelectionItem(funder: funder),
          child: Text(funder.toString(prefix: true),
              overflow: TextOverflow.ellipsis, style: TextStyle()),
        );
      }).toList());
    }

    // Add the fixed options
    items.addAll([
      DropdownMenuItem<FunderSelectionItem>(
        value:
            FunderSelectionItem(option: FunderSelectionDropdown.pasteKeyOption),
        child:
            Text(FunderSelectionDropdown.pasteKeyOption.displayName(context)),
      ),
    ]);

    return items;
  }

  S get s {
    return S.of(context);
  }
}

/// Represents a fixed option such as "generate a new key"
class FunderSelectionMenuOption {
  String Function(BuildContext context) displayStringGenerator;

  String displayName(BuildContext context) {
    return displayStringGenerator(context);
  }

  FunderSelectionMenuOption({this.displayStringGenerator});
}

/// An item in the key selection drop down list.
/// Holds either a key or a key selection option.
class FunderSelectionItem {
  EthereumAddress funder;
  FunderSelectionMenuOption option;

  FunderSelectionItem(
      {EthereumAddress funder, FunderSelectionMenuOption option}) {
    assert(funder == null || option == null);
    this.funder = funder;
    this.option = option;
  }

  bool operator ==(o) =>
      o is FunderSelectionItem && o.option == option && o.funder == funder;

  @override
  String toString() {
    return 'FunderSelectionItem{keyRef: $funder, option: $option}';
  }
}
