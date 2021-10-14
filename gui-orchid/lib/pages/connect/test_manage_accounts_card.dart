import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/openvpn_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/circuit/model/wireguard_hop.dart';
import 'package:orchid/util/on_off.dart';
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
  Circuit circuit = Circuit([]);

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    var account = Account(
      identityUid: "1234",
      chainId: Chains.XDAI_CHAINID,
      funder:
          EthereumAddress.from('0x6dd46C5F9f19AB8790F6249322F58028a3185087'),
      resolvedSignerAddress:
          EthereumAddress.from('0x45cC0D06CA2052Ef93b5B7adfeC2Af7690731110'),
    );
    var account2 = Account(
      identityUid: "1235",
      chainId: Chains.XDAI_CHAINID,
      funder:
          EthereumAddress.from('0x6dd46C5F9f19AB8790F6249322F58028a3185088'),
      resolvedSignerAddress:
          EthereumAddress.from('0x55cC0D06CA2052Ef93b5B7adfeC2Af7690731111'),
    );

    circuit = Circuit([
      OrchidHop.fromAccount(account),
      OrchidHop.fromAccount(account2),
      OpenVPNHop(userName: "Test", userPassword: "XXX", ovpnConfig: "XXX"),
      WireGuardHop(config: "XXX"),
    ]);
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
              OnOff(builder: (context, on) {
                return ManageAccountsCard(
                  circuit: circuit,
                  minHeight: false,
                  onManageAccountsPressed: () {
                    print("manage accounts");
                  },
                );
              }),
              // SizedBox(height: 50),
              // ManageAccountsCard(),
            ],
          ),
        ),
      ],
    );
  }
}
