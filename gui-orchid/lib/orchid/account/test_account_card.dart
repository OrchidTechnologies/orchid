import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/orchid/test_app.dart';
import 'account_card.dart';
import '../../api/orchid_eth/orchid_account_detail.dart';

// Note: This redundant import of material is required in the main dart file.
import 'package:flutter/material.dart';

void main() async {
  TestApp.run(scale: 1.0, content: _Test());
}

class _Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<_Test> {
  late AccountDetail account;
  bool active1 = true;

  @override
  void initState() {
    super.initState();

    account = MockAccountDetail.fromMock(AccountMock.account1xdai);
    // account = MockAccountDetail.fromMock(AccountMock.account1xdaiUnlocking);
    // account = MockAccountDetail.fromMock(AccountMock.account1xdaiUnlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Center(child: NeonOrchidLogo()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // full
              AccountCard(
                initiallyExpanded: true,
                accountDetail: account,
                // active: true,
                // selected: active1,
                onSelected: () {
                  setState(() {
                    active1 = !active1;
                  });
                },
              ),

              AccountCard(
                initiallyExpanded: false,
                accountDetail: account,
              ).top(40),

              // no account
              AccountCard(
                initiallyExpanded: false,
                accountDetail: null,
              ).top(40),

              // partial account
              AccountCard(
                initiallyExpanded: false,
                accountDetail: null,
                partialAccountFunderAddress: account.funder,
                // partialAccountSignerAddress: account.signerAddress,
              ).top(40),

            ],
          ),
        ),
      ],
    );
  }
}
