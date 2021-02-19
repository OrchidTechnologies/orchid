import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/pages/account_manager/account_composer.dart';
import 'package:orchid/pages/common/account_chart.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/tap_copy_text.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/util/listenable_builder.dart';

import '../app_sizes.dart';
import '../app_text.dart';
import 'account_model.dart';
import 'account_detail_poller.dart';

class AccountView extends StatefulWidget {
  final AccountModel account;
  final Function(AccountModel account) setActiveAccount;

  const AccountView(
      {Key key, @required this.account, @required this.setActiveAccount})
      : super(key: key);

  @override
  _AccountViewState createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {}

  bool _activated = false;

  AccountDetailPoller get _detail {
    return widget.account.detail;
  }

  Widget build(BuildContext context) {
    var style1 = TextStyle(fontSize: 18);
    return TitledPage(
      title: 'Account View',
      child: ListenableBuilder(
          listenable: _detail,
          builder: (context, snapshot) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    color: _active ? Colors.green.shade50 : null,
                    child: Column(
                      children: [
                        pady(16),
                        // Position the activate button on the header
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildHeader(),
                            Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: _buildActivateButton(),
                                )),
                          ],
                        ),
                        pady(24),
                      ],
                    ),
                  ),
                  Divider(height: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(children: [
                          pady(16),
                          LabeledCurrencyValue(
                              label: "Balance:",
                              style: style1,
                              value: _detail.lotteryPot?.balance),
                          pady(8),
                          LabeledCurrencyValue(
                              label: "Deposit:",
                              style: style1,
                              value: _detail.lotteryPot?.deposit),
                          pady(8),
                          Divider(),
                          pady(24),
                          if (_showAccountChart())
                            Container(width: 250, child: _buildAccountChart()),
                          if (_showAccountChart()) pady(24),
                          _buildAddFundsButton(),
                          pady(24),
                        ]),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }

  Widget _buildAddFundsButton() {
    return Container(
      width: 150,
      child: RoundedRectButton(
        text: "Add Funds",
        onPressed: _showPotComposer,
      ),
    );
  }

  bool get _active {
    return widget.account.active || _activated;
  }

  Widget _buildActivateButton() {
    return Container(
      width: 100,
      child: RoundedRectButton(
        text: "Activate",
        onPressed: _active
            ? null
            : () {
                widget.setActiveAccount(widget.account);
                setState(() {
                  _activated = true;
                });
              },
      ),
    );
  }

  void _showPotComposer() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return AccountComposerPage(widget.account.chain.nativeCurrency);
            }));
  }

  Widget _buildHeader() {
    var account = widget.account;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(account.chain.name, style: AppText.dialogTitle),
          Container(
            child: widget.account.chain.icon,
            width: 64,
            height: 64,
          ),
          Container(
            width:
                AppSize(context).widerThan(AppSize.iphone_12_max) ? null : 250,
            child: Center(
              child: TapToCopyText(
                account.funder.toString(),
                padding: EdgeInsets.zero,
                style: AppText.dialogTitle,
              ),
            ),
          )
        ]..spaced(16),
      ),
    );
  }

  bool _showAccountChart() {
    return _detail.marketConditions?.efficiency != null;
  }

  Widget _buildAccountChart() {
    log("ZZZ: build account chart: marketConditions = ${_detail.marketConditions}");
    return AccountChart(
      transactions: _detail.transactions,
      efficiency: _detail.marketConditions?.efficiency,
      lotteryPot: _detail.lotteryPot,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class LabeledCurrencyValue extends StatelessWidget {
  final String label;
  final TextStyle style;
  final Token value;

  const LabeledCurrencyValue({
    Key key,
    this.label,
    this.style,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var val = value != null ? value.formatCurrency(digits: 2) : "...";
    return Row(children: [
      Text(label, style: style),
      padx(4),
      Text(val, style: style.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}
