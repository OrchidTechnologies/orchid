import 'dart:math';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/account/account_view_model.dart';
import 'package:orchid/util/listenable_builder.dart';
import 'account_card.dart';
import 'account_detail_store.dart';

/// Display one or more accounts with selection buttons.
class AccountSelector extends StatefulWidget {
  final List<Account> accounts;
  final Set<Account> selectedAccounts;
  final void Function(Set<Account> selected) selectedAccountsChanged;
  final bool singleSelection;

  const AccountSelector({
    Key? key,
    required this.accounts,
    required this.selectedAccounts,
    required this.selectedAccountsChanged,
    this.singleSelection = false,
  }) : super(key: key);

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  late AccountDetailStore _accountDetailStore;

  @override
  void initState() {
    _accountDetailStore =
        AccountDetailStore(onAccountDetailChanged: _accountDetailChanged);
    super.initState();
  }

  void _accountDetailChanged() {
    setState(() {}); // Trigger a UI refresh
  }

  @override
  void dispose() {
    _accountDetailStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAccountList().pady(32);
  }

  Widget _buildAccountList() {
    List<AccountViewModel> accounts = widget.accounts.map((Account account) {
      log("XXX: build view model for account: $account");
      return AccountViewModel(
          chain: Chains.chainFor(account.chainId),
          signerKey: account.signerKey,
          funder: account.funder,
          active: widget.selectedAccounts.contains(account),
          detail: _accountDetailStore.get(account));
    }).toList();

    // final footer = () {
    //   return OrchidActionButton(
    //     text: s.import.toUpperCase(),
    //     onPressed: () {},
    //     enabled: true,
    //   ).top(24);
    // };

    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            Container(height: 24),
        key: PageStorageKey('account list view'),
        primary: true,
        // itemCount: accounts.length + 1,
        itemCount: accounts.length,
        itemBuilder: (BuildContext context, int index) {
          // if (index == accounts.length) {
          //   return footer();
          // }
          var account = accounts[index];
          return Container(
            key: Key(account.toString()),
            alignment: Alignment.center,
            child: _buildAccountCard(account, index),
          );
        });
  }

  Widget _buildAccountCard(AccountViewModel accountModel, int index) {
    bool single = widget.accounts.length == 1;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: AccountCard(
        key: Key(accountModel.toString()),
        accountDetail: accountModel.detail,
        selected: single ? null : accountModel.active,
        onSelected: () {
          _toggleSelected(accountModel);
        },
        allowExpand: false,
      ).padx(8),
    );
  }

  void _toggleSelected(AccountViewModel accountModel) {
    final account = accountModel.detail.account;
    if (widget.singleSelection) {
      widget.selectedAccountsChanged(Set<Account>.from([account]));
    } else {
      var newSet = Set<Account>.from(widget.selectedAccounts);
      if (newSet.contains(account)) {
        newSet.remove(account);
      } else {
        newSet.add(account);
      }
      widget.selectedAccountsChanged(newSet);
    }
  }
}

/// An account selector that is sized automatically for use in a full-screen dialog
/// and offers a show() method that manages a set of selected accounts for the
/// confirmation dialog.
class AccountSelectorDialog extends StatelessWidget {
  final List<Account> accounts;
  final Set<Account> selectedAccounts;
  final void Function(Set<Account> selected) selectedAccountsChanged;

  /// Allow only a single card to be selected at a time
  final bool singleSelection;

  const AccountSelectorDialog({
    Key? key,
    required this.accounts,
    required this.selectedAccounts,
    required this.selectedAccountsChanged,
    this.singleSelection = false,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required List<Account> accounts,
    required void Function(Set<Account> selected) onSelectedAccounts,
    bool singleSelection = false,
  }) {
    log("XXX: account selector show..");
    Set<Account> _selectedAccounts;
    if (singleSelection) {
      _selectedAccounts = accounts.isNotEmpty ? Set.from([accounts.first]) : {};
    } else {
      _selectedAccounts = Set.from(accounts);
    }

    // Workaround to dynamically update the title.
    var titleChanged = ChangeNotifier();
    return AppDialogs.showConfirmationDialog(
      context: context,
      contentPadding: EdgeInsets.zero,
      titleWidget: ListenableBuilderUtil(
          listenable: titleChanged,
          builder: (context, snapshot) {
            var num = _selectedAccounts.length;
            var single = num == 1;
            return Text(
              single ? context.s.importAccount : "Import $num Accounts",
            ).subtitle.white;
          }),
      commitAction: () {
        log("XXX: commit action");
        if (_selectedAccounts.isNotEmpty) {
          onSelectedAccounts(_selectedAccounts);
        }
      },
      cancelAction: () {
        log("XXX: cancel action");
      },
      dark: true,
      body: StatefulBuilder(
        builder: (context, setState) {
          log("XXX: build dialog");
          return AccountSelectorDialog(
            accounts: accounts,
            selectedAccounts: _selectedAccounts,
            selectedAccountsChanged: (Set<Account> selected) {
              setState(() {
                _selectedAccounts = selected;
                titleChanged.notifyListeners();
              });
            },
            singleSelection: singleSelection,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSize(context).size;
    final cardHeight = 152.0;
    final spacing = 24.0;
    final ypad = 32.0;
    final intrinsicHeight = accounts.length * cardHeight +
        (accounts.length - 1) * spacing +
        2 * ypad;
    final height = min(size.height * 0.7, intrinsicHeight);

    return SizedBox(
      height: height,
      width: 400,
      child: AccountSelector(
        accounts: accounts,
        selectedAccounts: selectedAccounts,
        selectedAccountsChanged: selectedAccountsChanged,
        singleSelection: singleSelection,
      ),
    );
  }
}
