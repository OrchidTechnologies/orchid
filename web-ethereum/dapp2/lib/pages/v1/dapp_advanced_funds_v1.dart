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
import 'package:orchid/util/units.dart';

import '../dapp_button.dart';
import '../orchid_form_fields.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/common/token_price_builder.dart';

class AdvancedFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;

  const AdvancedFundsPaneV1({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
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
    if (pot?.balance == null || wallet?.balance == null) {
      return Container();
    }
    var tokenType = pot.balance.type;
    return TokenPriceBuilder(
        tokenType: tokenType,
        seconds: 30,
        builder: (USD tokenPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // add
              ..._buildBalanceForm(tokenType, tokenPrice),
              pady(32),

              // withdraw
              ..._buildDepositForm(tokenType, tokenPrice),

              pady(32),
              // move
              ..._buildMoveFunds(tokenType, tokenPrice),

              pady(32),
              // warn
              ..._buildWarn(tokenType, tokenPrice),

              pady(48),
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 6, left: 16, right: 8),
          child: widget,
        ));
  }

  List<Widget> _buildBalanceForm(TokenType tokenType, USD tokenPrice) {
    return [
      _buildTitle(s.balance),
      pady(24),
      Row(
        children: [
          _addBorder(_AddWithdrawDropdown(
            value: _balanceFieldDirection,
            onChanged: (value) {
              setState(() {
                _balanceFieldDirection = value;
              });
            },
          )),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _balanceField,
              usdPrice: tokenPrice,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDepositForm(TokenType tokenType, USD tokenPrice) {
    return [
      _buildTitle(s.deposit),
      pady(24),
      Row(
        children: [
          _addBorder(_AddWithdrawDropdown(
            value: _depositFieldDirection,
            onChanged: (value) {
              setState(() {
                _depositFieldDirection = value;
              });
            },
          )),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _depositField,
              usdPrice: tokenPrice,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildMoveFunds(TokenType tokenType, USD tokenPrice) {
    return [
      _buildTitle(s.move),
      pady(24),
      Row(
        children: [
          _addBorder(_MoveDirectionDropdown(
            value: _moveFieldDirection,
            onChanged: (value) {
              setState(() {
                _moveFieldDirection = value;
              });
            },
          )),
          padx(16),
          Expanded(
            child: LabeledTokenValueField(
              labelWidth: 0,
              type: tokenType,
              controller: _moveField,
              usdPrice: tokenPrice,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildWarn(TokenType tokenType, USD tokenPrice) {
    var warnedIncreased = (_warnedField.value ?? tokenType.zero) > pot.warned;
    var unlockTime = warnedIncreased
        ? DateTime.now().add(Duration(days: 1))
        : pot.unlockTime;
    var unlockText = unlockTime.isAfter(DateTime.now())
        ? unlockTime.toLocal().toString()
        : s.now;

    return [
      _buildTitle(s.warn),
      pady(24),
      LabeledTokenValueField(
        labelWidth: 260,
        type: tokenType,
        controller: _warnedField,
        label: s.totalWarnedAmount + ':',
        onClear: _resetWarnedField,
        usdPrice: tokenPrice,
      ),
      Visibility(
        visible: _warnedField.value.gtZero(),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(s.available + ':').button),
              Text(unlockText).button,
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildTitle(String text) {
    return Text(text).title;
    // return Row(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Text(text).title,
    //   ],
    // );
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

  const _AddWithdrawDropdown({
    Key key,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 220,
        child: DropdownButton<_AddWithdrawDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text(s.select, style: OrchidText.button),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: Text(
                s.add,
                textAlign: TextAlign.right,
              ).button,
              value: _AddWithdrawDirection.Add,
            ),
            DropdownMenuItem(
              child: Text(s.withdraw).button,
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
    final s = context.s;
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: OrchidColors.dark_background,
        focusColor: OrchidColors.purple_menu,
      ),
      child: SizedBox(
        width: 220,
        child: DropdownButton<_MoveDirection>(
          isExpanded: true,
          // make the width flexible
          hint: Text(s.select, style: OrchidText.button),
          underline: Container(),
          value: value,
          items: [
            DropdownMenuItem(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(s.balanceToDeposit).button),
              value: _MoveDirection.BalanceToDeposit,
            ),
            DropdownMenuItem(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(s.depositToBalance).button),
              value: _MoveDirection.DepositToBalance,
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
