import 'dart:async';
import 'dart:ui';
import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_eth.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/util/units.dart';

import '../app_routes.dart';

class ConnectStatusPanel extends StatefulWidget {
  final bool darkBackground;

  const ConnectStatusPanel({
    Key key,
    @required this.darkBackground,
  }) : super(key: key);

  @override
  _ConnectStatusPanelState createState() => _ConnectStatusPanelState();
}

class _ConnectStatusPanelState extends State<ConnectStatusPanel> {
  List<StreamSubscription> _subs = [];
  Account _activeAccount;
  LotteryPot _pot;
  MarketConditions _marketConditions;
  USD _bandwidthPrice;
  Timer _balanceTimer;

  // TODO: Simplify this for V1: Publish the active account and pot info
  // TODO: or move it to a context provider.
  @override
  void initState() {
    super.initState();
    _subs.add(
      UserPreferences().activeAccounts.stream().listen((accounts) {
        _activeAccount = accounts.isEmpty || accounts[0].isIdentityPlaceholder
            ? null
            : accounts[0];
        _update();
      }),
    );

    const pollingPeriod = Duration(seconds: 15);
    _balanceTimer = Timer.periodic(pollingPeriod, (_) {
      _update();
    });
    _update(); // kick one off immediately
  }

  void _update() async {
    // Fetch pot balance
    if (_activeAccount != null) {
      try {
        var signer = await Account.getSigner(_activeAccount);
        var eth = OrchidEthereum(_activeAccount.chain);
        _pot = await eth.getLotteryPot(_activeAccount.funder, signer);
        _marketConditions = await eth.getMarketConditions(_pot);
        // TEST: show badge
        // _marketConditions = MarketConditions(null, 0.1, false);
      } catch (err) {
        log("error fetching pot: $err");
      }
    }

    // Fetch bandwidth price
    try {
      _bandwidthPrice = await OrchidEthereumV1.getBandwidthPrice();
    } catch (err) {
      log("error fetching bw price: $err");
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _activeAccount == null ? Container() : buildView();
  }

  Widget buildView() {
    var chainIcon = _activeAccount.chain.icon;
    // var balanceString = "10 xDai";
    var balanceString =
        _pot != null ? _pot.balance.formatCurrency(digits: 2) : "...";

    // TODO: localize bandwidth price
    var bandwidthCostString = _bandwidthPrice != null
        ? '\$' + formatCurrency(_bandwidthPrice.value)
        : "...";

    var textColor =
        widget.darkBackground ? AppColors.purple_5 : AppColors.neutral_3;
    var textStyle = TextStyle(color: textColor, fontSize: 13);
    var valueColor =
        widget.darkBackground ? AppColors.teal_5 : AppColors.neutral_3;
    var valueStyle = TextStyle(color: valueColor, fontSize: 18);
    var imageSize = 42.0;
    var bgColor = Colors.transparent;
    var borderColor = AppColors.purple_4;

    // TODO: Configurable efficiency setting
    var showBadge =
        _marketConditions != null && _marketConditions.efficiency <= 0.2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: FittedBox(
          child: Container(
            height: 72,
            child: FlatButton(
                color: bgColor,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: borderColor, width: 2.2),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.identity);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Balance
                    Row(
                      children: [
                        Container(
                            child: chainIcon,
                            width: imageSize,
                            height: imageSize),
                        padx(10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Badge(
                                showBadge: showBadge,
                                position:
                                    BadgePosition.bottomEnd(bottom: -3, end: -25),
                                elevation: 0,
                                badgeContent: Text('!',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                padding: EdgeInsets.all(8),
                                toAnimate: false,
                                child: Text("Balance", style: textStyle)),
                            Container(
                                width: 80,
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(balanceString,
                                        textAlign: TextAlign.left,
                                        style: valueStyle))),
                          ],
                        ),
                      ],
                    ),
                    
                    padx(8),

                    // Bandwidth Rate
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/icon_speed-meter-outline.svg',
                          width: imageSize,
                          height: imageSize,
                          color: textColor,
                        ),
                        padx(16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.of(context).bandwidthCost, style: textStyle),
                            Container(
                                width: 80,
                                child:
                                    Text(bandwidthCostString, style: valueStyle)),
                          ],
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    _subs.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
  }
}
