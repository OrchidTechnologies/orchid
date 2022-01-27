import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/pages/v1/dapp_withdraw_funds_v1.dart';
import '../dapp_add_funds.dart';
import 'dapp_advanced_funds_v1.dart';
import 'package:orchid/util/localization.dart';

/// The tabs for interacting with the V1 contract.
class DappTabsV1 extends StatefulWidget {
  final OrchidWeb3Context web3Context;
  final EthereumAddress signer;
  final AccountDetail accountDetail;

  const DappTabsV1({
    Key key,
    @required this.web3Context,
    @required this.signer,
    @required this.accountDetail,
  }) : super(key: key);

  @override
  State<DappTabsV1> createState() => _DappTabsV1State();
}

class _DappTabsV1State extends State<DappTabsV1> {
  OrchidWeb3V1 v1;

  @override
  void initState() {
    super.initState();
    v1 = OrchidWeb3V1(widget.web3Context);
  }

  OrchidWallet get wallet {
    return widget.web3Context.wallet;
  }

  @override
  Widget build(BuildContext context) {
    // var tabStyle = OrchidText.button.copyWith(fontSize: 16);
    var tabStyle = OrchidText.button;
    return SizedBox(
      height: 1000,
      width: 650,
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: AppBar(
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                indicatorColor: OrchidColors.tappable,
                tabs: [
                  Tab(child: FittedBox(child: Text(s.addFunds, style: tabStyle))),
                  Tab(child: FittedBox(child: Text(s.withdrawFunds, style: tabStyle))),
                  Tab(child: FittedBox(child: Text(s.advanced, style: tabStyle))),
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
                    tokenType: v1.fundsTokenType,
                    addFunds: v1.orchidAddFunds,
                  ),
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 500,
                  child: WithdrawFundsPaneV1(
                    context: widget.web3Context,
                    pot: widget.accountDetail?.lotteryPot,
                    signer: widget.signer,
                  ),
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                    child: SizedBox(
                  width: 650,
                  child: AdvancedFundsPaneV1(
                    // The warn value is captured statefully in the warn field
                    // Maybe find a cleaner way to deal with this.
                    key:
                        Key(widget.accountDetail?.lotteryPot?.toString() ?? ''),
                    context: widget.web3Context,
                    pot: widget.accountDetail?.lotteryPot,
                    signer: widget.signer,
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
