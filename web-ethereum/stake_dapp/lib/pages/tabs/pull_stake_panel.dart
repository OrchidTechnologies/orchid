import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:orchid/dapp/orchid/dapp_button.dart';
import 'package:orchid/dapp/orchid/dapp_tab_context.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/stake_dapp/orchid_web3_stake_v0.dart';

class PullStakePanel extends StatefulWidget {
  final OrchidWeb3Context? web3context;
  final EthereumAddress? stakee;
  final Token? currentStake;
  final USD? price;
  final bool enabled;

  const PullStakePanel({
    super.key,
    required this.web3context,
    required this.stakee,
    required this.currentStake,
    required this.price,
    required this.enabled,
  });

  @override
  State<PullStakePanel> createState() => _PullStakePanelState();
}

class _PullStakePanelState extends State<PullStakePanel>
    with DappTabWalletContext {
  OrchidWeb3Context? get web3Context => widget.web3context;

  late TypedTokenValueFieldController _pullStakeAmountController;
  late NumericValueFieldController _indexController;

  @override
  TokenType get tokenType => Tokens.OXT;

  @override
  void initState() {
    super.initState();
    _pullStakeAmountController = TypedTokenValueFieldController(
        type: tokenType, listener: _formFieldChanged);
    _indexController =
        NumericValueFieldController.withListener(_formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrchidLabeledTokenValueField(
          enabled: widget.enabled,
          label: "Pull Stake",
          type: Tokens.OXT,
          controller: _pullStakeAmountController,
          error: _pullStakeFieldError,
          usdPrice: widget.price,
        ).top(32).padx(8),
        OrchidLabeledNumericField(
          enabled: widget.enabled,
          integer: true,
          label: "To Index",
          controller: _indexController,
          showPaste: false,
          backgroundColor: OrchidColors.dark_background_2,
        ).top(16).padx(8),
        DappButton(
          text: "PULL FUNDS",
          onPressed: _formEnabled ? _pullStake : null,
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
        _pullStakeFieldValid &&
        _pullStakeAmountController.value!.gtZero();
  }

  bool get _pullStakeFieldError {
    return walletBalanceOf(tokenType) != null && !_pullStakeFieldValid;
  }

  bool get _pullStakeFieldValid {
    var value = _pullStakeAmountController.value;
    return value != null &&
        value <= (widget.currentStake ?? tokenType.zero);
  }

  void _pullStake() async {
    final stakee = widget.stakee;
    final wallet = web3Context?.wallet;
    final amount = _pullStakeAmountController.value;
    final index = (_indexController.value ?? 0).toInt();

    if (wallet == null ||
        stakee == null ||
        amount == null ||
        amount.lteZero()) {
      throw Exception('Invalid state for pull funds');
    }

    setState(() {
      txPending = true;
    });
    try {
      var txHashes = await OrchidWeb3StakeV0(web3Context!).orchidStakePullFunds(
        stakee: stakee,
        amount: amount,
        index: index,
      );

      UserPreferencesDapp()
          .addTransactions(txHashes.map((hash) => DappTransaction(
                transactionHash: hash,
                chainId: web3Context!.chain.chainId, // always Ethereum
                type: DappTransactionType.pullFunds,
              )));

      _pullStakeAmountController.clear();
      setState(() {});
    } catch (err) {
      log('Error on pull funds: $err');
    }
    setState(() {
      txPending = false;
    });
  }
}
