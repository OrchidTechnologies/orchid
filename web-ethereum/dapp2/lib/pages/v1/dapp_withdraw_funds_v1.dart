import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/dapp_transaction.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/timed_builder.dart';
import 'package:orchid/util/units.dart';
import '../dapp_button.dart';
import '../orchid_form_fields.dart';
import 'package:orchid/common/token_price_builder.dart';

class WithdrawFundsPaneV1 extends StatefulWidget {
  final OrchidWeb3Context context;
  final EthereumAddress signer;
  final LotteryPot pot;
  final bool enabled;

  WithdrawFundsPaneV1({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
    this.enabled,
  }) : super(key: key) {
    // TESTING
    // this.signer = AccountMock.account1xdai.signerAddress;
    // this.pot = AccountMock.account1xdaiLocked.mockLotteryPot;
    // this.pot = AccountMock.account1xdaiUnlocked.mockLotteryPot;
    // this.pot = AccountMock.account1xdaiUnlocking.mockLotteryPot;
  }

  @override
  _WithdrawFundsPaneV1State createState() => _WithdrawFundsPaneV1State();
}

class _WithdrawFundsPaneV1State extends State<WithdrawFundsPaneV1> {
  final _balanceField = TokenValueFieldController();
  final _depositField = TokenValueFieldController();
  bool _txPending = false;

  LotteryPot get _pot {
    return widget.pot;
  }

  bool get _connected {
    return _pot != null && widget.signer != null;
  }

  @override
  void initState() {
    super.initState();
    _balanceField.addListener(_formFieldChanged);
    _depositField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  bool _unlockDeposit = false;

  @override
  Widget build(BuildContext context) {
    var tokenType = _pot?.balance?.type ?? Tokens.TOK;
    var buttonTitle =
        _unlockDeposit ? s.withdrawAndUnlockFunds : s.withdrawFunds;

    bool fullyUnlocked;
    String availableText;
    Token totalFunds;
    if (_connected) {
      totalFunds = _pot.balance + _pot.deposit;
      final maxWithdraw = _pot.maxWithdrawable;
      fullyUnlocked = maxWithdraw >= totalFunds;
      availableText = fullyUnlocked
          ? s.allOfYourFundsAreAvailableForWithdrawal
          : s.maxWithdrawOfYourTotalFundsCombinedFunds(
              maxWithdraw.formatCurrency(locale: context.locale),
              totalFunds.formatCurrency(locale: context.locale));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pady(16),
        if (_connected && totalFunds.gtZero())
          Text(availableText).title.bottom(24),
        TokenPriceBuilder(
            tokenType: tokenType,
            seconds: 30,
            builder: (USD tokenPrice) {
              return Column(
                children: [
                  LabeledTokenValueField(
                    label: s.balance,
                    enabled: _connected,
                    labelWidth: 100,
                    type: tokenType,
                    controller: _balanceField,
                    usdPrice: tokenPrice,
                  ),
                  LabeledTokenValueField(
                    label: s.deposit,
                    trailing: _depositLockIndicator(),
                    bottomBanner: _depositBottomBanner(),
                    enabled: _connected && _pot.isUnlocked,
                    labelWidth: 100,
                    type: tokenType,
                    controller: _depositField,
                    usdPrice: tokenPrice,
                  ).top(16),
                ],
              );
            }),
        if (_connected && _pot.deposit > _pot.unlockedAmount)
          _buildUnlockDepositCheckbox(context).top(8),
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
        // if (_connected) _buildInstructions(fullyUnlocked),
      ],
    );
  }

  bool get _showDepositBottomBanner {
    return _unlockDeposit || (_connected && _pot.isUnlocking);
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
    if (_connected && _pot.isUnlocking) {
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
                    _pot.unlockTime.toCountdownString(),
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
    if (!_connected) {
      return Container();
    }
    return _pot.isLocked
        ? Row(
            children: [
              Icon(
                Icons.lock,
                color: OrchidColors.status_yellow,
                size: 18,
              ),
              Text("Locked")
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
    final active = _connected;
    if (!active || _pot.isWarned) {
      return Container();
    }
    final style = OrchidText.body2.activeIf(active);

    return RoundedRect(
      backgroundColor: OrchidColors.dark_background_2,
      radius: 12,
      child: Column(
        children: [
          Text("To withdraw your deposit, you'll need to unlock it which takes 24 hours.")
              .withStyle(style)
              .padx(16)
              .top(16),
          Row(
            children: [
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
                  },
                ),
              ),
              Text("Unlock deposit").withStyle(style).height(1.7).left(8),
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
    return _connected &&
        !_txPending &&
        _balanceFormValid &&
        _depositFormValid &&
        _netWithdraw.gtZero() &&
        _netWithdraw <= _pot.maxWithdrawable;
  }

  bool get _balanceFormValid {
    log("XXX: _pot = ${_pot.balance}, field.value = ${_balanceField?.value}");
    return _balanceField.value <= _pot.balance;
  }

  bool get _depositFormValid {
    return _depositField.value <= _pot.unlockedAmount;
  }

  Token get _netWithdraw {
    return _balanceField.value + _depositField.value;
  }

  void _withdrawFunds() async {
    var withdrawBalance = Token.min(_balanceField.value, _pot.balance);
    var withdrawDeposit = Token.min(_depositField.value, _pot.unlockedAmount);

    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context).orchidWithdrawFunds(
        pot: _pot,
        signer: widget.signer,
        withdrawBalance: withdrawBalance,
        withdrawEscrow: withdrawDeposit,
        warnDeposit: _unlockDeposit,
      );
      UserPreferences().addTransaction(DappTransaction(
          transactionHash: txHash, chainId: widget.context.chain.chainId));
      _balanceField.clear();
      _depositField.clear();
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
    _balanceField.removeListener(_formFieldChanged);
    _depositField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
