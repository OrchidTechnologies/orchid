import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v0/orchid_web3_v0.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import '../account_manager/account_detail_poller.dart';
import '../dapp_add_funds.dart';

/// The tabs for interacting with the V0 contract.
class DappTabsV0 extends StatefulWidget {
  final OrchidWeb3Context web3Context;
  final EthereumAddress signer;
  final AccountDetail accountDetail;

  const DappTabsV0({
    Key key,
    @required this.web3Context,
    @required this.signer,
    @required this.accountDetail,
  }) : super(key: key);

  @override
  State<DappTabsV0> createState() => _DappTabsV0State();
}

class _DappTabsV0State extends State<DappTabsV0> {

  OrchidWeb3V0 v0;

  @override
  void initState() {
    super.initState();
    v0 = OrchidWeb3V0(widget.web3Context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1000,
      child: DefaultTabController(
        initialIndex: 0,
        length: 1,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: AppBar(
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                indicatorColor: OrchidColors.tappable,
                tabs: [
                  Tab(child: Text("ADD FUNDS").button),
                  // Tab(child: Text("WITHDRAW FUNDS").button),
                  // Tab(child: Text("ADVANCED").button),
                ],
              ),
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
                        context: widget.web3Context,
                        signer: widget.signer,
                        tokenType: v0.fundsTokenType,
                        addFunds: v0.orchidAddFunds,
                      ),
                    )),
              ),
              /*
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                      width: 500,
                      child: WithdrawFundsPane(
                        context: web3Context,
                        pot: accountDetail?.lotteryPot,
                        signer: signer,
                        onTransaction: onTransaction,
                      ),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                      width: 500,
                      child: AdvancedFundsPane(
                        // the warn value is captured for the warn field
                        key: Key(accountDetail?.lotteryPot?.toString() ?? ''),
                        context: web3Context,
                        pot: accountDetail?.lotteryPot,
                        signer: signer,
                        onTransaction: onTransaction,
                      ),
                    )),
              ),
               */
            ],
          ),
        ),
      ),
    );
  }
}
