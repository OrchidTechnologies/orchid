import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/api/pricing/usd.dart';
import '../../dapp/orchid/dapp_button.dart';
import '../../dapp/orchid/dapp_error_row.dart';
import '../../dapp/orchid/dapp_tab_context.dart';
import '../../orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';

class AdvancedFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context? context;
  final LotteryPot? pot;
  final EthereumAddress? signer;
  final bool enabled;

  const AdvancedFundsPaneV1({
    Key? key,
    required this.context,
    required this.pot,
    required this.signer,
    this.enabled = false,
  }) : super(key: key);

  @override
  _AdvancedFundsPaneV1State createState() => _AdvancedFundsPaneV1State();
}

class _AdvancedFundsPaneV1State extends State<AdvancedFundsPaneV1>
    with DappTabWalletContext, DappTabPotContext {
  OrchidWeb3Context? get web3Context => widget.context;

  LotteryPot? get pot => widget.pot;

  EthereumAddress? get signer => widget.signer;

  late TypedTokenValueFieldController _balanceField;
  _AddWithdrawDirection _balanceFieldDirection = _AddWithdrawDirection.Add;

  late TypedTokenValueFieldController _depositField;
  _AddWithdrawDirection _depositFieldDirection = _AddWithdrawDirection.Add;

  late TypedTokenValueFieldController _moveField;
  _MoveDirection _moveFieldDirection = _MoveDirection.BalanceToDeposit;

  late TypedTokenValueFieldController _warnedField;

  @override
  void initState() {
    super.initState();
    _balanceField = TypedTokenValueFieldController(type: tokenType);
    _balanceField.addListener(_formFieldChanged);
    _depositField = TypedTokenValueFieldController(type: tokenType);
    _depositField.addListener(_formFieldChanged);
    _moveField = TypedTokenValueFieldController(type: tokenType);
    _moveField.addListener(_formFieldChanged);
    _warnedField = TypedTokenValueFieldController(type: tokenType);
    _warnedField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    var tokenType = pot?.balance.type ?? Tokens.TOK;
    return TokenPriceBuilder(
        tokenType: tokenType,
        seconds: 30,
        builder: (USD? tokenPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // add
              _buildBalanceField(tokenType, tokenPrice),
              pady(32),

              // withdraw
              _buildDepositField(tokenType, tokenPrice),

              pady(32),
              // move
              _buildMoveField(tokenType, tokenPrice),

              pady(32),
              // warn
              ..._buildWarn(tokenType, tokenPrice),

              if (_netPayableError)
                DappErrorRow(text: 'Total exceeds wallet balance.').top(16),

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

  Widget _buildBalanceField(TokenType tokenType, USD? tokenPrice) {
    return OrchidLabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.balance,
      type: tokenType,
      controller: _balanceField,
      usdPrice: tokenPrice,
      error: _balanceFieldError || _netPayableError,
      trailing: _addBorder(
        _AddWithdrawDropdown(
          enabled: widget.enabled,
          value: _balanceFieldDirection,
          onChanged: (value) {
            setState(() {
              _balanceFieldDirection = value ?? _AddWithdrawDirection.Add;
            });
          },
        ),
      ).height(30),
    );
  }

  Widget _buildDepositField(TokenType tokenType, USD? tokenPrice) {
    return OrchidLabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.deposit,
      type: tokenType,
      controller: _depositField,
      usdPrice: tokenPrice,
      error: _depositFieldError || _netPayableError,
      trailing: _addBorder(
        _AddWithdrawDropdown(
          enabled: widget.enabled,
          value: _depositFieldDirection,
          onChanged: (value) {
            setState(() {
              _depositFieldDirection = value ?? _AddWithdrawDirection.Add;
            });
          },
        ),
      ).height(30),
    );
  }

  Widget _buildMoveField(TokenType tokenType, USD? tokenPrice) {
    return OrchidLabeledTokenValueField(
      enabled: widget.enabled,
      labelWidth: 100,
      label: s.move,
      type: tokenType,
      controller: _moveField,
      usdPrice: tokenPrice,
      error: _moveFieldError,
      trailing: _addBorder(
        _MoveDirectionDropdown(
          enabled: widget.enabled,
          value: _moveFieldDirection,
          onChanged: (value) {
            setState(() {
              _moveFieldDirection = value ?? _MoveDirection.BalanceToDeposit;
            });
          },
        ),
      ).height(30),
    );
  }

  List<Widget> _buildWarn(TokenType tokenType, USD? tokenPrice) {
    String currentUnlockText = "", futureUnlockText = "";
    // pot guarded by 'connected'
    if (connected) {
      currentUnlockText = pot!.unlockTime.isAfter(DateTime.now())
          ? pot!.unlockTime.toLocal().toShortString()
          : s.now;
      futureUnlockText =
          DateTime.now().add(Duration(days: 1)).toLocal().toShortString();
    }

    // Inactive field used for formatting
    final currentAmount = TypedTokenValueFieldController(type: tokenType);
    currentAmount.value = pot?.warned ?? tokenType.zero;

    final warnLabelText = (connected && pot!.isWarned)
        ? s.changeWarnedAmountTo
        : s.setWarnedAmountTo;

    return [
      Visibility(
        visible: connected && pot!.isWarned,
        child: Column(
          children: [
            // Current warned amount
            OrchidLabeledTokenValueField(
              enabled: false,
              readOnly: true,
              labelWidth: 260,
              type: tokenType,
              controller: currentAmount,
              label: s.currentWarnedAmount + ':',
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
      OrchidLabeledTokenValueField(
        enabled: widget.enabled,
        labelWidth: 260,
        type: tokenType,
        controller: _warnedField,
        label: warnLabelText,
        usdPrice: _warnedField.hasValue ? tokenPrice : null,
        error: _warnFieldError,
      ),
      // User available time
      Visibility(
        visible: _warnedField.hasValue &&
            _warnedField.value!.gtZero() &&
            !_warnFieldError,
        child: Text(
          s.allWarnedFundsWillBeLockedUntil + ':  ' + futureUnlockText,
          maxLines: 2,
        ).body1.top(16),
      ),
    ];
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  // The move balance to deposit amount which may be negative to indicate
  // a move from deposit to balance.
  Token get _moveBalanceToDepositAmount {
    return _moveFieldDirection == _MoveDirection.BalanceToDeposit
        ? _moveField.value!
        : -_moveField.value!;
  }

  // The add balance amount which may be negative to indicate a withdrawal.
  Token get _addBalanceAmount {
    return _balanceFieldDirection == _AddWithdrawDirection.Add
        ? _balanceField.value!
        : -_balanceField.value!;
  }

  // a positive or negative amount indicating the amount added to balance;
  Token get _netBalanceAdd {
    return _addBalanceAmount - _moveBalanceToDepositAmount;
  }

  // Token get _netBalanceWithdraw {
  //   return -_netBalanceAdd;
  // }

  // The add deposit amount which may be negative to indicate a withdrawal.
  Token get _addDepositAmount {
    return _depositFieldDirection == _AddWithdrawDirection.Add
        ? _depositField.value!
        : -_depositField.value!;
  }

  // a positive or negative amount indicating the amount added to deposit
  Token get _netDepositAdd {
    return _addDepositAmount + _moveBalanceToDepositAmount;
  }

  // Token get _netDepositWithdraw {
  //   return -_netDepositAdd;
  // }

  // Change to warn amount: positive if the warned amount is increasing
  Token get _warnedAmountAdd {
    if (_warnedField.hasValue) {
      return _warnedField.value! - pot!.warned;
    } else {
      return pot!.balance.type.zero;
    }
  }

  // The net amount leaving the user's wallet (which may be negative)
  Token get _netPayable {
    return _netBalanceAdd + _netDepositAdd;
  }

  bool get _netPayableValid {
    return _netPayable <= wallet!.balance!;
  }

  bool get _netPayableError {
    return pot != null &&
        wallet != null &&
        !_balanceFieldError &&
        !_depositFieldError &&
        !_moveFieldError &&
        !_warnFieldError &&
        !_netPayableValid;
  }

  bool get _balanceFieldValid {
    switch (_balanceFieldDirection) {
      case _AddWithdrawDirection.Add:
        return _balanceField.value != null &&
            _balanceField.value! <= walletBalance!;
      case _AddWithdrawDirection.Withdraw:
        return _balanceField.value != null &&
            _balanceField.value! <= pot!.balance;
      default:
        throw Exception();
    }
  }

  bool get _balanceFieldError {
    return pot != null && wallet != null && !_balanceFieldValid;
  }

  bool get _depositFieldValid {
    switch (_depositFieldDirection) {
      case _AddWithdrawDirection.Add:
        return _depositField.value != null &&
            _depositField.value! <= walletBalance!;
      case _AddWithdrawDirection.Withdraw:
        return _depositField.value != null &&
            _depositField.value! <= pot!.unlockedAmount;
      default:
        throw Exception();
    }
  }

  bool get _depositFieldError {
    return pot != null && wallet != null && !_depositFieldValid;
  }

  bool get _moveFieldValid {
    switch (_moveFieldDirection) {
      case _MoveDirection.BalanceToDeposit:
        return _moveField.value != null && _moveField.value! <= pot!.balance;
      case _MoveDirection.DepositToBalance:
        return _moveField.value != null &&
            _moveField.value! <= pot!.unlockedAmount;
      default:
        throw Exception();
    }
  }

  bool get _moveFieldError {
    return pot != null && wallet != null && !_moveFieldValid;
  }

  bool get _warnFormValid {
    return _warnedField.value != null && _warnedField.value! <= pot!.deposit;
  }

  bool get _warnFieldError {
    return pot != null && !_warnFormValid;
  }

  // Would the transaction described by the form actually cause a change.
  bool get _formTransactionHasNetEffect {
    return _netPayable.isNotZero() ||
        _netDepositAdd.isNotZero() ||
        _warnedAmountAdd.isNotZero();
  }

  bool get _formEnabled {
    if (!connected || pot?.balance == null || wallet == null) {
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

    return !txPending &&
        _balanceFieldValid &&
        _depositFieldValid &&
        _moveFieldValid &&
        _warnFormValid &&
        _netPayableValid &&
        _formTransactionHasNetEffect;
  }

  void _doTx() async {
    if (widget.context == null) {
      throw Exception('No context');
    }
    setState(() {
      txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context!).orchidEditFunds(
        wallet: wallet!,
        pot: pot!,
        signer: widget.signer!,
        netPayable: _netPayable,
        adjustAmount: _netDepositAdd,
        warnAmount: _warnedAmountAdd,
      );

      UserPreferencesDapp().addTransaction(DappTransaction(
        transactionHash: txHash,
        chainId: widget.context!.chain.chainId,
        type: DappTransactionType.accountChanges,
      ));
      _balanceField.clear();
      _depositField.clear();
      _moveField.clear();
      _warnedField.clear();

      setState(() {});
    } catch (err) {
      log('Error on edit funds: $err');
    }
    setState(() {
      txPending = false;
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
  final ValueChanged<_AddWithdrawDirection?> onChanged;
  final bool enabled;

  const _AddWithdrawDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = OrchidText.body1.withHeight(1.7).disabledIf(!enabled);
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
  final ValueChanged<_MoveDirection?> onChanged;
  final bool enabled;

  const _MoveDirectionDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = OrchidText.body1.withHeight(1.7).disabledIf(!enabled);
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
              child: Text(s.balanceToDeposit1).withStyle(style),
              value: _MoveDirection.BalanceToDeposit,
            ),
            DropdownMenuItem(
              child: Text(s.depositToBalance1).withStyle(style),
              value: _MoveDirection.DepositToBalance,
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
