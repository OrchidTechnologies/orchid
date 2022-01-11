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

class MoveFundsPaneV0 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;

  const MoveFundsPaneV0({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
  }) : super(key: key);

  @override
  _MoveFundsPaneV0State createState() => _MoveFundsPaneV0State();
}

class _MoveFundsPaneV0State extends State<MoveFundsPaneV0> {
  final _moveBalanceField = TokenValueFieldController();
  bool _txPending = false;

  LotteryPot get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
    _moveBalanceField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (pot?.balance == null) {
      return Container();
    }
    var tokenType = TokenTypes.OXT;
    var buttonTitle = "MOVE FUNDS";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTokenValueField(
          type: tokenType,
          controller: _moveBalanceField,
          label: "Balance to Deposit" + ':',
          labelWidth: 180,
        ),
        pady(32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: buttonTitle,
                onPressed: _formEnabled ? _moveFunds : null),
          ],
        ),
      ],
    );
  }

  bool get _moveBalanceFieldValid {
    var balance = _moveBalanceField.value;
    return balance != null && balance <= pot.balance;
  }

  bool get _formEnabled {
    return !_txPending &&
        _moveBalanceFieldValid &&
        _moveBalanceField.value.gtZero();
  }

  void _moveFunds() async {
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context).orchidMoveBalanceToEscrow(
        signer: widget.signer,
        pot: pot,
        moveAmount: _moveBalanceField.value,
      );
      UserPreferences().addTransaction(txHash);
      _moveBalanceField.clear();
      setState(() {});
    } catch (err) {
      log("Error on move funds: $err");
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
    _moveBalanceField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
