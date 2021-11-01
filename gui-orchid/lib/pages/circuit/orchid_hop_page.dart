import 'dart:async';
import 'package:badges/badges.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/pricing/orchid_pricing_v0.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/account_chart.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/instructions_view.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/common/titled_page_base.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/pages/account_manager/account_finder.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/util/units.dart';
import 'package:styled_text/styled_text.dart';
import '../../common/app_sizes.dart';
import '../../common/app_text.dart';
import 'curator_page.dart';
import 'funder_selection.dart';
import 'hop_editor.dart';
import 'key_selection.dart';
import 'model/circuit_hop.dart';
import 'model/orchid_hop.dart';

/// Create / edit / view an Orchid Hop
class OrchidHopPage extends HopEditor<OrchidHop> {
  // The OrchidHopEditor operates in a "settings"-like fashion and allows
  // editing certain elements of the hop even when in "View" mode.  This flag
  // disables these features.
  bool disabled = false;

  OrchidHopPage(
      {@required editableHop, mode = HopEditorMode.View, onAddFlowComplete})
      : super(
            editableHop: editableHop,
            mode: mode,
            onAddFlowComplete: onAddFlowComplete);

  @override
  _OrchidHopPageState createState() => _OrchidHopPageState();
}

class _OrchidHopPageState extends State<OrchidHopPage> {
  var _pastedFunderField = TextEditingController();
  var _curatorField = TextEditingController();
  KeySelectionItem _initialSelectedKeyItem;
  KeySelectionItem _selectedKeyItem;
  FunderSelectionItem _initialSelectedFunderItem;
  FunderSelectionItem _selectedFunderItem;

  bool _showBalance = false;
  LotteryPot _lotteryPot; // initially null
  MarketConditions _marketConditions;
  List<OrchidUpdateTransactionV0> _transactions;
  DateTime _lotteryPotLastUpdate;
  Timer _balanceTimer;
  bool _balancePollInProgress = false;
  bool _showMarketStatsAlert = false;

