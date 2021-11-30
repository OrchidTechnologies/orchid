import 'package:flutter/material.dart';
import 'package:flutter_web3/ethers.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/on_off.dart';
import 'package:styled_text/styled_text.dart';

import 'dapp_button.dart';
import 'orchid_form_fields.dart';

class WithdrawFundsPane extends StatefulWidget {
  final OrchidWeb3Context context;

  // TODO: This will be available through context
  // final OrchidWallet wallet;

  final LotteryPot pot;

  final EthereumAddress signer;
  final VoidCallback onTransaction;

  const WithdrawFundsPane({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
    @required this.onTransaction,
  }) : super(key: key);

  @override
  _WithdrawFundsPaneState createState() => _WithdrawFundsPaneState();
}

class _WithdrawFundsPaneState extends State<WithdrawFundsPane> {
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
        _unlockDeposit ? "WITHDRAW AND UNLOCK FUNDS" : "WITHDRAW FUNDS";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTokenValueField(
          labelWidth: 90,
          type: tokenType,
          controller: _withdrawBalanceField,
          label: "Withdraw" + ':',
        ),
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
        _buildInstructions(),
      ],
    );
  }

  Row _buildUnlockDepositCheckbox(BuildContext context) {
    return Row(
      children: [
        Text("Unlock deposit: ").button.height(1.3),
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

  Widget _buildInstructions() {
    final totalFunds = pot.balance + pot.deposit;
    final maxWithdraw = pot.maxWithdrawable;
    final fullyUnlocked = maxWithdraw >= totalFunds;
    final fullyUnlockedInstruction =
        "All of your funds are available for withdrawal."
                '  ' +
            "If you specify less than the full amount funds will be drawn from your balance first."
                '  ' +
            "For additional options see the ADVANCED panel.";
    final partiallyUnlockedInstruction =
        "${maxWithdraw.formatCurrency()} of your ${totalFunds.formatCurrency()} funds are currently available for withdrawal."
        '  '
        "If you specify less than the full amount funds will be drawn from your balance first."
        '  '
        "If you select the unlock deposit option this transaction will immediately "
        "withdraw the specified amount from your balance and also begin the unlock process "
        "for your remaining deposit."
        '  '
        "Deposit funds are available for withdrawal 24 hours after unlocking."
        '  '
        "See the ADVANCED panel for additional options.";

    return StyledText(
      style: OrchidText.caption,
      textAlign: TextAlign.center,
      text: "Withdraw funds from your Orchid Account to your current wallet."
              "  " +
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
      widget.onTransaction();
    } catch (err) {
      log("Error on add funds: $err");
    }
    setState(() {
      _txPending = false;
    });
  }
}
