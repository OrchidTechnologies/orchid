import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badge;
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/orchid/account_chart.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/instructions_view.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/account/account_selector.dart';
import 'package:orchid/orchid/account/market_stats_dialog.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/util/format_currency.dart';
import 'package:styled_text/styled_text.dart';
import '../../common/app_sizes.dart';
import '../../common/app_text.dart';
import 'curator_page.dart';
import '../../orchid/menu/orchid_funder_selector_menu.dart';
import 'hop_editor.dart';
import 'package:orchid/orchid/menu/orchid_key_selector_menu.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';

/// Create / edit / view an Orchid Hop
// The OrchidHopEditor operates in a "settings"-like fashion and allows
// editing certain elements of the hop (e.g. curator) even when in "View" mode.
class OrchidHopPage extends HopEditor<OrchidHop> {
  OrchidHopPage(
      {required editableHop, mode = HopEditorMode.View, onAddFlowComplete})
      : super(
            editableHop: editableHop,
            mode: mode,
            onAddFlowComplete: onAddFlowComplete);

  @override
  _OrchidHopPageState createState() => _OrchidHopPageState();
}

class _OrchidHopPageState extends State<OrchidHopPage> {
  Account? _selectedAccount;
  var _curatorField = TextEditingController();

  bool _showBalance = false;
  LotteryPot? _lotteryPot; // initially null
  MarketConditions? _marketConditions;
  List<OrchidUpdateTransactionV0>? _transactions;
  DateTime? _lotteryPotLastUpdate;
  Timer? _balanceTimer;
  bool _balancePollInProgress = false;
  bool _showMarketStatsAlert = false;
  late StreamSubscription<Set<Account>> _accountListener;

  @override
  void initState() {
    super.initState();
    // Disable rotation until we update the screen design
    ScreenOrientation.portrait();
    initStateAsync();
  }

