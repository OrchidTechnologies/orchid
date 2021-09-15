import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/util/units.dart';
import '../account_manager/account_detail_poller.dart';
import '../../orchid/orchid_circular_identicon.dart';
import '../../orchid/orchid_panel.dart';
import '../../orchid/orchid_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Active account info and "manage accounts" button used on the connect page.
class ManageAccountsCard extends StatelessWidget {
  final AccountDetail accountDetail;
  final bool minHeight;

  const ManageAccountsCard({
    Key key,
    this.accountDetail,
    this.minHeight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: minHeight? 174 : 180,
      child: Stack(
        children: [
          Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                  width: 312,
                  height: 150,
                  child: OrchidPanel(
                      child: Center(
                          child: Padding(
                    padding: const EdgeInsets.only(top: 17.0),
                    child: _buildCardContent(context),
                  ))))),
          Align(
            alignment: Alignment.topCenter,
            child: OrchidCircularIdenticon(
              address: accountDetail?.signer,
              size: minHeight ? 48 : 60,
            ),
          ),
        ],
      ),
    );
  }

  Column _buildCardContent(BuildContext context) {
    S s = S.of(context);
    final text = accountDetail == null
        ? s.noAccountSelected
        : accountDetail.signer.toString();
    final textWidth = accountDetail == null ? null : 120.0;
    final balanceText = accountDetail == null
        ? formatCurrency(0.0, digits: 2)
        : (accountDetail.lotteryPot?.balance?.formatCurrency(digits: 2) ??
            "...");
    final efficiency = accountDetail?.marketConditions?.efficiency;
    var showBadge = (accountDetail?.marketConditions?.efficiency ?? 1.0) <
        MarketConditions.minEfficiency;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 20,
          width: textWidth,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: OrchidText.body2,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (efficiency != null) padx(16.0 + 16.0),
            SizedBox(
              height: 24,
              child: Text(
                balanceText,
                style: OrchidText.highlight,
              ),
            ),
            if (efficiency != null) ...[
              padx(16),
              OrchidCircularEfficiencyIndicators.small(efficiency),
            ],
          ],
        ),
        SizedBox(height: 16),
        Badge(
          showBadge: showBadge,
          elevation: 0,
          badgeContent: Text('!', style: OrchidText.caption),
          padding: EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 8),
          toAnimate: false,
          position: BadgePosition.topEnd(top: -8, end: -34),
          child: SizedBox(
            height: 16,
            child: Text(
              s.manageAccounts.toUpperCase(),
              style: OrchidText.button
                  .copyWith(color: OrchidColors.purple_ffb88dfc, height: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
