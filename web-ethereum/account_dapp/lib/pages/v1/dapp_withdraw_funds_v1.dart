import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/orchid/dapp_tab_context.dart';
import 'package:orchid/util/timed_builder.dart';
import 'package:orchid/api/pricing/usd.dart';
import '../../dapp/orchid/dapp_button.dart';
import '../../orchid/field/orchid_labeled_token_value_field.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';

class WithdrawFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context? context;
  final EthereumAddress? signer;
  final LotteryPot? pot;
  final bool enabled;

  WithdrawFundsPaneV1({
    Key? key,
    required this.context,
    required this.pot,
    required this.signer,
    this.enabled = false,
  }) : super(key: key) {
    // this.signer = AccountMock.account1xdai.signerAddress;
    // this.pot = AccountMock.account1xdaiLocked.mockLotteryPot;
    // this.pot = AccountMock.account1xdaiUnlocked.mockLotteryPot;
    // this.pot = AccountMock.account1xdaiUnlocking.mockLotteryPot;
  }

  @override
  _WithdrawFundsPaneV1State createState() => _WithdrawFundsPaneV1State();
}

class _WithdrawFundsPaneV1State extends State<WithdrawFundsPaneV1>
    with DappTabWalletContext, DappTabPotContext {
  OrchidWeb3Context? get web3Context => widget.context;

  LotteryPot? get pot => widget.pot;

  EthereumAddress? get signer => widget.signer;

  late TypedTokenValueFieldController _balanceField;
  late TypedTokenValueFieldController _depositField;
  bool _unlockDeposit = false;

  @override
  void initState() {
    super.initState();
    _balanceField = TypedTokenValueFieldController(type: tokenType);
    _balanceField.addListener(_formFieldChanged);
    _depositField = TypedTokenValueFieldController(type: tokenType);
    _depositField.addListener(_formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    var buttonTitle =
        _unlockDeposit ? s.withdrawAndUnlockFunds : s.withdrawFunds;
    if (_unlockDeposit && connected && _netWithdraw.isZero()) {
      buttonTitle = s.unlockDeposit;
    }

    bool fullyUnlocked;
    String? availableText;
    Token? totalFunds;
    // pot guarded by connected
    if (connected) {
      totalFunds = pot!.balance + pot!.deposit;
      final maxWithdraw = pot!.maxWithdrawable;
      fullyUnlocked = maxWithdraw >= totalFunds;
      availableText = fullyUnlocked
          ? s.allOfYourFundsAreAvailableForWithdrawal
          : s.maxWithdrawOfYourTotalFundsCombinedFunds(
              maxWithdraw.formatCurrency(locale: context.locale),
              totalFunds.formatCurrency(locale: context.locale));
    }
    bool showUnlock = connected && pot!.deposit > pot!.unlockedAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pady(16),
        if (connected && totalFunds!.gtZero())
          Text(availableText!).title.bottom(24),
        TokenPriceBuilder(
            tokenType: tokenType,
            seconds: 30,
            builder: (USD? tokenPrice) {
              return Column(
                children: [
                  OrchidLabeledTokenValueField(
                    label: s.balance,
                    enabled: connected,
                    labelWidth: 100,
                    type: tokenType,
                    controller: _balanceField,
                    usdPrice: tokenPrice,
                    error: _balanceFieldError,
                  ),
                  OrchidLabeledTokenValueField(
                    label: s.deposit,
                    trailing: _depositLockIndicator(),
                    bottomBanner: _depositBottomBanner(),
                    enabled: connected && (pot?.isUnlocked ?? false),
                    labelWidth: 100,
                    type: tokenType,
                    controller: _depositField,
                    usdPrice: tokenPrice,
                    error: _depositFieldError,
                  ).top(16),
                ],
              );
            }),
        if (showUnlock) _buildUnlockDepositCheckbox(context).top(8),
        pady(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: buttonTitle,
                onPressed: _formEnabled ? _withdrawFunds : null),
          ],
        ),
        // pady(32),
        // if (connected) _buildInstructions(fullyUnlocked),
      ],
    );
  }

  bool get _showDepositBottomBanner {
    return _unlockDeposit || (connected && pot!.isUnlocking);
  }

  Widget _depositBottomBanner() {
    return AnimatedVisibility(
        duration: millis(200),
        show: _showDepositBottomBanner,
        child: _depositBottomBannerImpl());
  }

  Widget _depositBottomBannerImpl() {
    final style = OrchidText.body1.black;
    if (_unlockDeposit) {
      return Row(
        children: [
          Text('Will be unlocked in 24 hours.')
              .withStyle(style)
              .top(8)
              .bottom(4)
              .padx(16),
        ],
      );
    }
    if (connected && pot!.isUnlocking) {
      return TimedBuilder.interval(
          seconds: 1,
          builder: (context) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time until unlocked').withStyle(style),
                SizedBox(
                  width: 70,
                  child: Text(
                    pot!.unlockTime.toCountdownString(),
                  ).withStyle(style),
                ),
              ],
            );
          }).top(8).bottom(4).padx(16);
    }

    return Container();
  }

  // The lock icon and text annotation on the deposit field
  Widget _depositLockIndicator() {
    if (!connected || pot!.deposit.isZero()) {
      return Container();
    }
    return pot!.isLocked
        ? Row(
            children: [
              Icon(
                Icons.lock,
                color: OrchidColors.status_yellow,
                size: 18,
              ),
              Text(s.locked1)
                  .body1
                  .copyWith(style: TextStyle(color: OrchidColors.status_yellow))
                  .left(12),
            ],
          )
        : Row(
            children: [
              Icon(
                Icons.lock_open,
                color: OrchidColors.status_green,
                size: 18,
              ),
              Text(s.unlocked)
                  .body1
                  .copyWith(style: TextStyle(color: OrchidColors.status_green))
                  .left(12),
            ],
          );
  }

  // The unlock checkbox and instructions shown when applicable
  Widget _buildUnlockDepositCheckbox(BuildContext context) {
    final active = connected;
    if (!active || pot!.isWarned) {
      return Container();
    }
    final style = OrchidText.body2.enabledIf(active);

    return RoundedRect(
      backgroundColor: OrchidColors.dark_background_2,
      radius: 12,
      child: Column(
        children: [
          Text('To withdraw your deposit the funds must be unlocked, which requires a waiting period of 24 hours.'
                  '  '
                  'Once the unlock is started you will no longer be able to use this account for payments until you re-lock or re-fund the account’s deposit.')
              .withStyle(style)
              .padx(16)
              .top(16),
          Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: Colors.white,
                  // toggleableActiveColor: OrchidColors.tappable,
                  // checkboxTheme: CheckboxThemeData(
                  //   checkColor: OrchidColors.tappable,
                  // )
                ),
                child: Checkbox(
                  value: _unlockDeposit,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _unlockDeposit = value;
                      });
                    }
                  },
                ),
              ),
              Text(s.unlockDeposit1).withStyle(style).height(1.7).left(8),
            ],
          ).top(8).left(8).bottom(8),
        ],
      ),
    );
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  bool get _formEnabled {
    // The normal condition for a withdrawal of funds
    bool validPositiveWithdrawal() =>
        _netWithdraw.gtZero() && _netWithdraw <= pot!.maxWithdrawable;

    // This allows unlocking without any actual withdrawal amount
    bool validZeroWithdrawal() => _netWithdraw.isZero() && _unlockDeposit;

    return connected &&
        !txPending &&
        _balanceFormValid &&
        _depositFormValid &&
        (validPositiveWithdrawal() || validZeroWithdrawal());
  }

  bool get _balanceFormValid {
    var value = _balanceField.value;
    return value != null && value <= pot!.balance;
  }

  bool get _balanceFieldError {
    return pot != null && !_balanceFormValid;
  }

  bool get _depositFormValid {
    var value = _depositField.value;
    return value != null && value <= pot!.unlockedAmount;
  }

  bool get _depositFieldError {
    return pot != null && !_depositFormValid;
  }

  Token get _netWithdraw {
    return _balanceField.value! + _depositField.value!;
  }

  void _withdrawFunds() async {
    if (widget.context == null || pot == null || signer == null) {
      throw Exception('Invalid state for withdraw funds');
    }
    var withdrawBalance = Token.min(_balanceField.value!, pot!.balance);
    var withdrawDeposit = Token.min(_depositField.value!, pot!.unlockedAmount);

    setState(() {
      txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context!).orchidWithdrawFunds(
        pot: pot!,
        signer: signer!,
        withdrawBalance: withdrawBalance,
        withdrawEscrow: withdrawDeposit,
        warnDeposit: _unlockDeposit,
      );
      UserPreferencesDapp().addTransaction(DappTransaction(
        transactionHash: txHash,
        chainId: widget.context!.chain.chainId,
        type: DappTransactionType.withdrawFunds,
      ));
      _balanceField.clear();
      _depositField.clear();
      _unlockDeposit = false;
      setState(() {});
    } catch (err) {
      log('Error on withdraw funds: $err');
    }
    setState(() {
      txPending = false;
    });
  }

  @override
  void dispose() {
    _balanceField.removeListener(_formFieldChanged);
    _depositField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
