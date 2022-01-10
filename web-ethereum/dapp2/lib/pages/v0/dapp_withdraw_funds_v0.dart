import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';

import '../dapp_button.dart';
import '../orchid_form_fields.dart';

class WithdrawFundsPaneV0 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;

  const WithdrawFundsPaneV0({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
  }) : super(key: key);

  @override
  _WithdrawFundsPaneV0State createState() => _WithdrawFundsPaneV0State();
}

class _WithdrawFundsPaneV0State extends State<WithdrawFundsPaneV0> {
  final _withdrawBalanceField = TokenValueFieldController();
  final _withdrawEscrowField = TokenValueFieldController();
  bool _txPending = false;

  LotteryPot get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
    _withdrawBalanceField.addListener(_formFieldChanged);
    _withdrawEscrowField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (pot?.balance == null) {
      return Container();
    }
    var tokenType = TokenTypes.OXT;
    var buttonTitle = "WITHDRAW FUNDS";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTokenValueField(
          type: tokenType,
          controller: _withdrawBalanceField,
          label: "Balance" + ':',
        ),
        pady(4),
        LabeledTokenValueField(
          type: tokenType,
          controller: _withdrawEscrowField,
          label: "Deposit" + ':',
        ),
        pady(32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: buttonTitle,
                onPressed: _withdrawFundsFormEnabled ? _withdrawFunds : null),
          ],
        ),
      ],
    );
  }

  bool get _withdrawFieldValid {
    var balance = _withdrawBalanceField.value;
    return balance != null && balance <= pot.balance;
  }

  bool get _escrowFieldValid {
    var escrow = _withdrawEscrowField.value;
    return escrow != null && escrow <= pot.unlockedAmount;
  }

  bool get _withdrawFundsFormEnabled {
    return !_txPending &&
        _withdrawFieldValid &&
        _escrowFieldValid &&
        (_withdrawBalanceField.value.gtZero() ||
            _withdrawEscrowField.value.gtZero());
  }

  void _withdrawFunds() async {
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context).orchidWithdrawFunds(
        wallet: widget.context.walletAddress,
        signer: widget.signer,
        pot: pot,
        withdrawBalance: _withdrawBalanceField.value,
        withdrawEscrow: _withdrawEscrowField.value,
      );
      UserPreferences().addTransaction(txHash);
      _withdrawBalanceField.clear();
      _withdrawEscrowField.clear();
      setState(() {});
    } catch (err) {
      log("Error on withdraw funds: $err");
    }
    setState(() {
      _txPending = false;
    });
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  @override
  void dispose() {
    _withdrawBalanceField.removeListener(_formFieldChanged);
    _withdrawEscrowField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
