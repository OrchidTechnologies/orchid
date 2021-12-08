import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
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
  final _balanceField = TokenValueFieldController();
  _AddWithdrawDirection _balanceFieldDirection = _AddWithdrawDirection.Add;

  final _depositField = TokenValueFieldController();
  _AddWithdrawDirection _depositFieldDirection = _AddWithdrawDirection.Add;

  final _moveField = TokenValueFieldController();
  _MoveDirection _moveFieldDirection = _MoveDirection.BalanceToDeposit;

  final _warnedField = TokenValueFieldController();

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
    _balanceField.addListener(_formFieldChanged);
    _depositField.addListener(_formFieldChanged);
    _moveField.addListener(_formFieldChanged);
    _warnedField.addListener(_formFieldChanged);
    _resetWarnedField();
  }

  void _resetWarnedField() {
    if (pot != null) {
      _warnedField.value = pot.warned;
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
        ..._buildBalanceForm(tokenType),
        pady(32),

        // withdraw
        ..._buildDepositForm(tokenType),

        pady(32),
        // move
        ..._buildMoveFunds(tokenType),

        pady(32),
        // warn
        ..._buildWarn(tokenType),

        pady(32),
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

  List<Widget> _buildBalanceForm(TokenType tokenType) {
    return [
      _buildCenteredTitle("Balance"),
      pady(24),
      Row(
        children: [
          _AddWithdrawDropdown(
            value: _balanceFieldDirection,
            onChanged: (value) {
              setState(() {
                _balanceFieldDirection = value;
              });
            },
          ),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _balanceField,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDepositForm(TokenType tokenType) {
    return [
      _buildCenteredTitle("Deposit"),
      pady(24),
      Row(
        children: [
          _AddWithdrawDropdown(
            value: _depositFieldDirection,
            onChanged: (value) {
              setState(() {
                _depositFieldDirection = value;
              });
            },
          ),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _depositField,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildMoveFunds(TokenType tokenType) {
    return [
      _buildCenteredTitle("Move"),
      pady(24),
      Row(
        children: [
          _MoveDirectionDropdown(
            value: _moveFieldDirection,
            onChanged: (value) {
              setState(() {
                _moveFieldDirection = value;
              });
            },
          ),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _moveField,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildWarn(TokenType tokenType) {
    var warnedIncreased = (_warnedField.value ?? tokenType.zero) > pot.warned;
    var unlockTime = warnedIncreased
        ? DateTime.now().add(Duration(days: 1))
        : pot.unlockTime;
    var unlockText = unlockTime.isAfter(DateTime.now())
        ? unlockTime.toLocal().toString()
        : "Now";

    return [
      _buildCenteredTitle("Set Warned Amount"),
      pady(24),
      LabeledTokenValueField(
        labelWidth: 120,
        type: tokenType,
        controller: _warnedField,
        label: "Amount" + ':',
        onClear: _resetWarnedField,
      ),
      Visibility(
        visible: _warnedField.value.gtZero(),
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
    if (_warnedField.hasNoValue) {
      _resetWarnedField();
    }
    // Update UI
    setState(() {});
  }

  // The move balance to deposit amount which may be negative to indicate
  // a move from deposit to balance.
  Token get _moveBalanceToDepositAmount {
    return _moveFieldDirection == _MoveDirection.BalanceToDeposit
        ? _moveField.value
        : -_moveField.value;
  }

  // The add balance amount which may be negative to indicate a withdrawal.
  Token get _addBalanceAmount {
    return _balanceFieldDirection == _AddWithdrawDirection.Add
        ? _balanceField.value
        : -_balanceField.value;
  }

  // a positive or negative amount indicating the amount added to balance;
  Token get _netBalanceAdd {
    return _addBalanceAmount - _moveBalanceToDepositAmount;
  }

  Token get _netBalanceWithdraw {
    return -_netBalanceAdd;
  }

  // The add deposit amount which may be negative to indicate a withdrawal.
  Token get _addDepositAmount {
    return _depositFieldDirection == _AddWithdrawDirection.Add
        ? _depositField.value
        : -_depositField.value;
  }

  // a positive or negative amount indicating the amount added to deposit
  Token get _netDepositAdd {
    return _addDepositAmount + _moveBalanceToDepositAmount;
  }

  Token get _netDepositWithdraw {
    return -_netDepositAdd;
  }

  // positive if the warned amount is increasing
  Token get _warnedAmountAdd {
    return (_warnedField.value ?? pot.warned) - pot.warned;
  }

  // The net amount leaving the user's wallet (which may be negative)
  Token get _netPayable {
    return _netBalanceAdd + _netDepositAdd;
  }

  bool get _netFundsChangeValid {
    return _netPayable <= wallet.balance;
  }

  bool get _balanceFormValid {
    switch (_balanceFieldDirection) {
      case _AddWithdrawDirection.Add:
        return true;
        break;
      case _AddWithdrawDirection.Withdraw:
        return _balanceField.value <= pot.balance &&
            _netBalanceWithdraw <= pot.balance;
        break;
      default:
        throw Exception();
    }
  }

  bool get _depositFormValid {
    switch (_depositFieldDirection) {
      case _AddWithdrawDirection.Add:
        return true;
        break;
      case _AddWithdrawDirection.Withdraw:
        return _depositField.value <= pot.warned &&
            _netDepositWithdraw <= pot.warned;
        break;
      default:
        throw Exception();
    }
  }

  bool get _moveFormValid {
    // return _balanceField.value <= pot.balance && _withdrawDepositField.value <= pot.warned;
    switch (_moveFieldDirection) {
      case _MoveDirection.BalanceToDeposit:
        return _moveField.value <= pot.balance;
        break;
      case _MoveDirection.DepositToBalance:
        return _moveField.value <= pot.warned;
        break;
      default:
        throw Exception();
    }
  }

  bool get _warnFormValid {
    return _warnedField.value <= pot.deposit;
  }

  // Would the transaction described by the form actually cause a change.
  bool get _formTransactionHasNetEffect {
    return _netPayable.isNotZero() ||
        _netDepositAdd.isNotZero() ||
        _warnedAmountAdd.isNotZero();
  }

  bool get _formEnabled {
    final fields = [
      _balanceField.value,
      _depositField.value,
      _moveField.value,
      _warnedField.value,
    ];
    // If a field is null it is invalid
    if (fields.any((e) => e == null)) {
      return false;
    }

    return !_txPending &&
        _netFundsChangeValid &&
        _balanceFormValid &&
        _depositFormValid &&
        _moveFormValid &&
        _warnFormValid &&
        _formTransactionHasNetEffect;
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
        adjustAmount: _netDepositAdd,
        warnAmount: _warnedAmountAdd,
      );

      UserPreferences().addTransaction(txHash);
      _balanceField.clear();
      _depositField.clear();
      _moveField.clear();
      _warnedField.clear();

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
    _balanceField.removeListener(_formFieldChanged);
    _depositField.removeListener(_formFieldChanged);
    _moveField.removeListener(_formFieldChanged);
    _warnedField.removeListener(_formFieldChanged);
    super.dispose();
  }
}

enum _AddWithdrawDirection { Add, Withdraw }

class _AddWithdrawDropdown extends StatelessWidget {
  final _AddWithdrawDirection value;
  final ValueChanged<_AddWithdrawDirection> onChanged;

  const _AddWithdrawDropdown({
    Key key,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 110,
        child: DropdownButton<_AddWithdrawDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text("Select", style: OrchidText.button),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: Text(
                "Add",
                textAlign: TextAlign.right,
              ).button,
              value: _AddWithdrawDirection.Add,
            ),
            DropdownMenuItem(
              child: Text("Withdraw").button,
              value: _AddWithdrawDirection.Withdraw,
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

enum _MoveDirection { BalanceToDeposit, DepositToBalance }

class _MoveDirectionDropdown extends StatelessWidget {
  final _MoveDirection value;
  final ValueChanged<_MoveDirection> onChanged;

  const _MoveDirectionDropdown({
    Key key,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 200,
        child: DropdownButton<_MoveDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text("Select", style: OrchidText.button),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: Text("Balance to Deposit").button,
              value: _MoveDirection.BalanceToDeposit,
            ),
            DropdownMenuItem(
              child: Text("Deposit to Balance").button,
              value: _MoveDirection.DepositToBalance,
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
