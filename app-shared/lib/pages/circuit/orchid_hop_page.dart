import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/cloudflare.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/keys/add_key_page.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'budget_page.dart';
import 'circuit_hop.dart';
import 'curator_page.dart';
import 'key_selection.dart';

/// Create / edit / view an Orchid Hop
class OrchidHopPage extends HopEditor<OrchidHop> {
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
  StoredEthereumKeyRef _initialKeyRef;
  StoredEthereumKeyRef _selectedKeyRef;
  bool _showBalance = false;
  OXT _balance; // initially null
  Timer _balanceTimer;

  @override
  void initState() {
    super.initState();
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
      _funderField.text = hop?.funder;
      _selectedKeyRef = hop?.keyRef;
      _curatorField.text = hop?.curator;
      _initialKeyRef = _selectedKeyRef;
    });
    _funderField.addListener(_textFieldChanged);

    // init balance polling
    if (await UserPreferences().getQueryBalances()) {
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
        title: "Orchid Hop",
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context, isValid: isValid)]
            : [],
        child: SafeArea(
          child: _buildContent(),
        ),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: <Widget>[
          _buildFunding(),
        ],
      ),
    );
  }

  Widget _buildViewOrEditModeContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24, right: 16),
      child: Column(
        children: <Widget>[
          _buildSection(
              title: "Funding", child: _buildFunding(), onDetail: null),
          pady(16),
          divider(),
          pady(24),
          _buildSection(
              title: "Curation",
              child: _buildCuration(),
              onDetail: _editCurator),
          pady(36),
          divider(),
          pady(24),
          _buildSection(
              title: "Budget", child: _buildBudget(), onDetail: _editBudget),
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
    const color = Color(0xff3a3149);
    const valueStyle = TextStyle(
        color: color,
        fontSize: 15.0,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.24,
        fontFamily: "SFProText-Regular",
        height: 20.0 / 15.0);
    var balanceText =
        _balance != null ? _balance.toStringAsFixed(4) + " OXT" : "...";
    return Column(
      children: <Widget>[
        // Balance (if enabled)
        Visibility(
          visible: _showBalance,
          child: Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                width: 80,
                child: Text("Balance:",
                    style: AppText.textLabelStyle.copyWith(
                        fontSize: 20,
                        color: _funderValid()
                            ? AppColors.neutral_1
                            : AppColors.neutral_3)),
              ),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(balanceText,
                    textAlign: TextAlign.right, style: valueStyle),
              ))
            ],
          ),
        ),

        // Wallet address (funder)
        Row(
          children: <Widget>[
            Container(
              width: 70,
              child: Text("Funder:",
                  style: AppText.textLabelStyle.copyWith(
                      fontSize: 20,
                      color: _funderValid()
                          ? AppColors.neutral_1
                          : AppColors.neutral_3)),
            ),
            Expanded(
                child: AppTextField(
              controller: _funderField,
              readOnly: widget.readOnly(),
              enabled: widget.editable(),
            ))
          ],
        ),

        // Signer
        pady(widget.readOnly() ? 0 : 8),
        Row(
          children: <Widget>[
            Container(
              width: 70,
              child: Text("Signer:",
                  style: AppText.textLabelStyle.copyWith(
                      fontSize: 20,
                      color: _keyRefValid()
                          ? AppColors.neutral_1
                          : AppColors.neutral_3)),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 16),
              child: KeySelection(
                  key: ValueKey(_initialKeyRef.toString()),
                  enabled: widget.editable(),
                  initialSelection: _initialKeyRef,
                  onSelection: _keySelected),
            )),

            // Copy key button
            Visibility(
              visible: widget.readOnly(),
              child: RoundedRectRaisedButton(
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  text: "Copy",
                  onPressed: _onCopyButton),
            ),

            // Add key button
            Visibility(
              visible: widget.editable(),
              child: _buidAddKeyButton(),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildCuration() {
    return Row(
      children: <Widget>[
        /*
        Container(
          width: 75,
          child: Text("Curator:",
              style: AppText.textLabelStyle
                  .copyWith(fontSize: 20, color: AppColors.neutral_1)),
        ),*/
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
        Text("View or modify your budget.",
            textAlign: TextAlign.left, style: AppText.dialogBody),
      ],
    );
  }

  Widget _buidAddKeyButton() {
    return Container(
      width: 30,
      child: FlatButton(
          padding: EdgeInsets.only(right: 5),
          child: Icon(Icons.add_circle_outline, color: Colors.grey),
          onPressed: _onAddKeyButton),
    );
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

  void _keySelected(StoredEthereumKey key) {
    setState(() {
      _selectedKeyRef = key.ref();
    });
  }

  void _textFieldChanged() {
    setState(() {}); // Update validation
  }

  bool _keyRefValid() {
    return _selectedKeyRef != null;
  }

  bool _funderValid() {
    try {
      EthereumAddress.parse(_funderField.text);
      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }

  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    widget.editableHop.update(OrchidHop.from(widget.editableHop.value?.hop,
        funder: Hex.removePrefix(_funderField.text), keyRef: _selectedKeyRef));
  }

  /// Copy the log data to the clipboard
  void _onCopyButton() async {
    StoredEthereumKey key = await _selectedKeyRef.get();
    Clipboard.setData(ClipboardData(text: key.keys().address));
  }

  void _onAddKeyButton() async {
    var route = MaterialPageRoute<StoredEthereumKey>(
        builder: (context) => AddKeyPage(), fullscreenDialog: true);
    StoredEthereumKey key = await Navigator.push(context, route);

    // User cancelled
    if (key == null) {
      return;
    }

    // Save the new key
    var keys = await UserPreferences().getKeys() ?? [];
    keys.add(key);
    await UserPreferences().setKeys(keys);

    // Select the new key in the list
    setState(() {
      _initialKeyRef = key.ref(); // rebuild the dropdown
      _selectedKeyRef = _initialKeyRef;
    });
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
    _funderField.removeListener(_textFieldChanged);
    _balanceTimer?.cancel();
  }

  void _pollBalance() async {
    print("polling balance");
    try {
      // funder and signer from the stored hop
      EthereumAddress funder = EthereumAddress.from(_hop()?.funder);
      StoredEthereumKey signerKey = await _hop()?.keyRef?.get();
      EthereumAddress signer = EthereumAddress.from(signerKey.keys().address);
      // Fetch the pot balance
      LotteryPot pot = await CloudFlare.getLotteryPot(funder, signer);
      setState(() {
        _balance = pot.balance;
      });
    } catch (err) {
      print("Can't fetch balance: $err");
      setState(() {
        _balance = null; // no balance available
      });
    }
  }
}
