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
import 'package:styled_text/styled_text.dart';
import '../dapp_button.dart';
import '../orchid_form_fields.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/common/token_price_builder.dart';

class WithdrawFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;

  const WithdrawFundsPaneV1({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
  }) : super(key: key);

  @override
  _WithdrawFundsPaneV1State createState() => _WithdrawFundsPaneV1State();
}

class _WithdrawFundsPaneV1State extends State<WithdrawFundsPaneV1> {
  final _withdrawBalanceField = TokenValueFieldController();
  bool _txPending = false;

  LotteryPot get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
    _withdrawBalanceField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  bool _unlockDeposit = false;

  @override
  Widget build(BuildContext context) {
    if (pot?.balance == null) {
      return Container();
    }
    var tokenType = pot.balance.type;
    var buttonTitle =
        _unlockDeposit ? s.withdrawAndUnlockFunds : s.withdrawFunds;

    final totalFunds = pot.balance + pot.deposit;
    final maxWithdraw = pot.maxWithdrawable;
    final fullyUnlocked = maxWithdraw >= totalFunds;

    final availableText = fullyUnlocked
        ? s.allOfYourFundsAreAvailableForWithdrawal
        : s.maxWithdrawOfYourTotalFundsCombinedFunds(
            maxWithdraw.formatCurrency(locale: context.locale),
            totalFunds.formatCurrency(locale: context.locale));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pady(16),
        Text(availableText).title,
        pady(24),
        TokenPriceBuilder(
            tokenType: tokenType,
            seconds: 30,
            builder: (USD tokenPrice) {
              return LabeledTokenValueField(
                labelWidth: 100,
                type: tokenType,
                controller: _withdrawBalanceField,
                label: s.withdraw + ':',
                usdPrice: tokenPrice,
              );
            }),
        if (pot.deposit > pot.unlockedAmount)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildUnlockDepositCheckbox(context),
          ),
        pady(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: buttonTitle,
                onPressed: _withdrawFundsFormEnabled ? _withdrawFunds : null),
          ],
        ),
        pady(32),
        _buildInstructions(fullyUnlocked),
      ],
    );
  }

  Row _buildUnlockDepositCheckbox(BuildContext context) {
    return Row(
      children: [
        Text(s.alsoUnlockRemainingDeposit + ': ').button.height(1.3),
        padx(8),
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: Colors.white,
            toggleableActiveColor: OrchidColors.tappable,
          ),
          child: Checkbox(
              value: _unlockDeposit,
              onChanged: (value) {
                setState(() {
                  _unlockDeposit = value;
                });
              }),
        ),
      ],
    );
  }

  Widget _buildInstructions(bool fullyUnlocked) {
    final fullyUnlockedInstruction =
        s.ifYouSpecifyLessThanTheFullAmountFundsWill +
            '  ' +
            s.forAdditionalOptionsSeeTheAdvancedPanel;

    final partiallyUnlockedInstruction =
        s.ifYouSpecifyLessThanTheFullAmountFundsWill +
            '  ' +
            s.ifYouSelectTheUnlockDepositOptionThisTransactionWill +
            '  ' +
            s.depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking +
            '  ' +
            s.forAdditionalOptionsSeeTheAdvancedPanel;

    return StyledText(
      style: OrchidText.caption,
      textAlign: TextAlign.center,
      text: s.withdrawFundsFromYourOrchidAccountToYourCurrentWallet +
          '  ' +
          (fullyUnlocked
              ? fullyUnlockedInstruction
              : partiallyUnlockedInstruction),
      tags: {
        // 'link': OrchidText.caption.linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  bool get _withdrawFundsFormEnabled {
    var value = _withdrawBalanceField.value;
    return !_txPending &&
        value != null &&
        value.gtZero() &&
        value <= pot.maxWithdrawable;
  }

  void _withdrawFunds() async {
    // Cap total at max withdrawable.
    var totalWithdrawal =
        Token.min(_withdrawBalanceField.value, pot.maxWithdrawable);
    // first from the balance
    var withdrawBalance = Token.min(totalWithdrawal, pot.balance);
    // any remainder from the warned deposit
    var withdrawDeposit = totalWithdrawal - withdrawBalance;

    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context).orchidWithdrawFunds(
        pot: pot,
        signer: widget.signer,
        withdrawBalance: withdrawBalance,
        withdrawEscrow: withdrawDeposit,
        warnDeposit: _unlockDeposit,
      );
      UserPreferences().addTransaction(txHash);
      _withdrawBalanceField.clear();
      _unlockDeposit = false;
      setState(() {});
    } catch (err) {
      log('Error on withdraw funds: $err');
    }
    setState(() {
      _txPending = false;
    });
  }

  @override
  void dispose() {
    _withdrawBalanceField.removeListener(_formFieldChanged);
    _withdrawBalanceField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