  bool _updatingAccounts = false;

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
          curator: await UserPreferences().getDefaultCurator() ??
              OrchidHop.appDefaultCurator));
    }

    // Init the UI from the supplied hop
    setState(() {
      _curatorField.text = _hop?.curator;

      _initialSelectedKeyItem =
          _hop?.keyRef != null ? KeySelectionItem(keyRef: _hop.keyRef) : null;

      _initialSelectedFunderItem = _hop?.funder != null
          ? FunderSelectionItem(funderAccount: _hop.account)
          : null;

      _selectedKeyItem = _initialSelectedKeyItem;
    });

    if (widget.editable()) {
      _pastedFunderField.addListener(_textFieldChanged);
    }

    // init balance and account details polling
    if (widget.readOnly() && await UserPreferences().getQueryBalances()) {
      setState(() {
        _showBalance = true;
      });
      _balanceTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _pollBalanceAndAccountDetails();
      });
      _pollBalanceAndAccountDetails(); // kick one off immediately
    }

    if (widget.create) {
      setState(() {
        _updatingAccounts = true;
      });
      AccountFinder().find((accounts) async {
        setState(() {
          _updatingAccounts = false;
        });
      });
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  @override
  Widget build(BuildContext context) {
    var isValid = _funderValid() && _keyRefValid();
    return TapClearsFocus(
      child: TitledPage(
        title: s.orchidHop,
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context, _onSave, isValid: isValid)]
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
        decoration: BoxDecoration(),
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
    throw Exception();
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
          LinkText(
            s.takeMeToTheAccountManager,
            style: OrchidText.body1.linkStyle,
            onTapped: () {
              Navigator.of(context).push(new MaterialPageRoute(
                  builder: (context) => AccountManagerPage()));
            },
          ),
          pady(24),
          _buildAccountDetails(),
          pady(24),
          if (_updatingAccounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildUpdatingAccounts(),
            ),
          pady(24),
        ],
      ),
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
              onDetail: !widget.disabled ? _editCurator : null),
          pady(36),
        ],
      ),
    );
  }

  Widget _buildSection({String title, Widget child, VoidCallback onDetail}) {
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
                  child: FlatButton(
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
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // mainAxisSize: MainAxisSize.max,
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
    var txRows = _transactions.map((utx) {
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
                    suffix: 'OXT')),
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

  Widget _buildUpdatingAccounts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            width: 20,
            height: 20,
            child: OrchidCircularProgressIndicator(
              value: null, // indeterminate animation
            )),
        padx(16),
        Text(s.updatingAccounts,
            style: OrchidText.caption.copyWith(height: 1.7)),
      ],
    );
  }

  // Build the signer key entry dropdown selector
  Widget _buildSelectSignerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.orchidIdentity + ':',
          style: OrchidText.title.copyWith(
              color:
                  _keyRefValid() ? OrchidColors.valid : OrchidColors.invalid),
        ),
        pady(8),
        Row(
          children: <Widget>[
            Expanded(
              child: KeySelectionDropdown(
                  key: ValueKey(_initialSelectedKeyItem.toString()),
                  enabled: widget.editable(),
                  initialSelection: _initialSelectedKeyItem,
                  onSelection: _onKeySelected),
            ),
            // Copy key button
            Visibility(
              visible: widget.readOnly(),
              child: RoundedRectButton(
                  textColor: Colors.black,
                  text: s.copy.toUpperCase(),
                  onPressed: _onCopyButton),
            ),
          ],
        ),
      ],
    );
  }

  /// Select a funder account address for the selected signer identity
  Column _buildSelectFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.funderAccount + ':',
            style: OrchidText.title.copyWith(
                color: _funderValid()
                    ? OrchidColors.valid
                    : OrchidColors.invalid)),
        pady(widget.readOnly() ? 4 : 8),

        Row(
          children: <Widget>[
            Expanded(
              child: FunderSelectionDropdown(
                  signer: _selectedKeyItem?.keyRef,
                  key: ValueKey(_selectedKeyItem?.toString() ??
                      _initialSelectedKeyItem.toString()),
                  enabled: widget.editable(),
                  initialSelection:
                      _selectedFunderItem ?? _initialSelectedFunderItem,
                  onSelection: _onFunderSelected),
            ),
          ],
        ),

        // Show the paste funder field if the user has selected the option
        Visibility(
          visible: widget.editable() &&
              _selectedFunderItem?.option ==
                  FunderSelectionDropdown.pasteKeyOption,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildPasteFunderField(),
          ),
        )
      ],
    );
  }

  Column _buildPasteFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OrchidTextField(
            hintText: '0x...',
            margin: EdgeInsets.zero,
            controller: _pastedFunderField,
            readOnly: widget.readOnly(),
            enabled: widget.editable(),
            trailing: widget.editable()
                ? FlatButton(
                    color: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Text(s.paste, style: OrchidText.button.purpleBright),
                    onPressed: _onPasteFunderAddress)
                : null)
      ],
    );
  }

  void _onPasteFunderAddress() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    _pastedFunderField.text = data.text;
  }

  Widget _buildAccountBalanceAndChart() {
    return Row(
      children: [
        Flexible(child: _buildAccountBalance()),
        Expanded(
          child: AccountChart(
              lotteryPot: _lotteryPot,
              efficiency: _marketConditions?.efficiency,
              transactions: _transactions),
        )
      ],
    );
  }

  Widget _buildAccountBalance() {
    var balanceText = _lotteryPot?.balance?.formatCurrency() ?? '...';
    var depositText = _lotteryPot?.deposit?.formatCurrency() ?? '...';
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
          padding: EdgeInsets.zero,
          readOnly: true,
          enabled: false,
        ))
      ],
    );
  }

  Widget _buildMarketStatsButton() {
    return Badge(
      showBadge: _showMarketStatsAlert,
      position: BadgePosition.topEnd(top: 9, end: 55),
      badgeContent:
          Text('!', style: TextStyle(color: Colors.white, fontSize: 12)),
      padding: EdgeInsets.all(8),
      toAnimate: false,
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
    if (_lotteryPot == null || _marketConditions == null) {
      return;
    }

    var gasPrice = await _account.chain.getGasPrice();

    // We used to do this :)
    // bool gasPriceHigh = gasPrice.value >= 50.0;
    bool gasPriceHigh = false;

    List<Widget> tokenPrices;
    if (_account.isV0) {
      PricingV0 pricing = await OrchidPricingAPIV0().getPricing();
      var ethPriceText =
          formatCurrency(1.0 / pricing?.ethToUsdRate, suffix: 'USD');
      var oxtPriceText =
          formatCurrency(1.0 / pricing?.oxtToUsdRate, suffix: 'USD');
      tokenPrices = [
        Text(s.ethPrice + " " + ethPriceText).body2,
        Text(s.oxtPrice + " " + oxtPriceText).body2,
      ];
    } else {
      var tokenType = _account.chain.nativeCurrency;
      var tokenPrice = await OrchidPricing().tokenToUsdRate(tokenType);
      var priceText = formatCurrency(tokenPrice, suffix: 'USD');
      tokenPrices = [
        Text(tokenType.symbol + ' ' + "Price" + ': ' + priceText).body2,
      ];
    }

    // Show gas prices as "GWEI" regardless of token type.
    var gasPriceGwei = gasPrice.multiplyDouble(1e9);
    var gasPriceText = formatCurrency(gasPriceGwei.floatValue, suffix: 'GWEI');

    String maxFaceValueText = _marketConditions.maxFaceValue.formatCurrency();
    String costToRedeemText = _marketConditions.costToRedeem.formatCurrency();

    bool ticketUnderwater = _marketConditions.costToRedeem.floatValue >=
        _marketConditions.maxFaceValue.floatValue;

    String limitedByText = _marketConditions.limitedByBalance
        ? s.yourMaxTicketValueIsCurrentlyLimitedByYourBalance +
            " ${_lotteryPot.balance.formatCurrency()}.  " +
            s.considerAddingOxtToYourAccountBalance
        : s.yourMaxTicketValueIsCurrentlyLimitedByYourDeposit +
            " ${_lotteryPot.deposit.formatCurrency()}.  " +
            s.considerAddingOxtToYourDepositOrMovingFundsFrom;

    String limitedByTitleText = _marketConditions.limitedByBalance
        ? s.balanceTooLow
        : s.depositSizeTooSmall;

    return AppDialogs.showAppDialog(
        context: context,
        title: s.marketStats,
        body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.prices).title,
              pady(4),
              ...tokenPrices,
              Text(s.gasPrice + " " + gasPriceText,
                      style: gasPriceHigh
                          ? OrchidText.body1.copyWith(color: Colors.red)
                          : OrchidText.body1)
                  .body2,
              pady(16),
              Text(s.ticketValue).title,
              pady(4),

              Text(s.maxFaceValue + " " + maxFaceValueText).body2,

              Text(s.costToRedeem + " " + costToRedeemText,
                  style: ticketUnderwater
                      ? OrchidText.body2.copyWith(color: Colors.red)
                      : OrchidText.body2),

              // Problem description
              if (ticketUnderwater) ...[
                pady(16),
                Text(limitedByTitleText).body1,
                pady(8),

                // Text(limitedByText, style: TextStyle(fontStyle: FontStyle.italic)),
                Text(limitedByText,
                    style:
                        OrchidText.body1.copyWith(fontStyle: FontStyle.italic)),

                pady(16),
                LinkText(s.viewTheDocsForHelpOnThisIssue,
                    style: OrchidText.linkStyle,
                    url:
                        'https://docs.orchid.com/en/stable/accounts/#deposit-size-too-small')
              ]
            ]));
  }

  void _editCurator() async {
    var route = MaterialPageRoute(
        builder: (context) =>
            CuratorEditorPage(editableHop: widget.editableHop));
    await Navigator.push(context, route);
    _curatorField.text = _hop?.curator;
  }

  void _onKeySelected(KeySelectionItem key) {
    setState(() {
      _selectedKeyItem = key;
      _selectedFunderItem = null;
      _pastedFunderField.text = null;
    });
    // clear the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  void _onFunderSelected(FunderSelectionItem funder) {
    setState(() {
      _selectedFunderItem = funder;
    });
    // clear the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  void _textFieldChanged() {
    setState(() {}); // Update validation
  }

  bool _keyRefValid() {
    // invalid selection
    if (_selectedKeyItem == null) {
      return false;
    }
    // key value selected
    if (_selectedKeyItem.keyRef != null) {
      return true;
    }
    return false;
  }

  bool _funderValid() {
    return (_selectedFunderItem != null &&
            _selectedFunderItem.option !=
                FunderSelectionDropdown.pasteKeyOption) ||
        _pastedFunderValid() ||
        widget.readOnly();
  }

  bool _pastedFunderValid() {
    try {
      EthereumAddress.parse(_pastedFunderField.text);
      return true;
    } catch (err) {
      return false;
    }
  }

  // Note: Called whenever setState() is invoked. We should probably make this explicit.
  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    EthereumAddress funder;
    int chainId;
    int version;
    try {
      var account = _selectedFunderItem?.account;
      funder = account?.funder ?? EthereumAddress.from(_pastedFunderField.text);
      chainId = account?.chainId;
      version = account?.version;
    } catch (err) {
      funder = null; // don't update it
    }
    // The selected key ref may be null here in the case of the generate
    // or import options.  In those cases the key will be filled in upon save.
    widget.editableHop.update(
      OrchidHop.from(
        widget.editableHop.value?.hop,
        keyRef: _selectedKeyItem?.keyRef,
        funder: funder,
        chainId: chainId,
        version: version,
      ),
    );
  }

  /// Copy the wallet address to the clipboard
  void _onCopyButton() async {
    StoredEthereumKey key = await _selectedKeyItem.keyRef.get();
    Clipboard.setData(ClipboardData(text: key.get().addressString));
  }

  // Participate in the save operation and then delegate to the on complete handler.
  void _onSave(CircuitHop result) async {
    // Pass on the updated hop
    widget.onAddFlowComplete(widget.editableHop.value.hop);
  }

  OrchidHop get _hop {
    return widget.editableHop.value?.hop;
  }

  Account get _account {
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
    _pastedFunderField.removeListener(_textFieldChanged);
    _balanceTimer?.cancel();
  }

  // TODO: Use AccountDetailPoller?
  void _pollBalanceAndAccountDetails() async {
    if (_balancePollInProgress) {
      return;
    }
    _balancePollInProgress = true;
    try {
      Account account = _hop?.account;
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
              funder: account.funder, signer: await account.signerAddress);
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
          _lotteryPotLastUpdate.difference(DateTime.now()) >
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
            AccountManagerPage.showAccount(context, _account);
          }
        });
  }

  S get s {
    return S.of(context);
  }
}
