import 'dart:async';

import 'package:badges/badges.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_pricing.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/circuit/scan_paste_account.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/instructions_view.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/util/units.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_colors.dart';
import '../app_sizes.dart';
import '../app_text.dart';
import 'budget_page.dart';
import 'curator_page.dart';
import 'hop_editor.dart';
import 'key_selection.dart';
import 'model/circuit_hop.dart';
import 'model/orchid_hop.dart';
import 'package:intl/intl.dart';

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
  var _funderField = TextEditingController();
  var _curatorField = TextEditingController();
  var _importKeyField = TextEditingController();
  KeySelectionItem _initialSelectedItem;
  KeySelectionItem _selectedKeyItem;
  bool _showBalance = false;
  LotteryPot _lotteryPot; // initially null
  DateTime _lotteryPotLastUpdate;
  Timer _balanceTimer;
  bool _balancePollInProgress = false;
  bool _showMarketStatsAlert = false;

  @override
  void initState() {
    super.initState();
    // Disable rotation until we update the screen design
    ScreenOrientation.portrait();
    initStateAsync();
  }

  void initStateAsync() async {
    // If the hop is empty initialize it to defaults now.
    if (_hop() == null) {
      widget.editableHop.update(OrchidHop.from(_hop(),
          curator: await UserPreferences().getDefaultCurator() ??
              OrchidHop.appDefaultCurator));
    }

    // Init the UI from the supplied hop
    setState(() {
      OrchidHop hop = _hop();
      _funderField.text = hop?.funder?.toString();
      _curatorField.text = hop?.curator;
      _initialSelectedItem = hop?.keyRef != null
          ? KeySelectionItem(keyRef: hop.keyRef)
          : KeySelectionItem(option: KeySelectionDropdown.generateKeyOption);
      _selectedKeyItem = _initialSelectedItem;
    });

    if (widget.editable()) {
      _funderField.addListener(_textFieldChanged);
      _importKeyField.addListener(_textFieldChanged);
    }

    // init balance polling
    if (widget.readOnly() && await UserPreferences().getQueryBalances()) {
      setState(() {
        _showBalance = true;
      });
      _balanceTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _pollBalance();
      });
      _pollBalance(); // kick one off immediately
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
      default:
        throw Error();
    }
  }

  Widget _buildCreateModeContent() {
    var bodyStyle = TextStyle(fontSize: 16, color: Color(0xff504960));
    var richText = TextSpan(
      children: <TextSpan>[
        TextSpan(text: s.createInstruction1 + ' ', style: bodyStyle),

        // Use 'package:flutter_html/rich_text_parser.dart' now or our own?
        LinkTextSpan(
          text: 'account.orchid.com',
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://account.orchid.com/',
        ),

        TextSpan(
          text: "  " + s.createInstructions2 + "  ",
          style: bodyStyle,
        ),

        LinkTextSpan(
          text: s.learnMoreButtonTitle,
          style: AppText.linkStyle.copyWith(fontSize: 15),
          url: 'https://orchid.com/join',
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: <Widget>[
          pady(36),
          InstructionsView(
            image: Image.asset('assets/images/group12.png'),
            title: s.orchidRequiresOXT,
          ),
          RichText(text: richText),
          pady(24),
          divider(),
          pady(24),
          _buildFunding(),
          pady(96),
        ],
      ),
    );
  }

  Widget _buildViewOrEditModeContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24, right: 16),
      child: Column(
        children: <Widget>[
          if (AppSize(context).tallerThan(AppSize.iphone_xs_max)) pady(64),
          _buildSection(
              title: s.credentials, child: _buildFunding(), onDetail: null),
          pady(16),
          divider(),
          pady(24),
          _buildSection(
              title: s.curation,
              child: _buildCuration(),
              onDetail: !widget.disabled ? _editCurator : null),
          pady(36),
          /*
          divider(),
          pady(24),
          _buildSection(
              title: s.rateLimit, child: _buildBudget(), onDetail: _editBudget),
           */
        ],
      ),
    );
  }

  Widget _buildSection({String title, Widget child, VoidCallback onDetail}) {
    return Column(
      children: <Widget>[
        Text(title,
            style: AppText.dialogTitle
                .copyWith(color: Colors.black, fontSize: 22)),
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
                      child: Icon(Icons.chevron_right), onPressed: onDetail),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Balance and Deposit
        Visibility(
          visible: _showBalance,
          child: _buildBalance(),
        ),

        pady(16),
        // Wallet address (funder)
        _buildWalletAddress(),

        // Signer key
        pady(widget.readOnly() ? 0 : 24),
        _buildSignerKey(),

        // Market Stats
        if (widget.mode == HopEditorMode.View) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: _buildMarketStatsLink(),
          ),
        ],

        if (widget.readOnly())
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildExportAccountButton(),
              ],
            ),
          ),
      ],
    );
  }

  // Build the signer key entry dropdown selector
  Column _buildSignerKey() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.signerKey + ':',
            style: AppText.textLabelStyle.copyWith(
                fontSize: 16,
                color: _keyRefValid()
                    ? AppColors.neutral_1
                    : AppColors.neutral_3)),
        pady(8),
        Row(
          children: <Widget>[
            Expanded(
              child: KeySelectionDropdown(
                  key: ValueKey(_initialSelectedItem.toString()),
                  enabled: widget.editable(),
                  initialSelection: _initialSelectedItem,
                  onSelection: _onKeySelected),
            ),
            // Copy key button
            Visibility(
              visible: widget.readOnly(),
              child: RoundedRectButton(
                  backgroundColor: Colors.deepPurple,
                  textColor: Colors.white,
                  text: s.copy,
                  onPressed: _onCopyButton),
            ),
          ],
        ),

        // Show the import key field if the user has selected the option
        Visibility(
          visible: widget.editable() &&
              _selectedKeyItem?.option == KeySelectionDropdown.importKeyOption,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildImportKey(),
          ),
        )
      ],
    );
  }

  // Build the import key field
  Widget _buildImportKey() {
    return AppTextField(
        hintText: '0x...',
        margin: EdgeInsets.zero,
        controller: _importKeyField,
        trailing: FlatButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            child: Text(s.paste, style: AppText.pasteButtonStyle),
            onPressed: _pasteImportedKey));
  }

  Column _buildWalletAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.ethereumAddress + ':',
            style: AppText.textLabelStyle.copyWith(
                fontSize: 16,
                color: _funderValid()
                    ? AppColors.neutral_1
                    : AppColors.neutral_3)),
        pady(widget.readOnly() ? 4 : 8),
        AppTextField(
            hintText: '0x...',
            margin: EdgeInsets.zero,
            controller: _funderField,
            readOnly: widget.readOnly(),
            enabled: widget.editable(),
            trailing: widget.editable()
                ? FlatButton(
                    color: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Text(s.paste, style: AppText.pasteButtonStyle),
                    onPressed: _pasteWalletAddress)
                : null)
      ],
    );
  }

  void _pasteWalletAddress() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    _funderField.text = data.text;
  }

  void _pasteImportedKey() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    _importKeyField.text = data.text;
  }

  Column _buildBalance() {
    const color = Color(0xff3a3149);
    const valueStyle = TextStyle(
        color: color,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.24,
        fontFamily: 'SFProText-Regular',
        height: 20.0 / 15.0);

    var balanceText = _lotteryPot?.balance != null
        ? NumberFormat('#0.0###').format(_lotteryPot?.balance?.value) +
            " ${s.oxt}"
        : "...";
    var depositText = _lotteryPot?.deposit != null
        ? NumberFormat('#0.0###').format(_lotteryPot?.deposit?.value) +
            " ${s.oxt}"
        : '...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Balance
        Text(s.amount + ':',
            style: AppText.textLabelStyle
                .copyWith(fontSize: 20, color: AppColors.neutral_1)),
        pady(4),
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: 8, left: 16),
          child:
              Text(balanceText, textAlign: TextAlign.left, style: valueStyle),
        ),
        pady(16),
        // Deposit
        Text(s.deposit + ':',
            style: AppText.textLabelStyle
                .copyWith(fontSize: 20, color: AppColors.neutral_1)),
        pady(4),
        Padding(
          padding: EdgeInsets.only(top: 10, bottom: 8, left: 16),
          child:
              Text(depositText, textAlign: TextAlign.left, style: valueStyle),
        ),
      ],
    );
  }

  Widget _buildCuration() {
    return Row(
      children: <Widget>[
        Expanded(
            child: AppTextField(
          controller: _curatorField,
          padding: EdgeInsets.zero,
          readOnly: true,
          enabled: false,
        ))
      ],
    );
  }

  Widget _buildBudget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        pady(16),
        Text(s.viewOrModifyRateLimit,
            textAlign: TextAlign.left, style: AppText.dialogBody),
      ],
    );
  }

  Widget _buildMarketStatsLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _showMarketStats,
        child: Row(
          children: [
            LinkText(
              s.marketStats,
              style: AppText.linkStyle.copyWith(fontSize: 13),
              onTapped: _showMarketStats,
            ),
            padx(8),
            Badge(
              showBadge: _showMarketStatsAlert,
              position: BadgePosition.topEnd(top: -6, end: -28),
              badgeContent: Text('!',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              padding: EdgeInsets.all(8),
              toAnimate: false,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showMarketStats() async {
    // data
    Pricing pricing = await OrchidPricingAPI().getPricing();
    GWEI gasPrice = await OrchidEthereum().getGasPrice();
    if (_lotteryPot == null || pricing == null || gasPrice == null) {
      return;
    }

    // calculation
    ETH gasCostToRedeem =
        (gasPrice * OrchidPricingAPI.gasCostToRedeemTicket).toEth();
    OXT oxtCostToRedeem = pricing.ethToOxt(gasCostToRedeem);
    OXT maxFaceValue = OXT.min(_lotteryPot.balance, _lotteryPot.deposit / 2.0);
    bool gasPriceHigh = gasPrice.value >= 15.0;
    bool balanceLimited =
        _lotteryPot.balance.value < _lotteryPot.deposit.value / 2.0;

    // formatting
    var ethPriceText =
        formatCurrency(1.0 / pricing?.ethToUsdRate, suffix: 'USD');
    var oxtPriceText =
        formatCurrency(1.0 / pricing?.oxtToUsdRate, suffix: 'USD');
    var gasPriceText = formatCurrency(gasPrice.value, suffix: 'GWEI');
    String maxFaceValueText =
        formatCurrency(maxFaceValue?.value, suffix: 'OXT');
    String costToRedeemText =
        formatCurrency(oxtCostToRedeem.value, suffix: 'OXT');
    bool ticketUnderwater = oxtCostToRedeem.value >= maxFaceValue.value;

    String limitedByText = balanceLimited
        ? s.yourMaxTicketValueIsCurrentlyLimitedByYourBalance +
            " ${formatCurrency(_lotteryPot.balance.value, suffix: 'OXT')}.  " +
            s.considerAddingOxtToYourAccountBalance
        : s.yourMaxTicketValueIsCurrentlyLimitedByYourDeposit +
            " ${formatCurrency(_lotteryPot.deposit.value, suffix: 'OXT')}.  " +
            s.considerAddingOxtToYourDepositOrMovingFundsFrom;

    String limitedByTitleText =
        balanceLimited ? s.balanceTooLow : s.depositSizeTooSmall;

    return Dialogs.showAppDialog(
        context: context,
        title: s.marketStats,
        body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.prices, style: TextStyle(fontWeight: FontWeight.bold)),
              pady(4),
              Text(s.ethPrice + " " + ethPriceText),
              Text(s.oxtPrice + " " + oxtPriceText),
              Text(s.gasPrice + " " + gasPriceText,
                  style: gasPriceHigh ? TextStyle(color: Colors.red) : null),

              pady(16),
              Text(s.ticketValue,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              pady(4),

              Text(s.maxFaceValue + " " + maxFaceValueText),

              Text(s.costToRedeem + " " + costToRedeemText,
                  style:
                      ticketUnderwater ? TextStyle(color: Colors.red) : null),

              // Problem description
              if (ticketUnderwater) ...[
                pady(16),
                Text(limitedByTitleText,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                pady(8),
                Text(limitedByText,
                    style: TextStyle(fontStyle: FontStyle.italic)),
                pady(16),
                LinkText(s.viewTheDocsForHelpOnThisIssue,
                    style: AppText.linkStyle.copyWith(fontSize: 15),
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
    _curatorField.text = _hop()?.curator;
  }

  void _editBudget() {
    var route = MaterialPageRoute(
        builder: (context) =>
            BudgetEditorPage(editableHop: widget.editableHop));
    Navigator.push(context, route);
  }

  void _onKeySelected(KeySelectionItem key) {
    setState(() {
      _selectedKeyItem = key;
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
    // generate option handled upon save
    if (_selectedKeyItem.option == KeySelectionDropdown.generateKeyOption) {
      return true;
    }
    // import option
    if (_selectedKeyItem.option == KeySelectionDropdown.importKeyOption) {
      return _importKeyValid();
    }
    return false;
  }

  bool _funderValid() {
    try {
      EthereumAddress.parse(_funderField.text);
      return true;
    } catch (err) {
      return false;
    }
  }

  bool _importKeyValid() {
    try {
      Crypto.parseEthereumPrivateKey(_importKeyField.text);
      return true;
    } catch (err) {
      return false;
    }
  }

  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    EthereumAddress funder;
    try {
      funder = EthereumAddress.from(_funderField.text);
    } catch (err) {
      funder = null; // don't update it
    }
    // The selected key ref may be null here in the case of the generate
    // or import options.  In those cases the key will be filled in upon save.
    widget.editableHop.update(OrchidHop.from(widget.editableHop.value?.hop,
        funder: funder, keyRef: _selectedKeyItem?.keyRef));
  }

  /// Copy the wallet address to the clipboard
  void _onCopyButton() async {
    StoredEthereumKey key = await _selectedKeyItem.keyRef.get();
    Clipboard.setData(ClipboardData(text: key.keys().address));
  }

  // Participate in the save operation and then delegate to the on complete handler.
  void _onSave(CircuitHop result) async {
    if (_selectedKeyItem.option == KeySelectionDropdown.importKeyOption) {
      await _importKey();
    }
    if (_selectedKeyItem.option == KeySelectionDropdown.generateKeyOption) {
      await _generateKey();
    }
    // Pass on the updated hop
    widget.onAddFlowComplete(widget.editableHop.value.hop);
  }

  /// Import the user pasted key and apply it to the hop.
  /// Called on save when the import key option is selected.
  Future<bool> _importKey() async {
    var secret = Crypto.parseEthereumPrivateKey(_importKeyField.text);
    return _saveAndApplyNewKey(secret: secret, imported: true);
  }

  /// Generate a new key and apply it to the hop.
  /// Called on save when the generate new key option is selected.
  Future<bool> _generateKey() async {
    // Generate a new key
    var keyPair = Crypto.generateKeyPair();
    return _saveAndApplyNewKey(secret: keyPair.private, imported: false);
  }

  /// Save a newly generated or imported key secret and apply it to the hop
  /// Note: the hop itself is actually returned to and saved by the caller of the
  /// add hop flow (via the nav context).  It would be better if any new key and
  /// hop were saved together at one point in the code.
  Future<bool> _saveAndApplyNewKey({BigInt secret, bool imported}) async {
    var key = StoredEthereumKey(
        time: DateTime.now(), imported: false, private: secret);
    await UserPreferences().addKey(key);

    // Update the hop
    _selectedKeyItem = KeySelectionItem(keyRef: key.ref());
    _updateHop();

    return true;
  }

  OrchidHop _hop() {
    return widget.editableHop.value?.hop;
  }

  Widget divider() {
    return Divider(
      color: Colors.black.withOpacity(0.5),
      height: 1.0,
    );
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _funderField.removeListener(_textFieldChanged);
    _balanceTimer?.cancel();
  }

  void _pollBalance() async {
    if (_balancePollInProgress) {
      return;
    }
    _balancePollInProgress = true;
    try {
      // funder and signer from the stored hop
      EthereumAddress funder = _hop()?.funder;
      StoredEthereumKey signerKey = await _hop()?.keyRef?.get();
      EthereumAddress signer = EthereumAddress.from(signerKey.keys().address);
      // Fetch the pot balance
      LotteryPot pot;
      try {
        pot = await OrchidEthereum.getLotteryPot(funder, signer)
            .timeout(Duration(seconds: 60));
      } catch (err) {
        log('Error fetching lottery pot: $err');
        return;
      }
      var ticketValue = await OrchidPricingAPI().getMaxTicketValue(pot);
      if (mounted) {
        setState(() {
          _lotteryPot = pot;
          _showMarketStatsAlert = ticketValue.value <= 0;
        });
      }
      _lotteryPotLastUpdate = DateTime.now();
    } catch (err) {
      log("Can't fetch balance: $err");

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

  Widget _buildExportAccountButton() {
    return TitleIconButton(
        text: s.shareOrchidAccount,
        spacing: 24,
        trailing: Image.asset('assets/images/scan.png', color: Colors.white),
        textColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        onPressed: _exportAccount);
  }

  void _exportAccount() async {
    var config = await _hop().accountConfigString();
    Dialogs.showAppDialog(
        context: context,
        title: s.myOrchidAccount + ':',
        body: Container(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: QrImage(
                  data: config,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              _buildCopyButton(config)
            ],
          ),
        ));
  }

  Widget _buildCopyButton(String config) {
    return RoundedRectButton(
        backgroundColor: Colors.deepPurple,
        textColor: Colors.white,
        text: s.copy,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: config));
        });
  }

  S get s {
    return S.of(context);
  }
}
