// @dart=2.9
import 'package:orchid/orchid.dart';
import 'dart:async';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'orchid_selector_menu.dart';

typedef KeySelectorCallback = void Function(KeySelectionItem key);

// TODO: recast as stateless by supplying keys with the pref builder
class OrchidKeySelectorMenu extends StatefulWidget {
  final KeySelectorCallback onSelection;
  final KeySelectionItem selected;
  final bool enabled;

  // Fixed options
  static final generateKeyOption =
      KeySelectionMenuOption(displayStringGenerator: (context) {
    return S.of(context).generateNewKey;
  });
  static final importKeyOption =
      KeySelectionMenuOption(displayStringGenerator: (context) {
    return S.of(context).importIdentity;
  });

  OrchidKeySelectorMenu(
      {Key key,
      @required this.onSelection,
      this.selected,
      this.enabled = false})
      : super(key: key);

  @override
  _OrchidKeySelectorMenuState createState() => _OrchidKeySelectorMenuState();
}

class _OrchidKeySelectorMenuState extends State<OrchidKeySelectorMenu> {
  List<StoredEthereumKey> _keys; // initially null
  List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    // Monitor changes to keys
    UserPreferences().keys.stream().listen((keys) {
      setState(() {
        this._keys = keys;

        // Guard that the selected key ref exists in the keystore,
        // else invalidate the selection.
        final keyRef = widget.selected?.keyRef;
        if (keyRef != null && !keyRef.isFoundIn(keys)) {
          widget.onSelection(null);
        }
      });
    }).dispose(_subs);

    // Update all state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OrchidSelectorMenu<KeySelectionItem>(
      // items
      items: _getItems(),
      titleUnselected: context.s.chooseIdentity,
      titleForItem: (item) => item.title(context),
      iconForItem: (item) => item.icon(),

      // pass through
      selected: widget.selected,
      onSelection: widget.onSelection,
      enabled: widget.enabled,
      width: double.infinity,
    );
  }

  List<KeySelectionItem> _getItems() {
    List<KeySelectionItem> items = [];
    if (_keys != null) {
      items.addAll(
          _keys.map((key) => KeySelectionItem(keyRef: key.ref())).toList());
    }
    // Add the fixed options
    items.addAll([
      KeySelectionItem(option: OrchidKeySelectorMenu.importKeyOption),
    ]);

    return items;
  }

  S get s => S.of(context);

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

  EthereumAddress get address => keyRef.get().address;

  String title(BuildContext context) {
    if (keyRef != null) {
      return address.toString(prefix: true, elide: false);
    } else {
      return option.displayName(context);
    }
  }

  Widget icon() {
    if (keyRef != null) {
      return OrchidCircularIdenticon(address: address, size: 24);
    } else {
      return null;
    }
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
