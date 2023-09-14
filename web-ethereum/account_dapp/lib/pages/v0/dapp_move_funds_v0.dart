import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/common/formatting.dart';
import '../../dapp/orchid/dapp_button.dart';
import '../../orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/util/localization.dart';

class MoveFundsPaneV0 extends StatefulWidget {
  final OrchidWeb3Context? context;
  final LotteryPot? pot;
  final EthereumAddress? signer;
  final bool enabled;

  const MoveFundsPaneV0({
    Key? key,
    required this.context,
    required this.pot,
    required this.signer,
    this.enabled = false,
  }) : super(key: key);

  @override
  _MoveFundsPaneV0State createState() => _MoveFundsPaneV0State();
}

class _MoveFundsPaneV0State extends State<MoveFundsPaneV0> {
  static final tokenType = Tokens.OXT;
  final _moveBalanceField = TypedTokenValueFieldController(type: tokenType);
  bool _txPending = false;

  LotteryPot? get pot {
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
    var buttonTitle = s.moveFunds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          type: tokenType,
          controller: _moveBalanceField,
          label: s.balanceToDeposit1,
          labelWidth: 180,
        ),
        pady(32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: buttonTitle, onPressed: _formEnabled ? _moveFunds : null),
          ],
        ),
      ],
    );
  }

  bool get _moveBalanceFieldValid {
    var balance = _moveBalanceField.value;
    // pot null guarded by page logic
    return balance != null && balance <= pot!.balance;
  }

  bool get _formEnabled {
    return pot != null &&
        !_txPending &&
        _moveBalanceFieldValid &&
        _moveBalanceField.value!.gtZero();
  }

  void _moveFunds() async {
    if (pot == null || widget.context == null || widget.signer == null) {
      throw Exception('null');
    }
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context!).orchidMoveBalanceToEscrow(
        signer: widget.signer!,
        pot: pot!,
        moveAmount: _moveBalanceField.value!,
      );
      UserPreferencesDapp().addTransaction(DappTransaction(
        transactionHash: txHash,
        chainId: widget.context!.chain.chainId,
        type: DappTransactionType.moveFunds,
      ));
      _moveBalanceField.clear();
      setState(() {});
    } catch (err) {
      log('Error on move funds: $err');
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
