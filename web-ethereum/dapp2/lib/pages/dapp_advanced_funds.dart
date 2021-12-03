import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/on_off.dart';

import 'dapp_button.dart';
import 'orchid_form_fields.dart';

class AdvancedFundsPane extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;
  final VoidCallback onTransaction;

  const AdvancedFundsPane({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
    @required this.onTransaction,
  }) : super(key: key);

  @override
  _AdvancedFundsPaneState createState() => _AdvancedFundsPaneState();
}

class _AdvancedFundsPaneState extends State<AdvancedFundsPane> {
  final _addBalanceField = TokenValueFieldController();
  final _withdrawBalanceField = TokenValueFieldController();
  final _addDepositField = TokenValueFieldController();
  final _withdrawDepositField = TokenValueFieldController();

  // final _adjustAmountField = TokenValueFieldController();
  final _moveBalanceToDepositField = TokenValueFieldController();
  final _moveDepositToBalanceField = TokenValueFieldController();
  final _warnedAmountField = TokenValueFieldController();

  // bool _adjustBalanceToDeposit = true;
  bool _txPending = false;

  OrchidWallet get wallet {
    return widget.context.wallet;
  }

  LotteryPot get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
    _withdrawBalanceField.addListener(_formFieldChanged);
    _addBalanceField.addListener(_formFieldChanged);
    _withdrawBalanceField.addListener(_formFieldChanged);
    _addDepositField.addListener(_formFieldChanged);
    _withdrawDepositField.addListener(_formFieldChanged);
    _moveBalanceToDepositField.addListener(_formFieldChanged);
    _moveDepositToBalanceField.addListener(_formFieldChanged);
    _warnedAmountField.addListener(_formFieldChanged);
    _resetWarnedField();
  }

  void _resetWarnedField() {
    if (pot != null) {
      _warnedAmountField.value = pot.warned;
    }
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (pot?.balance == null) {
      return Container();
    }
    var tokenType = pot.balance.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // add
        ..._buildAddFunds(tokenType),
        _divider(),

        // withdraw
        ..._buildWithdrawFunds(tokenType),
        _divider(),

        // move
        ..._buildMoveFunds(tokenType),
        _divider(),

        // warn
        ..._buildWarn(tokenType),

        pady(40),
        // submit button
        _buildSubmitButton(),
        pady(32),

        // _buildInstructions(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    var buttonTitle = "SUBMIT TRANSACTION";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DappButton(text: buttonTitle, onPressed: _formEnabled ? _doTx : null),
      ],
    );
  }

  List<Widget> _buildAddFunds(TokenType tokenType) {
    return [
      _buildCenteredTitle("Add Funds"),
      pady(16),
      // add
      _hidingField(
        type: tokenType,
        controller: _addBalanceField,
        label: "Balance" + ':',
        hide: _withdrawBalanceField.hasValue,
      ),
      pady(4),
      _hidingField(
        type: tokenType,
        controller: _addDepositField,
        label: "Deposit" + ':',
        hide: _withdrawDepositField.hasValue,
      )
    ];
  }

  List<Widget> _buildWithdrawFunds(TokenType tokenType) {
    return [
      _buildCenteredTitle("Withdraw Funds"),
      pady(16),
      _hidingField(
        type: tokenType,
        controller: _withdrawBalanceField,
        label: "Balance" + ':',
        hide: _addBalanceField.hasValue,
      ),
      pady(4),
      _hidingField(
        type: tokenType,
        controller: _withdrawDepositField,
        label: "Deposit" + ':',
        hide: _addDepositField.hasValue,
      )
    ];
  }

  List<Widget> _buildMoveFunds(TokenType tokenType) {
    return [
      _buildCenteredTitle("Move Funds"),
      pady(16),
      _hidingField(
        width: 200,
        type: tokenType,
        controller: _moveBalanceToDepositField,
        label: "BALANCE -> DEPOSIT",
        hide: _moveDepositToBalanceField.hasValue,
      ),
      pady(8),
      _hidingField(
        width: 200,
        type: tokenType,
        controller: _moveDepositToBalanceField,
        label: "DEPOSIT -> BALANCE",
        hide: _moveBalanceToDepositField.hasValue,
      ),
    ];
  }

  List<Widget> _buildWarn(TokenType tokenType) {
    var warnedIncreased =
        (_warnedAmountField.value ?? tokenType.zero) > pot.warned;
    var unlockTime = warnedIncreased
        ? DateTime.now().add(Duration(days: 1))
        : pot.unlockTime;
    var unlockText = unlockTime.isAfter(DateTime.now())
        ? unlockTime.toLocal().toString()
        : "Now";

    return [
      _buildCenteredTitle("Set Warned Amount"),
      pady(16),
      LabeledTokenValueField(
        labelWidth: 90,
        type: tokenType,
        controller: _warnedAmountField,
        label: "Amount" + ':',
        onClear: _resetWarnedField,
      ),
      Visibility(
        visible: _warnedAmountField.value.gtZero(),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text("Available:").button),
              Text(unlockText).button,
            ],
          ),
        ),
      )
    ];
  }

  Widget _hidingField({
    @required TokenType type,
    @required TokenValueFieldController controller,
    @required String label,
    @required bool hide,
    double width,
  }) {
    return AbsorbPointer(
      absorbing: hide,
      child: Opacity(
        opacity: hide ? 0.33 : 1.0,
        child: LabeledTokenValueField(
          labelWidth: width ?? 90,
          type: type,
          controller: controller,
          label: label,
        ),
      ),
    );
  }

  /*
  AnimatedContainer _hidingField({
    @required TokenType type,
    @required TokenValueFieldController controller,
    @required String label,
    @required bool hide,
    double width,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 330),
      height: hide ? 0 : 56,
      child: Visibility(
        visible: !hide, // animated container leaves a line at zero height?
        child: LabeledTokenValueField(
          labelWidth: width ?? 90,
          type: type,
          controller: controller,
          label: label,
        ),
      ),
    );
  }
   */

  /*
  List<Widget> _buildMoveFunds2(TokenType tokenType) {
    return [
      _buildCenteredTitle("Move Funds"),
      pady(24),
      Padding(
        padding: const EdgeInsets.only(left: 110),
        child: Text(_adjustBalanceToDeposit
                ? "Move amount from balance to deposit."
                : "Move amount from deposit to balance.")
            .subtitle
            .center,
      ),
      pady(16),
      LabeledTokenValueField(
        labelWidth: 90,
        type: tokenType,
        controller: _adjustAmountField,
        label: "Amount:",
      ),
      pady(16),
      Center(
        child: Text(_adjustBalanceToDeposit
                ? "BALANCE -> DEPOSIT"
                : "DEPOSIT -> BALANCE")
            .title,
      ),
      pady(8),
      Center(
        child: DappButton(
          text: "REVERSE",
          onPressed: () {
            setState(() {
              _adjustBalanceToDeposit = !_adjustBalanceToDeposit;
            });
          },
        ),
      )
    ];
  }
   */

  Row _buildCenteredTitle(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text).title,
      ],
    );
  }

  Padding _divider() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Divider(color: Colors.white.withOpacity(0.3)),
    );
  }

  void _formFieldChanged() {
    if (_warnedAmountField.hasNoValue) {
      _resetWarnedField();
    }
    // Update UI
    setState(() {});
  }

  Token get _netBalanceChange {
    // @formatter:off
    return _addBalanceField.value
        - _withdrawBalanceField.value
        + _moveDepositToBalanceField.value
        - _moveBalanceToDepositField.value;
    // @formatter:on
  }

  Token get _netDepositChange {
    // @formatter:off
    return _addDepositField.value
        - _withdrawDepositField.value
        + _moveBalanceToDepositField.value
        - _moveDepositToBalanceField.value;
    // @formatter:on
  }

  // positive if the warned amount is increasing
  Token get _warnedAmountChange {
    return (_warnedAmountField.value ?? pot.warned) - pot.warned;
  }

  // The net amount leaving the user's wallet (which may be negative)
  Token get _netPayable {
    return _netBalanceChange + _netDepositChange;
  }

  bool get _addFundsFormValid {
    return _netPayable <= wallet.balance;
  }

  bool get _withdrawFundsFormValid {
    return _withdrawBalanceField.value <= pot.balance &&
        _withdrawDepositField.value <= pot.warned;
  }

  bool get _moveFundsFormValid {
    return _moveBalanceToDepositField.value <= pot.balance &&
        _moveDepositToBalanceField.value <= pot.unlockedAmount;
  }

  bool get _warnFormValid {
    return _warnedAmountField.value <= pot.deposit;
  }

  // Would the transaction described by the form actually cause a change.
  bool get _formTransactionHasNetEffect {
    return _netPayable.isNotZero() ||
        _netDepositChange.isNotZero() ||
        _warnedAmountChange.isNotZero();
  }

  bool get _formEnabled {
    //log("XXX formEnabled: tx net effect: $_formTransactionHasNetEffect, warned form valid: $_warnFormValid");
    final fields = [
      _addBalanceField.value,
      _withdrawBalanceField.value,
      _moveDepositToBalanceField.value,
      _moveBalanceToDepositField.value,
      _addDepositField.value,
      _withdrawDepositField.value,
      _moveBalanceToDepositField.value,
      _moveDepositToBalanceField.value,
    ];

    // If a field is null it is invalid
    if (fields.any((e) => e == null)) {
      return false;
    }

    return !_txPending && _addFundsFormValid
        && _withdrawFundsFormValid
        && _moveFundsFormValid
        && _warnFormValid
        && _formTransactionHasNetEffect
        ;
  }

  void _doTx() async {
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context).orchidEditFunds(
        wallet: wallet,
        pot: pot,
        signer: widget.signer,
        netPayable: _netPayable,
        adjustAmount: _netDepositChange,
        warnAmount: _warnedAmountChange,
      );

      UserPreferences().addTransaction(txHash);
      _addBalanceField.clear();
      _withdrawBalanceField.clear();
      _addDepositField.clear();
      _withdrawDepositField.clear();
      _moveDepositToBalanceField.clear();
      _moveBalanceToDepositField.clear();
      _warnedAmountField.clear();
      // _adjustAmountField.clear();

      setState(() {});
      widget.onTransaction();
    } catch (err) {
      log("Error on edit funds: $err");
    }
    setState(() {
      _txPending = false;
    });
  }

  @override
  void dispose() {
    _withdrawBalanceField.removeListener(_formFieldChanged);
    _addBalanceField.removeListener(_formFieldChanged);
    _withdrawBalanceField.removeListener(_formFieldChanged);
    _addDepositField.removeListener(_formFieldChanged);
    _withdrawDepositField.removeListener(_formFieldChanged);
    _moveBalanceToDepositField.removeListener(_formFieldChanged);
    _moveDepositToBalanceField.removeListener(_formFieldChanged);
    _warnedAmountField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
