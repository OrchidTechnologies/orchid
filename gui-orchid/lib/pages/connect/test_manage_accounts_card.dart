import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/pages/account_manager/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/util/test_app.dart';
import 'manage_accounts_card.dart';

void main() {
  runApp(TestApp(content: _AccountCardTest()));
}

class _AccountCardTest extends StatefulWidget {
  @override
  __AccountCardTestState createState() => __AccountCardTestState();
}

class __AccountCardTestState extends State<_AccountCardTest> {
  AccountDetailPoller account;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    account = AccountDetailPoller(
        account: Account(
          identityUid: null,
          chainId: Chains.XDAI_CHAINID,
          funder: EthereumAddress.from(
              '0x6dd46C5F9f19AB8790F6249322F58028a3185087'),
        ),
        resolvedSigner:
            EthereumAddress.from('0x45cC0D06CA2052Ef93b5B7adfeC2Af7690731110'));
    await account.refresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(alignment: Alignment.topCenter, child: NeonOrchidLogo()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ManageAccountsCard(accountDetail: account),
              SizedBox(height: 50),
              ManageAccountsCard(),
            ],
          ),
        ),
      ],
    );
  }
}
