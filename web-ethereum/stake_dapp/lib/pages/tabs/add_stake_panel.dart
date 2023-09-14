import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:orchid/dapp/orchid/dapp_button.dart';
import 'package:orchid/dapp/orchid/dapp_tab_context.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/stake_dapp/orchid_web3_stake_v0.dart';

class AddStakePanel extends StatefulWidget {
  final OrchidWeb3Context? web3context;
  final EthereumAddress? stakee;
  final Token? currentStake;
  final USD? price;
  final bool enabled;

  const AddStakePanel({
    super.key,
    required this.web3context,
    required this.stakee,
    required this.currentStake,
    required this.price,
    required this.enabled,
  });

  @override
  State<AddStakePanel> createState() => _AddStakePanelState();
}

class _AddStakePanelState extends State<AddStakePanel>
    with DappTabWalletContext {
  OrchidWeb3Context? get web3Context => widget.web3context;

  late TypedTokenValueFieldController _addToStakeAmountController;

  @override
  TokenType get tokenType => Tokens.OXT;

  @override
  void initState() {
    super.initState();
    _addToStakeAmountController = TypedTokenValueFieldController(
        type: tokenType, listener: _formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          label: "Add to Stake",
          type: Tokens.OXT,
          controller: _addToStakeAmountController,
          error: _addStakeFieldError,
          usdPrice: widget.price,
        ).top(32).padx(8),
        Text("Delay is zero").white.caption.top(16),
        DappButton(
          text: s.addFunds,
          onPressed: _formEnabled ? _addStake : null,
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
        _addStakeFieldValid &&
        _addToStakeAmountController.value!.gtZero();
  }

  bool get _addStakeFieldError {
    return walletBalanceOf(tokenType) != null && !_addStakeFieldValid;
  }

  bool get _addStakeFieldValid {
    var value = _addToStakeAmountController.value;
    return value != null &&
        value <= (walletBalanceOf(tokenType) ?? tokenType.zero);
  }

  void _addStake() async {
    final stakee = widget.stakee;
    final wallet = web3Context?.wallet;
    final amount = _addToStakeAmountController.value;
    if (wallet == null ||
        stakee == null ||
        amount == null ||
        amount.lteZero()) {
      throw Exception('Invalid state for add funds');
    }

    setState(() {
      txPending = true;
    });
    try {
      var txHashes = await OrchidWeb3StakeV0(web3Context!).orchidStakePushFunds(
        wallet: wallet,
        stakee: stakee,
        amount: amount,
      );

      UserPreferencesDapp()
          .addTransactions(txHashes.map((hash) => DappTransaction(
                transactionHash: hash,
                chainId: web3Context!.chain.chainId, // always Ethereum
                type: DappTransactionType.addFunds,
              )));

      _addToStakeAmountController.clear();
      setState(() {});
    } catch (err) {
      log('Error on add funds: $err');
    }
    setState(() {
      txPending = false;
    });
  }
}
