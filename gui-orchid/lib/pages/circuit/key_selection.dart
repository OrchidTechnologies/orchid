import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/util/streams.dart';

typedef KeySelectionCallback = void Function(KeySelectionItem key);

class KeySelectionDropdown extends StatefulWidget {
  final KeySelectionCallback onSelection;
  final KeySelectionItem initialSelection;
  final bool enabled;

  // Fixed options
  static final generateKeyOption =
      KeySelectionMenuOption(displayStringGenerator: (context) {
    return S.of(context).generateNewKey;
  });
  static final importKeyOption =
      KeySelectionMenuOption(displayStringGenerator: (context) {
    return S.of(context).importKey;
  });

  KeySelectionDropdown(
      {Key key,
      @required this.onSelection,
      this.initialSelection,
      this.enabled = false})
      : super(key: key);

  @override
  _KeySelectionDropdownState createState() => _KeySelectionDropdownState();
}

class _KeySelectionDropdownState extends State<KeySelectionDropdown> {
  List<StoredEthereumKey> _keys = [];
  KeySelectionItem _selectedItem;
  List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    // If an initial key selection is provided use it
    if (widget.initialSelection != null) {
      this._selectedItem = widget.initialSelection;
    }

    // Monitor changes to keys
    (await UserPreferences().keys.streamAsync()).listen((keys) {
      setState(() {
        this._keys = keys;
        if (_selectedItem != null &&
            !_keys.contains(_selectedItem.keyRef.getFrom(keys))) {
          _selectedItem = null;
          widget.onSelection(null);
        }
      });
    }).dispose(_subs);

    // Update all state
    setState(() {});
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
            child: DropdownButton<KeySelectionItem>(
              hint: Text(s.chooseIdentity).button,
              isExpanded: true,
              icon: !widget.enabled ? Icon(Icons.add, size: 0) : null,
              underline: Container(),
              // suppress the underline
              value: _selectedItem,
              items: _getDropdownItems(),
              onChanged: (KeySelectionItem item) {
                setState(() {
                  _selectedItem = item;
                });
                widget.onSelection(item);
              },
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<KeySelectionItem>> _getDropdownItems() {
    List<DropdownMenuItem<KeySelectionItem>> items = [];

    // Add the fixed options
    /*
    items.addAll([
      DropdownMenuItem<KeySelectionItem>(
        value: KeySelectionItem(option: KeySelectionDropdown.generateKeyOption),
        child:
            Text(KeySelectionDropdown.generateKeyOption.displayName(context)),
      ),
      DropdownMenuItem<KeySelectionItem>(
        value: KeySelectionItem(option: KeySelectionDropdown.importKeyOption),
        child: Text(KeySelectionDropdown.importKeyOption.displayName(context)),
      )
    ]);
     */

    if (_keys != null) {
      items.addAll(_keys.map((key) {
        var address = key.get().address;
        var identicon = OrchidCircularIdenticon(address: address, size: 24);
        return new DropdownMenuItem<KeySelectionItem>(
            value: KeySelectionItem(keyRef: key.ref()),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: identicon,
                ),
                Flexible(
                  child: Text(
                    address.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: OrchidText.button,
                  ),
                ),
              ],
            ));
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
    _subs.dispose();
  }
}

/// Represents a fixed option such as "generate a new key"
class KeySelectionMenuOption {
  String Function(BuildContext context) displayStringGenerator;

  String displayName(BuildContext context) {
    return displayStringGenerator(context);
  }

  KeySelectionMenuOption({this.displayStringGenerator});
}

/// An item in the key selection drop down list.
/// Holds either a key or a key selection option.
class KeySelectionItem {
  StoredEthereumKeyRef keyRef;
  KeySelectionMenuOption option;

  KeySelectionItem(
      {StoredEthereumKeyRef keyRef, KeySelectionMenuOption option}) {
    assert(keyRef == null || option == null);
    this.keyRef = keyRef;
    this.option = option;
  }

  bool operator ==(o) =>
      o is KeySelectionItem &&
      o.option == option &&
      o.keyRef?.keyUid == keyRef?.keyUid;

  @override
  String toString() {
    return 'KeySelectionItem{keyRef: $keyRef, option: $option}';
  }
}
