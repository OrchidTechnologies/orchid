import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/common/account_chart.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/util/units.dart';
import 'account_detail_poller.dart';
import '../../orchid/orchid_panel.dart';
import '../../orchid/orchid_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// The account cards used on the account manager
class AccountCard extends StatefulWidget {
  final AccountDetail accountDetail;

  // If non-null show the selected circle and checkmark for selection
  final bool selected;

  // If non-null designates the active / inactive status line.
  final bool active;

  // Callback for selection when selected is non-null.
  final VoidCallback onSelected;

  final bool initiallyExpanded;

  /// Produces a shorter card
  final bool minHeight;

  const AccountCard({
    Key key,
    this.accountDetail,
    this.active,
    this.selected,
    this.onSelected,
    this.initiallyExpanded = false,
    this.minHeight = false,
  }) : super(key: key);

  @override
  _AccountCardState createState() => _AccountCardState();

  static Widget iconForTokenType(TokenType t) {
    if (t == TokenTypes.ETH) {
      return Image.asset('assets/images/eth_token_icon.png', fit: BoxFit.fill);
    }
    if (t == TokenTypes.XDAI) {
      return Image.asset('assets/images/xdai_token_icon.png', fit: BoxFit.fill);
    }
    if (t == TokenTypes.OXT) {
      return SvgPicture.asset('assets/svg/oxt_token_icon.svg',
          fit: BoxFit.fill);
    }
    return null;
  }
}

