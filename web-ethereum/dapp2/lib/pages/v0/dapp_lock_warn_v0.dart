import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/pages/account_manager/account_card.dart';
import '../dapp_button.dart';

class LockWarnPaneV0 extends StatefulWidget {
  final OrchidWeb3Context context;
  final LotteryPot pot;
  final EthereumAddress signer;

  const LockWarnPaneV0({
    Key key,
    @required this.context,
    @required this.pot,
    @required this.signer,
  }) : super(key: key);

  @override
  _LockWarnPaneV0State createState() => _LockWarnPaneV0State();
}

class _LockWarnPaneV0State extends State<LockWarnPaneV0> {
  bool _txPending = false;

  LotteryPot get pot {
    return widget.pot;
  }

  @override
  void initState() {
    super.initState();
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (pot?.balance == null) {
      return Container();
    }
    var statusText = pot.isUnlocked
        ? "Your deposit of ${pot.warned.formatCurrency()} is unlocked."
        : "Your deposit of ${pot.deposit.formatCurrency()} is ${pot.isUnlocking ? 'unlocking' : 'locked'}.";
    statusText += pot.isUnlocking
        ? "\nThe funds will be available for withdrawal in ${pot.unlockInString()}."
        : '';

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
            if (pot.isUnlocked || pot.isUnlocking)
              DappButton(
                  text: "LOCK DEPOSIT",
                  onPressed: _formEnabled()
                      ? () {
                          _lockOrUnlock(lock: true);
                        }
                      : null)
            else
              DappButton(
                  text: "UNLOCK DEPOSIT",
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
    return !_txPending;
  }

  void _lockOrUnlock({bool lock}) async {
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V0(widget.context).orchidLockOrWarn(
        isLock: lock,
        signer: widget.signer,
      );
      UserPreferences().addTransaction(txHash);
      setState(() {});
    } catch (err) {
      log("Error on move funds: $err");
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
