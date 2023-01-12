import 'package:orchid/orchid.dart';
import 'dart:async';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'orchid_selector_menu.dart';

typedef FunderSelectorCallback = void Function(FunderSelectionItem key);

// TODO: recast as stateless by supplying accounts with the pref builder
class OrchidFunderSelectorMenu extends StatefulWidget {
  final FunderSelectorCallback onSelection;
  final FunderSelectionItem selected;
  final bool enabled;
  final StoredEthereumKeyRef signer;

  // Fixed menu options
  static final pasteAddressOption =
      FunderSelectionMenuOption(displayStringGenerator: (context) {
    return context.s.pasteAddress;
  });

  OrchidFunderSelectorMenu({
    Key key,
    @required this.signer,
    @required this.onSelection,
    this.selected,
    bool enabled = false,
  })  : this.enabled = signer == null ? false : enabled,
        super(key: key);

  @override
  _OrchidFunderSelectorMenuState createState() =>
      _OrchidFunderSelectorMenuState();
}

class _OrchidFunderSelectorMenuState extends State<OrchidFunderSelectorMenu> {
  StoredEthereumKey _signer;
  List<Account> _funderAccounts = [];
  List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _signer = widget.signer?.get();

    // Load accounts, listening for updates
    UserPreferences().cachedDiscoveredAccounts.stream().listen((cached) {
      _funderAccounts = cached
          .where((account) => account.signerKeyUid == _signer.uid)
          .toList();

      // If the cached accounts list does not include the selected funder add it.
      // This can happen if the user pasted a prospective account that hasn't been
      // funded yet.
      if (widget.selected?.account != null &&
          !_funderAccounts.contains(widget.selected?.account)) {
        _funderAccounts.add(widget.selected.account);
      }

      if (mounted) {
        setState(() {});
      }
    }).dispose(_subs);

    // Update all state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OrchidSelectorMenu<FunderSelectionItem>(
      // items
      items: _getItems(),
      titleUnselected: context.s.chooseAddress,
      titleForItem: (item) => item.title(context),
      iconForItem: (item) => item.icon(),

      // pass through
      selected: widget.selected,
      onSelection: widget.onSelection,
      enabled: widget.enabled,
      width: double.infinity,
    );
  }

  List<FunderSelectionItem> _getItems() {
    List<FunderSelectionItem> items = [];
    if (_funderAccounts != null) {
      items.addAll(_funderAccounts
          .map((account) => FunderSelectionItem(funderAccount: account))
          .toList());
    }
    // Add the fixed options
    items.addAll([
      FunderSelectionItem(option: OrchidFunderSelectorMenu.pasteAddressOption),
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

/// Represents a fixed option such as 'generate a new key'
class FunderSelectionMenuOption {
  String Function(BuildContext context) displayStringGenerator;

  String displayName(BuildContext context) {
    return displayStringGenerator(context);
  }

  FunderSelectionMenuOption({this.displayStringGenerator});
}

/// An item in the funder selection drop down list.
/// Holds either an account (representing the funder) or a selection option.
class FunderSelectionItem {
  Account account;
  FunderSelectionMenuOption option;

  FunderSelectionItem({
    Account funderAccount,
    FunderSelectionMenuOption option,
  }) {
    assert(funderAccount == null || option == null);
    this.account = funderAccount;
    this.option = option;
  }

  String title(BuildContext context) {
    if (account != null) {
      return account.funder.toString(prefix: true, elide: false);
    } else {
      return option.displayName(context);
    }
  }

  Widget icon() {
    if (account != null) {
      return SizedBox(width: 24, height: 24, child: account.chain.icon);
    } else {
      return null;
    }
  }

  bool operator ==(o) =>
      o is FunderSelectionItem && o.option == option && o.account == account;

  @override
  int get hashCode => super.hashCode;

  @override
  String toString() {
    return 'FunderSelectionItem{keyRef: $account, option: $option}';
  }
}
