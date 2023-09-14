import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
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

class WithdrawFundsPaneV0 extends StatefulWidget {
  final OrchidWeb3Context? context;
  final LotteryPot? pot;
  final EthereumAddress? signer;
  final bool enabled;

  const WithdrawFundsPaneV0({
    Key? key,
    required this.context,
    required this.pot,
    required this.signer,
    required this.enabled,
  }) : super(key: key);

  @override
  _WithdrawFundsPaneV0State createState() => _WithdrawFundsPaneV0State();
}

class _WithdrawFundsPaneV0State extends State<WithdrawFundsPaneV0> {
  static final tokenType = Tokens.OXT;
  final _withdrawBalanceField = TypedTokenValueFieldController(type: tokenType);
  final _withdrawEscrowField = TypedTokenValueFieldController(type: tokenType);
  bool _txPending = false;

  LotteryPot? get pot {
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
    var buttonTitle = s.withdrawFunds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          type: tokenType,
          controller: _withdrawBalanceField,
          label: s.balance,
        ),
        pady(4),
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          type: tokenType,
          controller: _withdrawEscrowField,
          label: s.deposit,
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
    return balance != null && balance <= pot!.balance;
  }

  bool get _escrowFieldValid {
    var escrow = _withdrawEscrowField.value;
    return escrow != null && escrow <= pot!.unlockedAmount;
  }

  bool get _withdrawFundsFormEnabled {
    return pot != null &&
        !_txPending &&
        _withdrawFieldValid &&
        _escrowFieldValid &&
        (_withdrawBalanceField.value!.gtZero() ||
            _withdrawEscrowField.value!.gtZero());
  }

  void _withdrawFunds() async {
    if (widget.context == null || pot == null || widget.signer == null) {
      throw Exception('Invalid state');
    }
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context!).orchidWithdrawFunds(
        wallet: widget.context!.walletAddress!,
        signer: widget.signer!,
        pot: pot!,
        withdrawBalance: _withdrawBalanceField.value!,
        withdrawEscrow: _withdrawEscrowField.value!,
      );
      UserPreferencesDapp().addTransaction(DappTransaction(
        transactionHash: txHash,
        chainId: widget.context!.chain.chainId,
        type: DappTransactionType.withdrawFunds,
      ));
      _withdrawBalanceField.clear();
      _withdrawEscrowField.clear();
      setState(() {});
    } catch (err) {
      log('Error on withdraw funds: $err');
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
