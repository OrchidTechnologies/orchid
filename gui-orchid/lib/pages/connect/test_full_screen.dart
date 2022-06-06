import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/util/test_app.dart';
import 'manage_accounts_card.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DebugColor();
  }
}
