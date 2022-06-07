import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/dapp_transaction.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/units.dart';

import '../dapp_button.dart';
import '../orchid_form_fields.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/common/token_price_builder.dart';

class AdvancedFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;
  final bool enabled;

  const AdvancedFundsPaneV1({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
    this.enabled,
  }) : super(key: key);

  @override
  _AdvancedFundsPaneV1State createState() => _AdvancedFundsPaneV1State();
}

class _AdvancedFundsPaneV1State extends State<AdvancedFundsPaneV1> {
  final _balanceField = TokenValueFieldController();
  _AddWithdrawDirection _balanceFieldDirection = _AddWithdrawDirection.Add;

  final _depositField = TokenValueFieldController();
  _AddWithdrawDirection _depositFieldDirection = _AddWithdrawDirection.Add;

  final _moveField = TokenValueFieldController();
  _MoveDirection _moveFieldDirection = _MoveDirection.BalanceToDeposit;

  final _warnedField = TokenValueFieldController();

  bool _txPending = false;

  OrchidWallet get wallet {
    return widget.context?.wallet;
  }

  LotteryPot get pot {
    return widget.pot;
  }

  bool get _connected {
    return pot != null;
  }

  @override
  void initState() {
    super.initState();
    _balanceField.addListener(_formFieldChanged);
    _depositField.addListener(_formFieldChanged);
    _moveField.addListener(_formFieldChanged);
    _warnedField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    var tokenType = pot?.balance?.type ?? Tokens.TOK;
    return TokenPriceBuilder(
        tokenType: tokenType,
        seconds: 30,
        builder: (USD tokenPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // add
              _buildBalanceForm(tokenType, tokenPrice),
              pady(32),

              // withdraw
              _buildDepositForm(tokenType, tokenPrice),

              pady(32),
              // move
              _buildMoveFunds(tokenType, tokenPrice),

              pady(32),
              // warn
              ..._buildWarn(tokenType, tokenPrice),

              pady(32),
              // submit button
              _buildSubmitButton(),

              pady(32),
              Text(
                s.settingAWarnedDepositAmountBeginsThe24HourWaiting +
                    ' ' +
                    s.duringThisPeriodTheFundsAreNotAvailableAsA +
                    ' ' +
                    s.fundsMayBeRelockedAtAnyTimeByReducingThe,
              ).caption.center,
            ],
          );
        });
  }

  Widget _buildSubmitButton() {
    var buttonTitle = s.submitTransaction;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DappButton(text: buttonTitle, onPressed: _formEnabled ? _doTx : null),
      ],
    );
  }

  // TODO: pull the border off of the text fields and unify this along with sizing
  Widget _addBorder(Widget widget) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1.0, color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 6, left: 16, right: 8),
        child: widget,
      ),
    );
  }

  Widget _buildBalanceForm(TokenType tokenType, USD tokenPrice) {
    return LabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.balance,
      type: tokenType,
      controller: _balanceField,
      usdPrice: tokenPrice,
      trailing: _addBorder(
        _AddWithdrawDropdown(
          enabled: widget.enabled,
          value: _balanceFieldDirection,
          onChanged: (value) {
            setState(() {
              _balanceFieldDirection = value;
            });
          },
        ),
      ).height(30),
    );
  }

  Widget _buildDepositForm(TokenType tokenType, USD tokenPrice) {
    return LabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.deposit,
      type: tokenType,
      controller: _depositField,
      usdPrice: tokenPrice,
      trailing: _addBorder(
        _AddWithdrawDropdown(
          enabled: widget.enabled,
          value: _depositFieldDirection,
          onChanged: (value) {
            setState(() {
              _depositFieldDirection = value;
            });
          },
        ),
      ).height(30),
    );
  }

  Widget _buildMoveFunds(TokenType tokenType, USD tokenPrice) {
    return LabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.move,
      type: tokenType,
      controller: _moveField,
      usdPrice: tokenPrice,
      trailing: _addBorder(
        _MoveDirectionDropdown(
          enabled: widget.enabled,
          value: _moveFieldDirection,
          onChanged: (value) {
            setState(() {
              _moveFieldDirection = value;
            });
          },
        ),
      ).height(30),
    );
  }

  List<Widget> _buildWarn(TokenType tokenType, USD tokenPrice) {
    String currentUnlockText = "", futureUnlockText = "";
    if (_connected) {
      currentUnlockText = pot.unlockTime.isAfter(DateTime.now())
          ? pot.unlockTime.toLocal().toShortString()
          : s.now;
      futureUnlockText =
          DateTime.now().add(Duration(days: 1)).toLocal().toShortString();
    }

    // Inactive field used for formatting
    final currentAmount = TokenValueFieldController();
    currentAmount.value = pot?.warned ?? tokenType.zero;

    final setLabel = (_connected && pot.isWarned)
        ? "Change Warned Amount To"
        : "Set Warned Amount To";

    return [
      Visibility(
        visible: _connected && pot.isWarned,
        child: Column(
          children: [
            // Current warned amount
            LabeledTokenValueField(
              enabled: false,
              readOnly: true,
              labelWidth: 260,
              type: tokenType,
              controller: currentAmount,
              label: "Current Warned Amount" + ':',
              usdPrice: tokenPrice,
            ),
            // Current available time
            Row(
              children: [
                SizedBox(width: 110, child: Text(s.available + ':').button),
                Text(currentUnlockText).button,
              ],
            ),
          ],
        ).bottom(16),
      ),

      // User warned amount field
      LabeledTokenValueField(
        enabled: widget.enabled,
        labelWidth: 260,
        type: tokenType,
        controller: _warnedField,
        label: setLabel,
        hintText: (pot?.warned ?? tokenType.zero)
            .toFixedLocalized(digits: 2, locale: context.locale),
        usdPrice: _warnedField.hasValue ? tokenPrice : null,
      ),
      // User available time
      Visibility(
        visible: _warnedField.hasValue && _warnedField.value.gtZero(),
        child: Text(
          "All warned funds will be locked until" + ':  ' + futureUnlockText,
          maxLines: 2,
        ).body1.top(16),
      ),
    ];
  }

  Widget _title(String text) {
    return Text(text).title;
  }

  void _formFieldChanged() {
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

  // Change to warn amount: positive if the warned amount is increasing
  Token get _warnedAmountAdd {
    if (_warnedField.hasValue) {
      return _warnedField.value - pot.warned;
    } else {
      return pot.balance.type.zero;
    }
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
    // log("XXX: _warnedAmountAdd = ${_warnedAmountAdd}");
    return _netPayable.isNotZero() ||
        _netDepositAdd.isNotZero() ||
        _warnedAmountAdd.isNotZero();
  }

  bool get _formEnabled {
    if (!_connected || pot?.balance == null || wallet == null) {
      return false;
    }

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

      UserPreferences().addTransaction(DappTransaction(
          transactionHash: txHash, chainId: widget.context.chain.chainId));
      _balanceField.clear();
      _depositField.clear();
      _moveField.clear();
      _warnedField.clear();

      setState(() {});
    } catch (err) {
      log('Error on edit funds: $err');
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
  final bool enabled;

  const _AddWithdrawDropdown({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = OrchidText.body1.withHeight(1.7).inactiveIf(!enabled);
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 180,
        child: DropdownButton<_AddWithdrawDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text(s.select).withStyle(style),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: Text("Add").withStyle(style),
              value: _AddWithdrawDirection.Add,
            ),
            DropdownMenuItem(
              child: Text(s.withdraw).withStyle(style),
              value: _AddWithdrawDirection.Withdraw,
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

enum _MoveDirection { BalanceToDeposit, DepositToBalance }

class _MoveDirectionDropdown extends StatelessWidget {
  final _MoveDirection value;
  final ValueChanged<_MoveDirection> onChanged;
  final bool enabled;

  const _MoveDirectionDropdown({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = OrchidText.body1.withHeight(1.7).inactiveIf(!enabled);
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 180,
        child: DropdownButton<_MoveDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text(s.select).withStyle(style),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: Text("Balance to Deposit").withStyle(style),
              value: _MoveDirection.BalanceToDeposit,
            ),
            DropdownMenuItem(
              child: Text("Deposit to Balance").withStyle(style),
              value: _MoveDirection.DepositToBalance,
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
