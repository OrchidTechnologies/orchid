import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import '../../dapp/orchid/dapp_button.dart';
import 'package:orchid/util/localization.dart';

class LockWarnPaneV0 extends StatefulWidget {
  final OrchidWeb3Context? context;
  final LotteryPot? pot;
  final EthereumAddress? signer;
  final bool enabled;

  const LockWarnPaneV0({
    Key? key,
    required this.context,
    required this.pot,
    required this.signer,
    this.enabled = false,
  }) : super(key: key);

  @override
  _LockWarnPaneV0State createState() => _LockWarnPaneV0State();
}

class _LockWarnPaneV0State extends State<LockWarnPaneV0> {
  bool _txPending = false;

  LotteryPot? get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    var statusText = '';
    var isUnlockedOrUnlocking = false;
    if (pot != null) {
      statusText = pot!.isUnlocked
          ? s.yourDepositOfAmountIsUnlocked(
              pot!.warned.formatCurrency(locale: context.locale))
          : s.yourDepositOfAmountIsUnlockingOrUnlocked(
              pot!.deposit.formatCurrency(locale: context.locale),
              pot!.isUnlocking ? s.unlocking : s.locked);
      statusText += pot!.isUnlocking
          ? '\n' +
              s.theFundsWillBeAvailableForWithdrawalInTime(pot!.unlockInString())
          : '';
      isUnlockedOrUnlocking = (pot!.isUnlocked || pot!.isUnlocking);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(statusText).subtitle.height(1.5).center),
          ],
        ),
        pady(32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUnlockedOrUnlocking)
              DappButton(
                  text: s.lockDeposit,
                  onPressed: _formEnabled()
                      ? () {
                          _lockOrUnlock(lock: true);
                        }
                      : null)
            else
              DappButton(
                  text: s.unlockDeposit,
                  onPressed: _formEnabled()
                      ? () {
                          _lockOrUnlock(lock: false);
                        }
                      : null),
          ],
        ),
      ],
    );
  }

  bool _formEnabled() {
    return pot != null && !_txPending;
  }

  void _lockOrUnlock({required bool lock}) async {
    if (widget.context == null || widget.signer == null) {
      throw Exception('Context or signer is null');
    }
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context!).orchidLockOrWarn(
        isLock: lock,
        signer: widget.signer!,
      );
      UserPreferencesDapp().addTransaction(DappTransaction(
        transactionHash: txHash,
        chainId: widget.context!.chain.chainId,
        type: lock
            ? DappTransactionType.lockDeposit
            : DappTransactionType.unlockDeposit,
      ));
      setState(() {});
    } catch (err) {
      log('Error on move funds: $err');
    }
    setState(() {
      _txPending = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
