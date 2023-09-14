import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import '../dapp_add_funds.dart';
import 'dapp_lock_warn_v0.dart';
import 'dapp_move_funds_v0.dart';
import 'dapp_withdraw_funds_v0.dart';
import 'package:orchid/util/localization.dart';

/// The tabs for interacting with the V0 contract.
class DappTabsV0 extends StatefulWidget {
  final OrchidWeb3Context? web3Context;
  final EthereumAddress? signer;
  final AccountDetail? accountDetail;

  const DappTabsV0({
    Key? key,
    required this.web3Context,
    required this.signer,
    required this.accountDetail,
  }) : super(key: key);

  @override
  State<DappTabsV0> createState() => _DappTabsV0State();
}

class _DappTabsV0State extends State<DappTabsV0> {
  @override
  void initState() {
    super.initState();
  }

  bool get _enabled {
    return widget.web3Context != null && widget.signer != null;
  }

  @override
  Widget build(BuildContext context) {
    // var tabStyle = OrchidText.button.copyWith(fontSize: 16);
    var tabStyle = OrchidText.button;
    return SizedBox(
      height: 500,
      width: 700,
      child: DefaultTabController(
        initialIndex: 0,
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: TabBar(
              indicatorColor: OrchidColors.tappable,
              tabs: [
                Tab(child: FittedBox(child: Text(s.add1, style: tabStyle))),
                Tab(child: FittedBox(child: Text(s.withdraw, style: tabStyle))),
                Tab(child: FittedBox(child: Text(s.move).button)),
                Tab(child: FittedBox(child: Text(s.lockUnlock1).button)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 500,
                  child: AddFundsPane(
                    tokenType: Tokens.OXT,
                    enabled: _enabled,
                    context: widget.web3Context,
                    signer: widget.signer,
                    addFunds: _orchidAddFunds,
                  ),
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: WithdrawFundsPaneV0(
                  enabled: _enabled,
                  context: widget.web3Context,
                  pot: widget.accountDetail?.lotteryPot,
                  signer: widget.signer,
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: MoveFundsPaneV0(
                  enabled: _enabled,
                  context: widget.web3Context,
                  pot: widget.accountDetail?.lotteryPot,
                  signer: widget.signer,
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: LockWarnPaneV0(
                  enabled: _enabled,
                  context: widget.web3Context,
                  pot: widget.accountDetail?.lotteryPot,
                  signer: widget.signer,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Defers construction of the contract until needed
  Future<List<String> /*TransactionId*/ > _orchidAddFunds({
    required OrchidWallet? wallet,
    required EthereumAddress? signer,
    required Token addBalance,
    required Token addEscrow,
  }) async {
    if (widget.web3Context == null || signer == null || wallet == null) {
      throw Exception('No web3 context or null signer');
    }
    return OrchidWeb3V0(widget.web3Context!).orchidAddFunds(
      wallet: wallet,
      signer: signer,
      addBalance: addBalance,
      addEscrow: addEscrow,
    );
  }
}
