import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/common/account_chart.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/util/units.dart';
import '../account_manager/account_detail_poller.dart';
import '../../orchid/orchid_panel.dart';
import '../../orchid/orchid_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Active account info and "manage accounts" button used on the connect page.
class AccountCard extends StatefulWidget {
  final AccountDetail accountDetail;
  final bool active;
  final VoidCallback onCheckButton;

  const AccountCard({
    Key key,
    this.accountDetail,
    this.active = false,
    this.onCheckButton,
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
  bool expanded = false;
  var expandDuration = const Duration(milliseconds: 330);
  AnimationController _gradientAnim;

  @override
  void initState() {
    super.initState();
    _gradientAnim =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    var height = expanded ? 408.0 : 116.0;
    var width = 334.0;
    var checkExtraHeight = 12.0;
    var checkExtraWidth = 16.0;
    return GestureDetector(
      onTap: () {
        setState(() {
          expanded = !expanded;
        });
      },
      child: Padding(
        padding: EdgeInsets.only(left: checkExtraWidth),
        // balance the button right
        child: AnimatedContainer(
            duration: expandDuration,
            height: height + checkExtraHeight, // padding for check button
            width: width + checkExtraWidth,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: 16, bottom: checkExtraHeight),
                    child: AnimatedBuilder(
                        animation: _gradientAnim,
                        builder: (context, snapshot) {
                          return OrchidPanel(
                              key: Key(widget.active.toString()),
                              highlight: widget.active,
                              highlightAnimation: _gradientAnim.value,
                              child: _buildCardContent(context));
                        }),
                  ),
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: _buildToggleButton(checked: widget.active))
              ],
            )),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    S s = S.of(context);
    final efficiency = widget.accountDetail?.marketConditions?.efficiency;
    final tokenType = widget.accountDetail?.lotteryPot?.balance?.type;
    return Stack(
      fit: StackFit.expand,
      children: [
        // token icon
        AnimatedAlign(
          duration: Duration(
              milliseconds: (expandDuration.inMilliseconds * 0.5).round()),
          alignment: expanded ? Alignment.topCenter : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
                left: expanded ? 0 : 24.0, top: expanded ? 24 : 0),
            child: _buildTokenIcon(tokenType),
          ),
        ),

        // info column
        AnimatedAlign(
            duration: expandDuration,
            alignment: expanded ? Alignment.topCenter : Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: expanded ? 108 : 8),
              child: _buildInfoColumn(),
            )),

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
    var size = expanded ? 60.0 : 40.0;
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
    final text = widget.accountDetail?.signer == null
        ? "No account selected"
        : widget.accountDetail.signer.toString();
    final textWidth =
        expanded ? 250.0 : (widget.accountDetail == null ? null : 120.0);
    final balanceText = _balanceText();
    var showBadge =
        (widget.accountDetail?.marketConditions?.efficiency ?? 1.0) <
            MarketConditions.minEfficiency;
    final activeColor = Color(0xff6efac8);
    final inactiveColor = Color(0xfff88b9f);
    return SingleChildScrollView(
      child: Column(
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
          pady(expanded ? 12 : 4),
          Text(
            widget.active ? s.active : "Inactive",
            //key: Key(widget.active.toString()),
            style: OrchidText.caption.copyWith(
              color: widget.active ? activeColor : inactiveColor,
            ),
          ),
          pady(8),
          if (!expanded)
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
                        padding: EdgeInsets.only(
                            left: 8, right: 8, bottom: 5, top: 8),
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
          if (expanded) ...[pady(24), _buildExpandedDetail()]
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
    final chartModel =
        lotteryPot != null && widget.accountDetail?.transactions != null
            ? AccountBalanceChartTicketModel(
                lotteryPot, widget.accountDetail.transactions)
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.balance, style: OrchidText.body2),
              Text(_balanceText(), style: OrchidText.body2),
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
                Text("Tickets", style: OrchidText.body2),
                _buildGlowingTicketsChart(chartModel, efficiency)
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGlowingTicketsChart(
      AccountBalanceChartTicketModel chartModel, double efficiency) {
    final chart = _buildTicketsChart(chartModel, efficiency);
    return Stack(
      alignment: Alignment.center,
      children: [
        // TODO: Why is this blur not working (to add the glow)?
        // ImageFiltered(
        //     imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: chart),
        chart,
      ],
    );
  }

  Widget _buildTicketsChart(
      AccountBalanceChartTicketModel chartModel, double efficiency) {
    return SizedBox(
        width: 100,
        height: 4,
        child: AccountChart.buildTicketsAvailableLineChart(chartModel,
            color: OrchidCircularEfficiencyIndicators.colorForEfficiency(
                efficiency)));
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
        if (widget.onCheckButton != null) {
          widget.onCheckButton();
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
                        width: 24, height: 24, fit: BoxFit.none),
                  )
                : SvgPicture.asset('assets/svg/toggle_unchecked.svg',
                    width: 20, height: 20, fit: BoxFit.none)),
          ),
        ),
      ),
    );
  }

  S get s {
    return S.of(context);
  }
}
