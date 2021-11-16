import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/pages/account_manager/account_detail_poller.dart';
import 'package:orchid/util/test_app.dart';
import 'account_card.dart';

void main() {
  runApp(TestApp(scale: 1.0, content: _Test()));
}

class _Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<_Test> {
  AccountDetailPoller account;
  bool active1 = true;
  bool active2 = false;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    var signer = "0x45cC0D06CA2052Ef93b5B7adfeC2Af7690731110";
    var funder = "0x7dFae1C74a946FCb50e7376Ff40fe2Aa3A2F9B2b";
    account = AccountDetailPoller(
      account: Account.fromSignerAddress(
        chainId: Chains.XDAI_CHAINID,
        funder: EthereumAddress.from(funder),
        signerAddress: EthereumAddress.from(signer),
      ),
    );
    await account.pollOnce();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(child: NeonOrchidLogo()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AccountCard(
                accountDetail: account,
                selected: active1,
                onSelected: () {
                  setState(() {
                    active1 = !active1;
                  });
                },
              ),
              SizedBox(height: 50),
              AccountCard(
                accountDetail: account,
                selected: active2,
                onSelected: () {
                  setState(() {
                    active2 = !active2;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
