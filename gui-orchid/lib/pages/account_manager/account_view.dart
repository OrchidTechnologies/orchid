import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/common/alert_badge.dart';
import 'package:orchid/common/account_chart.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/common/titled_page_base.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/util/listenable_builder.dart';

import '../../common/app_sizes.dart';
import '../../common/app_text.dart';
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
    return TitledPage(
      title: S.of(context).accountView,
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
                    child: _buildBottom(),
                  )
                ],
              ),
            );
          }),
    );
  }

  Widget _buildBottom() {
    return RefreshIndicator(
      onRefresh: _detail.refresh,
      child: Container(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(children: [
              pady(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalance(),
                ],
              ),
              pady(8),
              Divider(),
              pady(24),
              if (_showAccountChart())
                Container(width: 250, child: _buildAccountChart()),
              // if (_showAccountChart()) pady(24),
              // _buildAddFundsButton(),
              pady(32),
              if (_alert) _buildLowEfficiencyText()
            ]),
          ),
        ),
      ),
    );
  }

  bool get _alert {
    return _detail.showMarketStatsAlert;
  }

  Column _buildBalance() {
    var style1 = TextStyle(
      fontSize: 17,
      color: _alert ? Colors.red.shade900 : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_alert)
              SizedAlertBadge(
                  visible: _alert, size: 26, insets: 6, maintainSize: false),
            if (_alert) padx(8),
            LabeledCurrencyValue(
                label: s.balance + ':',
                style: style1,
                value: _detail.lotteryPot?.balance),
          ],
        ),
        // The badge still has outside padding (fix this)
        if (_alert) pady(4) else pady(8),
        Row(
          children: [
            if (_alert)
              SizedAlertBadge(
                  visible: _alert, size: 26, insets: 6, maintainSize: false),
            if (_alert) padx(8),
            LabeledCurrencyValue(
                label: s.deposit + ':',
                style: style1,
                value: _detail.lotteryPot?.deposit),
          ],
        ),
      ],
    );
  }

  Widget _buildLowEfficiencyText() {
    var bodyStyle = TextStyle(
      // color: Colors.black,
      fontSize: 15,
      height: 1.3,
      // fontStyle: FontStyle.italic,
    );
    var titleStyle = bodyStyle.copyWith(
      fontWeight: FontWeight.bold,
      // height: 2.0,
    );
    var linkStyle = AppText.linkStyle.copyWith(
      fontSize: 15.0,
      // height: 1.3,
      // fontStyle: FontStyle.italic,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Efficiency too low', style: titleStyle),
        pady(8),
        Text(
            'Your access to the Orchid network is currently limited by your efficiency.',
            style: bodyStyle),
        pady(8),
        LinkText('What is efficiency?',
            style: linkStyle, url: OrchidUrls.accountOrchid),
      ],
    );
    /*
    return StyledText(
      style: bodyStyle,
      newLineAsBreaks: true,
      text: '<title>Efficiency too low</title>\n'
          'Your access to the Orchid network is currently limited by your efficiency.\n'
          '<link1>What is efficiency?</link1>',
      styles: {
        'title': titleStyle,
        'link1': linkStyle.link(OrchidUrls.accountOrchid),
      },
    );
     */
  }

  bool get _active {
    return widget.account.active || _activated;
  }

  Widget _buildActivateButton() {
    return Container(
      width: 100,
      child: RoundedRectButton(
        text: s.activate,
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
      alert: _alert,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  S get s {
    return S.of(context);
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