class _AccountCardState extends State<AccountCard>
    with TickerProviderStateMixin {
  bool expanded;
  var expandDuration = const Duration(milliseconds: 330);
  AnimationController _gradientAnim;

  bool get _hasSelection {
    return widget.selected != null;
  }

  @override
  void initState() {
    super.initState();
    this.expanded = widget.initiallyExpanded;
    _gradientAnim =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
  }

  bool get short {
    return widget.minHeight;
  }

  @override
  Widget build(BuildContext context) {
    var height = short ? (expanded ? 360.0 : 74.0) : (expanded ? 360.0 : 116.0);
    var width = 334.0;
    var checkExtraHeight = _hasSelection ? 12.0 : 0.0;
    var checkExtraWidth = _hasSelection ? 16.0 : 0.0;
    return GestureDetector(
      onTap: () {
        setState(() {
          expanded = !expanded;
        });
      },
      child: Padding(
        // balance the selection button right
        padding: EdgeInsets.only(left: checkExtraWidth),
        child: AnimatedContainer(
            duration: expandDuration,
            height: height + checkExtraHeight, // padding for check button
            width: width + checkExtraWidth,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: checkExtraWidth, bottom: checkExtraHeight),
                    child: AnimatedBuilder(
                        animation: _gradientAnim,
                        builder: (context, snapshot) {
                          return OrchidPanel(
                              key: Key(widget.selected?.toString() ?? ''),
                              highlight: widget.active ?? false,
                              highlightAnimation: _gradientAnim.value,
                              child: _buildCardContent(context));
                        }),
                  ),
                ),
                // checkmark selection button
                if (_hasSelection)
                  Align(
                      alignment: Alignment.bottomRight,
                      child: _buildToggleButton(checked: widget.selected))
              ],
            )),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final efficiency = widget.accountDetail?.marketConditions?.efficiency;
    final tokenType = widget.accountDetail?.lotteryPot?.balance?.type;
    return Stack(
      fit: StackFit.expand,
      children: [
        // info column
        Padding(
          padding: EdgeInsets.only(top: short ? 18 : 28),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Token icon (aligned from top because this stays in the header when expanded)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 24.0, top: short ? 0 : 10),
                  child: _buildTokenIcon(tokenType),
                ),
              ),
              _buildInfoColumn(),
            ],
          ),
        ),

        // efficiency meter
        if (!expanded)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: _buildEfficiencyMeter(efficiency),
            ),
          ),
      ],
    );
  }

  AnimatedSwitcher _buildEfficiencyMeter(double efficiency) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      child: Container(
        key: Key((efficiency != null).toString()),
        child: efficiency != null && !expanded
            ? OrchidCircularEfficiencyIndicators.medium(efficiency)
            : Container(width: 40, height: 40),
      ),
    );
  }

  Widget _buildTokenIcon(TokenType tokenType) {
    var size = 40.0;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      child: SizedBox(
          key: Key(tokenType?.toString() ?? "empty"),
          width: size,
          height: size,
          child: AccountCard.iconForTokenType(tokenType) ?? Container()),
    );
  }

  Widget _buildInfoColumn() {
    final text = widget.accountDetail?.funder == null
        ? s.noAccountSelected
        : widget.accountDetail.funder.toString();
    final textWidth =
        expanded ? 120.0 : (widget.accountDetail == null ? null : 120.0);
    final balanceText = _balanceText();
    var showBadge =
        (widget.accountDetail?.marketConditions?.efficiency ?? 1.0) <
            MarketConditions.minEfficiency;
    final activeColor = Color(0xff6efac8);
    final inactiveColor = Color(0xfff88b9f);
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // signer
          Container(
            height: 20,
            width: textWidth,
            child: TapToCopyText(
              text,
              padding: EdgeInsets.zero,
              overflow: TextOverflow.ellipsis,
              style: OrchidText.body2,
            ),
          ),
          // active / inactive label
          if (!short && widget.active != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.active ? s.active : s.inactive,
                style: OrchidText.caption.copyWith(
                  color: widget.active ? activeColor : inactiveColor,
                ),
              ),
            ),
          if (!short) pady(8),
          // balance
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: SizedBox(
              key: Key(balanceText ?? ''),
              height: 24,
              child: balanceText != null
                  ? Badge(
                      showBadge: showBadge,
                      elevation: 0,
                      badgeContent: Text('!', style: OrchidText.caption),
                      padding:
                          EdgeInsets.only(left: 8, right: 8, bottom: 5, top: 8),
                      toAnimate: false,
                      position: BadgePosition.topEnd(top: -5, end: -30),
                      child: Text(balanceText, style: OrchidText.highlight),
                    )
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildLoading(),
                    ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            reverseDuration: const Duration(milliseconds: 200),
            child: expanded
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 32.0, right: 32, top: 8, bottom: 24),
                        child: Divider(
                            color: Colors.white.withOpacity(0.4),
                            thickness: 0.5),
                      ),
                      _buildExpandedDetail(),
                    ],
                  )
                : Container(),
          ),
          pady(1),
        ],
      ),
    );
  }

  // Return the text or null
  String _balanceText() {
    return widget.accountDetail == null
        ? formatCurrency(0.0, digits: 2)
        : (widget.accountDetail.lotteryPot?.balance?.formatCurrency(digits: 2));
  }

  Widget _buildExpandedDetail() {
    var lotteryPot = widget.accountDetail?.lotteryPot;
    var depositText = lotteryPot?.deposit?.formatCurrency(digits: 2) ?? "";
    final efficiency = widget.accountDetail?.marketConditions?.efficiency ?? 0;
    final chartModel = lotteryPot != null
        ? AccountBalanceChartTicketModel(
            lotteryPot, widget.accountDetail.transactions ?? [])
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.balance, style: OrchidText.body2),
              Text(_balanceText() ?? '', style: OrchidText.body2),
            ],
          ),
          pady(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.deposit, style: OrchidText.body2),
              Text(depositText, style: OrchidText.body2),
            ],
          ),
          pady(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.efficiency, style: OrchidText.body2),
              Stack(
                alignment: Alignment.center,
                children: [
                  OrchidCircularEfficiencyIndicators.large(efficiency),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: Text((efficiency * 100.0).toStringAsFixed(2) + '%',
                        style: OrchidText.caption.copyWith(
                            color: OrchidCircularEfficiencyIndicators
                                .colorForEfficiency(efficiency))),
                  )
                ],
              ),
            ],
          ),
          pady(16),
          pady(16),
          if (chartModel != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.tickets, style: OrchidText.body2),
                AccountChart.buildTicketsAvailableLineChart(
                    chartModel, efficiency)
              ],
            ),
        ],
      ),
    );
  }

  SizedBox _buildLoading() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
          color: OrchidColors.purpleCaption, strokeWidth: 1.5),
    );
  }

  Widget _buildToggleButton({bool checked}) {
    return GestureDetector(
      onTap: () {
        _gradientAnim.reset();
        _gradientAnim.forward();
        if (widget.onSelected != null) {
          widget.onSelected();
        }
      },
      child: GradientBorder(
        gradient: OrchidGradients.transparentGradientTLBR,
        radius: 20,
        strokeWidth: 1,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xff312346),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: (checked
                ? Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 5),
                    child: SvgPicture.asset('assets/svg/toggle_checked.svg',
                        width: 25, height: 25, fit: BoxFit.scaleDown),
                  )
                : SvgPicture.asset('assets/svg/toggle_unchecked.svg',
                    width: 20, height: 20, fit: BoxFit.scaleDown)),
          ),
        ),
      ),
    );
  }

  S get s {
    return S.of(context);
  }
}
