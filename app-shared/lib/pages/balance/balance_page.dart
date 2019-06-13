import 'package:flutter/material.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class BalancePage extends StatefulWidget {
  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Balance", child: buildPage(context));
  }

  @override
  Widget buildPage(BuildContext context) {}
}
