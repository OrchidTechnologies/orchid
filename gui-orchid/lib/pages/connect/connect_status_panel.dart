import 'dart:ui';
import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/pages/account_manager/account_detail_poller.dart';
import 'package:orchid/util/units.dart';

import '../app_routes.dart';

class ConnectStatusPanel extends StatelessWidget {
  final bool darkBackground;
  final AccountDetail data;
  final USD bandwidthPrice;

  const ConnectStatusPanel({
    Key key,
    @required this.darkBackground,
    @required this.data,
    @required this.bandwidthPrice,
  }) : super(key: key);

  Widget build(BuildContext context) {
    var chainIcon = data.account.chain.icon;
    // var balanceString = "10 xDai";
    var balanceString = data.lotteryPot != null
        ? data.lotteryPot.balance.formatCurrency(digits: 2)
        : "...";

    var bandwidthCostString = bandwidthPrice != null
        ? '\$' + formatCurrency(bandwidthPrice.value)
        : "...";

    var textColor = darkBackground ? AppColors.purple_5 : AppColors.neutral_3;
    var textStyle = TextStyle(color: textColor, fontSize: 13);
    var valueColor = darkBackground ? AppColors.teal_5 : AppColors.neutral_3;
    var valueStyle = TextStyle(color: valueColor, fontSize: 18);
    var imageSize = 42.0;
    var bgColor = Colors.transparent;
    var borderColor = AppColors.purple_4;

    // Show balance badge on low efficiency
    // var showBalanceBadge = data.marketConditions != null &&
    //     data.marketConditions.efficiency <= MarketConditions.minEfficiency &&
    //     data.marketConditions.limitedByBalance;
    var showBalanceBadge = false;

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
                                showBadge: showBalanceBadge,
                                position: BadgePosition.bottomEnd(
                                    bottom: -3, end: -25),
                                elevation: 0,
                                badgeContent: Text('!',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                padding: EdgeInsets.all(8),
                                toAnimate: false,
                                child: Text(S.of(context).balance,
                                    style: textStyle)),
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
                                child: Text(bandwidthCostString,
                                    style: valueStyle)),
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
}
