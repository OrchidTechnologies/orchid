import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/test_app.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/orchid/account/account_selector.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
export 'package:orchid/common/app_sizes.dart';

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
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();

    // TEST account config text: random, not real accounts.
    final config = 'accounts=[ '
        '{ funder: "0x6dd46c5f9f19ab8790f6249322f58028a3185087", secret: "3d15ba96c0aa8eff04f6df30d5e2d03f63c288d37dd5bef5c370274f9b76c747", chainid: 100, version: 1 },'
        '{ funder: "0x7dd46c5f9f19ab8790f6249322f58028a3185087", secret: "c1f10dcf9133671051065231311315270ecd04cc5545fc3a151504bcb9d7813e", chainid: 100, version: 1 }, '
        '{ funder: "0x8dd46c5f9f19ab8790f6249322f58028a3185087", secret: "c1f10dcf9133671051065231311315270ecd04cc5545fc3a151504bcb9d7813e", chainid: 100, version: 1 }, '
        '{ funder: "0x8dd46c5f9f19ab8790f6249322f58028a3185087", secret: "c1f10dcf9133671051065231311315270ecd04cc5545fc3a151504bcb9d7813e", chainid: 100, version: 1 }, '
        ']';
    _accounts = OrchidAccountImport.parse(config).accounts ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OrchidActionButton(
        text: "Show Dialog",
        onPressed: _showDialog,
        enabled: true,
      ),
    );
  }

  void _showDialog() {
    AccountSelectorDialog.show(
      context: context,
      accounts: _accounts,
      onSelectedAccounts: (Set<Account> selected) {
        log("XXX: selectedAccountsChanged: $selected");
      },
    );
  }
}