  void initStateAsync() async {
    // If the hop is empty initialize it to defaults now.
    if (_hop == null) {
      widget.editableHop.update(OrchidHop.from(_hop,
          curator: UserPreferencesVPN().getDefaultCurator() ??
              OrchidHop.appDefaultCurator));
    }

    // init balance and account details polling
    if (widget.readOnly() && UserPreferencesVPN().getQueryBalances()) {
      setState(() {
        _showBalance = true;
      });
      _balanceTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _pollBalanceAndAccountDetails();
      });
      _pollBalanceAndAccountDetails(); // kick one off immediately
    }

    _accountListener = UserPreferencesVPN()
        .cachedDiscoveredAccounts
        .stream()
        .listen((accounts) {
      // guard changes in accounts availability
      if (!accounts.contains(_selectedAccount)) {
        setState(() {
          _selectedAccount = null;
        });
      }
      // default a single account selection
      if (_selectedAccount == null && accounts.length == 1) {
        setState(() {
          _selectedAccount = accounts.first;
        });
      }
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  // Migrating to OrchidAccountEntry
  KeySelectionItem? get _initialSelectedKeyItem {
    return _hop?.keyRef != null ? KeySelectionItem(keyRef: _hop!.keyRef) : null;
  }

  // Migrating to OrchidAccountEntry
  KeySelectionItem? get _selectedKeyItem {
    return _initialSelectedKeyItem;
  }

  // Migrating to OrchidAccountEntry
  FunderSelectionItem? get _initialSelectedFunderItem {
    return _hop?.funder != null
        ? FunderSelectionItem(funderAccount: _hop!.account)
        : null;
  }

  // Migrating to OrchidAccountEntry
  FunderSelectionItem? get _selectedFunderItem {
    return _initialSelectedFunderItem;
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        title: s.orchidHop,
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context, _onSave, isValid: _formValid())]
            : [],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: _buildContent()),
            ),
          ),
        ),
        // decoration: BoxDecoration(),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case HopEditorMode.Create:
        return _buildCreateModeContent();
      case HopEditorMode.Edit:
      case HopEditorMode.View:
        return _buildViewOrEditModeContent();
    }
  }

  Widget _buildCreateModeContent() {
    var text = StyledText(
      style: OrchidText.body2,
      newLineAsBreaks: true,
      text: s.chooseAnOrchidAccountToUseWithThisHop +
          '  ' +
          s.ifYouDontSeeYourAccountBelowYouCanUse,
      tags: {
        // 'link': linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: <Widget>[
          pady(8),
          InstructionsView(
            title: s.selectAnOrchidAccount,
            titleColor: Colors.white,
          ),
          text,
          pady(16),
          _buildAccountManagerLinkText(),
          StreamBuilder<Set<Account>>(
              stream: UserPreferencesVPN().cachedDiscoveredAccounts.stream(),
              builder: (context, snapshot) {
                final accounts = snapshot.data;
                if ((accounts ?? {}).isEmpty) {
                  return Container();
                }
                return AccountSelectorDialog(
                  accounts: accounts!.toList(),
                  singleSelection: true,
                  selectedAccounts: _selectedAccount != null
                      ? Set.from([_selectedAccount])
                      : {},
                  selectedAccountsChanged: (Set<Account> selected) {
                    setState(() {
                      _selectedAccount = selected.first;
                    });
                  },
                );
              }),
          pady(24),
        ],
      ),
    );
  }

  LinkText _buildAccountManagerLinkText() {
    return LinkText(
      s.takeMeToTheAccountManager,
      style: OrchidText.body1.linkStyle,
      onTapped: () {
        Navigator.of(context).push(
            new MaterialPageRoute(builder: (context) => AccountManagerPage()));
      },
    );
  }

  Widget _buildViewOrEditModeContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 8, bottom: 24, right: 16),
      child: Column(
        children: <Widget>[
          if (AppSize(context).tallerThan(AppSize.iphone_12_pro_max)) pady(64),
          _buildSection(
              title: s.account, child: _buildAccountDetails(), onDetail: null),
          pady(16),
          _divider(),
          pady(24),
          _buildSection(
              title: s.curation,
              child: _buildCuration(),
              onDetail: _editCurator),
          pady(36),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required Widget child, VoidCallback? onDetail}) {
    return Column(
      children: <Widget>[
        Text(title, style: OrchidText.title),
        pady(8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: child),
              Visibility(
                visible: onDetail != null,
                child: Container(
                  //width: 60,
                  //color: Colors.red,
                  child: FlatButtonDeprecated(
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: onDetail),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    bool v0 = _account?.isV0 ?? false;
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Balance and Deposit
              Visibility(
                visible: _showBalance,
                child: _buildAccountBalanceAndChart(),
              ),

              // Signer
              if (widget.readOnly()) pady(16),
              _buildSelectSignerField(),

              pady(16),

              // Funder
              if (_selectedKeyItem != null) _buildSelectFunderField(),

              // Market Stats
              if (widget.mode == HopEditorMode.View)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Center(
                      child: SizedBox(
                    width: 310,
                    child: _buildMarketStatsButton(),
                  )),
                ),

              // Share button
              if (widget.readOnly())
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Center(
                      child: SizedBox(
                    width: 310,
                    child: _buildShowAccountButton(),
                  )),
                ),

              // Transactions list
              // TODO: This only works for V0
              if (v0 && widget.readOnly() && _transactions != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _divider(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTransactionListV0(),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionListV0() {
    const String bullet = "• ";
    // null guarded by page logic
    var txRows = _transactions!.map((utx) {
      return Row(
        children: [
          Text(bullet, style: TextStyle(fontSize: 20)),
          Container(
              width: 40,
              child: Text(utx.tx.type.toString().split('.')[1] + ':')),
          padx(16),
          Container(
            width: 150,
            child: Text(s.balance +
                ': ' +
                formatCurrency(utx.update.endBalance.floatValue,
                    locale: context.locale, suffix: 'OXT')),
          ),
          padx(8),
          Flexible(child: Text(utx.tx.transactionHash.substring(0, 8) + '...'))
        ],
      );
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.transactions, style: AppText.textLabelStyle),
      pady(8),
      ...txRows,
    ]);
  }

  // Build the signer key entry dropdown selector
  Widget _buildSelectSignerField() {
    final _keyRefValid = _formValid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.orchidIdentity + ':',
          style: OrchidText.title.copyWith(
              color: _keyRefValid ? OrchidColors.valid : OrchidColors.invalid),
        ),
        pady(8),
        Row(
          children: <Widget>[
            Expanded(
              child: OrchidKeySelectorMenu(
                  key: ValueKey(_initialSelectedKeyItem.toString()),
                  enabled: widget.editable(),
                  selected: _initialSelectedKeyItem,
                  onSelection: (_) {}),
            ),
            // Copy key button
            Visibility(
              visible: widget.readOnly(),
              child: RoundedRectButton(
                  textColor: Colors.black,
                  text: s.copy.toUpperCase(),
                  onPressed: _onCopyButton),
            ).left(12),
          ],
        ),
      ],
    );
  }

  /// Select a funder account address for the selected signer identity
  Column _buildSelectFunderField() {
    final _funderValid = _formValid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.funderAccount + ':',
            style: OrchidText.title.copyWith(
                color:
                    _funderValid ? OrchidColors.valid : OrchidColors.invalid)),
        pady(widget.readOnly() ? 4 : 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OrchidFunderSelectorMenu(
                  signer: _selectedKeyItem?.keyRef,
                  key: ValueKey(_selectedKeyItem?.toString() ??
                      _initialSelectedKeyItem.toString()),
                  enabled: widget.editable(),
                  selected: _selectedFunderItem ?? _initialSelectedFunderItem,
                  onSelection: (_) {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountBalanceAndChart() {
    return Row(
      children: [
        Flexible(child: _buildAccountBalance()),
        Expanded(
          child: OrchidAccountChart(
            lotteryPot: _lotteryPot,
            efficiency: _marketConditions?.efficiency,
            transactions: _transactions,
          ),
        )
      ],
    );
  }

  Widget _buildAccountBalance() {
    var balanceText =
        _lotteryPot?.balance.formatCurrency(locale: context.locale) ?? '...';
    var depositText =
        _lotteryPot?.effectiveDeposit.formatCurrency(locale: context.locale) ??
            '...';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Balance
        Text(s.balance + ':').title,
        pady(4),
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: 8, left: 16),
          child: Text(balanceText, textAlign: TextAlign.left).subtitle,
        ),
        pady(16),
        // Deposit
        Text(s.deposit + ':').title,
        pady(4),
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: 8, left: 16),
          child: Text(depositText, textAlign: TextAlign.left).subtitle,
        ),
      ],
    );
  }

  Widget _buildCuration() {
    return Row(
      children: <Widget>[
        Expanded(
            child: OrchidTextField(
          controller: _curatorField,
          hintText: OrchidHop.appDefaultCurator,
          readOnly: true,
          enabled: false,
        ))
      ],
    );
  }

  Widget _buildMarketStatsButton() {
    return badge.Badge(
      showBadge: _showMarketStatsAlert,
      position: badge.BadgePosition.topEnd(top: 9, end: 55),
      badgeContent:
          Text('!', style: TextStyle(color: Colors.white, fontSize: 12)),
      badgeStyle: badge.BadgeStyle(
        padding: EdgeInsets.all(8),
      ),
      // toAnimate: false,
      child: SizedBox(
        // fill the stack that Badge creates
        width: double.infinity,
        child: RoundedRectButton(
          textColor: Colors.black,
          text: s.marketStats.toUpperCase(),
          onPressed: _showMarketStats,
        ),
      ),
    );
  }

  Future<void> _showMarketStats() async {
    if (_account == null) {
      return;
    }
    MarketStatsDialog.show(
      context: context,
      account: _account!,
      lotteryPot: _lotteryPot,
      marketConditions: _marketConditions,
    );
  }

  void _editCurator() async {
    var route = MaterialPageRoute(
        builder: (context) =>
            CuratorEditorPage(editableHop: widget.editableHop));
    await Navigator.push(context, route);
    _curatorField.text = _hop?.curator ?? '';
  }

  bool _formValid() {
    return _selectedAccount != null;
  }

  // Note: Called whenever setState() is invoked. We should probably make this explicit.
  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    if (_selectedAccount == null) {
      return;
    }

    // The selected key ref may be null here in the case of the generate
    // or import options.  In those cases the key will be filled in upon save.
    widget.editableHop.update(
      OrchidHop.from(
        widget.editableHop.value?.hop as OrchidHop,
        keyRef: _selectedAccount?.signerKeyRef,
        funder: _selectedAccount?.funder,
        chainId: _selectedAccount?.chainId,
        version: _selectedAccount?.version,
      ),
    );
  }

  /// Copy the wallet address to the clipboard
  void _onCopyButton() async {
    StoredEthereumKey? key = _selectedKeyItem?.keyRef?.get();
    if (key != null) {
      Clipboard.setData(ClipboardData(text: key.get().address.toString()));
    }
  }

  // Participate in the save operation and then delegate to the on complete handler.
  void _onSave(CircuitHop? result) async {
    if (_selectedAccount != null) {
      await UserPreferencesVPN().ensureSaved(_selectedAccount!);
    }
    // Pass on the updated hop
    if (widget.onAddFlowComplete != null) {
      widget.onAddFlowComplete!(widget.editableHop.value?.hop);
    }
  }

  OrchidHop? get _hop {
    return widget.editableHop.value?.hop as OrchidHop;
  }

  Account? get _account {
    return _hop?.account;
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withOpacity(0.5),
      height: 1.0,
    );
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _balanceTimer?.cancel();
    _accountListener.cancel();
  }

  // TODO: Use AccountDetailPoller?
  void _pollBalanceAndAccountDetails() async {
    if (_balancePollInProgress) {
      return;
    }
    _balancePollInProgress = true;
    try {
      Account? account = _hop?.account;
      if (account == null) {
        throw Exception("No account to poll");
      }

      // Fetch the pot balance
      LotteryPot pot;
      try {
        pot = await account.getLotteryPot().timeout(Duration(seconds: 60));
      } catch (err) {
        log('Error fetching lottery pot: $err');
        return;
      }
      if (mounted) {
        setState(() {
          _lotteryPot = pot;
        });
      }

      MarketConditions marketConditions;
      try {
        marketConditions = await account.getMarketConditionsFor(pot);
      } catch (err, stack) {
        log('Error fetching market conditions: $err\n$stack');
        return;
      }
      if (mounted) {
        setState(() {
          _marketConditions = marketConditions;
          _showMarketStatsAlert =
              MarketConditions.isBelowMinEfficiency(marketConditions);
        });
      }

      // TODO: transactions and ticket count only work for V0
      List<OrchidUpdateTransactionV0> transactions = [];
      if (_account?.isV0 ?? false) {
        try {
          transactions = await OrchidEthereumV0().getUpdateTransactions(
              funder: account.funder, signer: account.signerAddress);
        } catch (err) {
          log('Error fetching account update transactions: $err');
        }
      }
      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }

      _lotteryPotLastUpdate = DateTime.now();
    } catch (err, stack) {
      log("Can't fetch balance: $err, $stack");

      // Allow a stale balance for a period of time.
      if (_lotteryPotLastUpdate != null &&
          _lotteryPotLastUpdate!.difference(DateTime.now()) >
              Duration(hours: 1)) {
        if (mounted) {
          setState(() {
            _lotteryPot = null; // no balance available
          });
        }
      }
    } finally {
      _balancePollInProgress = false;
    }
  }

  Widget _buildShowAccountButton() {
    return RoundedRectButton(
        text: s.showInAccountManager.toUpperCase(),
        textColor: Colors.black,
        onPressed: () {
          if (_account != null) {
            AccountManagerPage.showAccount(context, _account!);
          }
        });
  }
}
