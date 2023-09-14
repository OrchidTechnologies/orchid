import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:orchid/dapp/orchid/dapp_button.dart';
import 'package:orchid/dapp/orchid/dapp_tab_context.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/stake_dapp/orchid_web3_stake_v0.dart';

class WithdrawStakePanel extends StatefulWidget {
  final OrchidWeb3Context? web3context;
  final EthereumAddress? stakee;
  final Token? currentStake;
  final USD? price;
  final bool enabled;

  const WithdrawStakePanel({
    super.key,
    required this.web3context,
    required this.stakee,
    required this.currentStake,
    required this.price,
    required this.enabled,
  });

  @override
  State<WithdrawStakePanel> createState() => _WithdrawStakePanelState();
}

class _WithdrawStakePanelState extends State<WithdrawStakePanel>
    with DappTabWalletContext {
  OrchidWeb3Context? get web3Context => widget.web3context;

  late NumericValueFieldController _indexController;
  late TypedTokenValueFieldController _withdrawStakeAmountController;
  late AddressValueFieldController _targetController;

  @override
  TokenType get tokenType => Tokens.OXT;

  @override
  void initState() {
    super.initState();
    _withdrawStakeAmountController = TypedTokenValueFieldController(
        type: tokenType, listener: _formFieldChanged);
    _indexController =
        NumericValueFieldController.withListener(_formFieldChanged);
    _targetController =
        AddressValueFieldController.withListener(_formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          label: "Withdraw Stake",
          type: Tokens.OXT,
          controller: _withdrawStakeAmountController,
          error: _withdrawStakeFieldError,
          usdPrice: widget.price,
        ).top(32).padx(8),
        OrchidLabeledNumericField(
          enabled: widget.enabled,
          integer: true,
          label: "From Index",
          controller: _indexController,
          showPaste: false,
          backgroundColor: OrchidColors.dark_background_2,
        ).top(16).padx(8),
        OrchidLabeledAddressField(
          enabled: widget.enabled,
          label: "To Address", // localize
          controller: _targetController,
          contentPadding:
              EdgeInsets.only(top: 8, bottom: 18, left: 16, right: 16),
        ).top(16).padx(8),
        DappButton(
          text: "PULL FUNDS",
          onPressed: _formEnabled ? _withdrawStake : null,
        ).top(32),
      ],
    ).width(double.infinity);
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  bool get _formEnabled {
    return !txPending &&
        _withdrawStakeFieldValid &&
        _withdrawStakeAmountController.value!.gtZero() &&
        _targetFieldValid;
  }

  bool get _withdrawStakeFieldError {
    return walletBalanceOf(tokenType) != null && !_withdrawStakeFieldValid;
  }

  bool get _withdrawStakeFieldValid {
    var value = _withdrawStakeAmountController.value;
    return value != null && value <= (widget.currentStake ?? tokenType.zero);
  }

  bool get _targetFieldValid {
    return _targetController.value != null;
  }

  void _withdrawStake() async {
    final amount = _withdrawStakeAmountController.value;
    final index = _indexController.intValue;
    final target = _targetController.value;

    if (amount == null || amount.lteZero() || index == null || target == null) {
      throw Exception('Invalid state for withdraw funds');
    }

    setState(() {
      txPending = true;
    });
    try {
      var txHashes =
          await OrchidWeb3StakeV0(web3Context!).orchidStakeWithdrawFunds(
        index: index,
        amount: amount,
        target: target,
      );

      UserPreferencesDapp()
          .addTransactions(txHashes.map((hash) => DappTransaction(
                transactionHash: hash,
                chainId: web3Context!.chain.chainId, // always Ethereum
                type: DappTransactionType.withdrawFunds,
              )));

      _withdrawStakeAmountController.clear();
      setState(() {});
    } catch (err) {
      log('Error on withdraw funds: $err');
    }
    setState(() {
      txPending = false;
    });
  }
}
