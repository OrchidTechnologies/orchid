import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';
import 'package:badges/badges.dart' as badge;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/orchid/account_chart.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/field/token_value_widget_row.dart';
import 'package:orchid/orchid/orchid_circular_identicon.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/util/timed_builder.dart';
import 'package:orchid/util/format_currency.dart';
import 'package:orchid/api/pricing/usd.dart';
import '../orchid_panel.dart';
import '../../api/orchid_eth/orchid_account_detail.dart';

/// The account cards used on the account manager
class AccountCard extends StatefulWidget {
  final AccountDetail? accountDetail;

  /// Support for partial account display during user entry. These values
  /// populate the display in lieu of an accountDetail. If accountDetail is
  /// set these values are ignored.
  final EthereumAddress? partialAccountFunderAddress;
  final EthereumAddress? partialAccountSignerAddress;

  // If non-null show the selected circle and checkmark for selection
  final bool? selected;

  // If non-null designates the active / inactive status line.
  final bool? active;

  // Callback for selection when selected is non-null.
  final VoidCallback? onSelected;

  final bool initiallyExpanded;

  /// Produces a shorter card
  final bool minHeight;

  final bool allowExpand;

  /// Additional options for the detail view
  final bool showAddresses;
  final bool showContractVersion;

  const AccountCard({
    Key? key,
    this.accountDetail,
    this.active,
    this.selected,
    this.onSelected,
    this.initiallyExpanded = false,
    this.minHeight = false,
    this.partialAccountFunderAddress,
    this.partialAccountSignerAddress,
    this.allowExpand = true,
    this.showAddresses = true,
    this.showContractVersion = true,
  }) : super(key: key);

  @override
  _AccountCardState createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with TickerProviderStateMixin {
  final expandDuration = const Duration(milliseconds: 330);
  late bool expanded;
  late AnimationController _gradientAnim;

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

  bool get minHeight {
    return widget.minHeight;
  }

  double? get efficiency => widget.accountDetail?.marketConditions?.efficiency;

  LotteryPot? get pot {
    // return AccountMock.account1xdaiLocked.mockLotteryPot;
    // return AccountMock.account1xdaiUnlocking.mockLotteryPot;
    // return AccountMock.account1xdaiUnlocked.mockLotteryPot;
    // return AccountMock.account1xdaiPartUnlocked.mockLotteryPot;
    return widget.accountDetail?.lotteryPot;
  }

  bool get _potIsWarned {
    return pot?.isWarned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    var width = 334.0;
    var checkExtraHeight = _hasSelection ? 12.0 : 0.0;
    var checkExtraWidth = _hasSelection ? 16.0 : 0.0;
    return GestureDetector(
      onTap: () {
        if (!widget.allowExpand) {
          return;
        }
        setState(() {
          expanded = !expanded;
        });
      },
      child: SizedBox(
        width: width + checkExtraWidth,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  right: checkExtraWidth, bottom: checkExtraHeight),
              child: OrchidPanel(
                key: Key(widget.selected?.toString() ?? ''),
                highlight: widget.active ?? false,
                highlightAnimation: _gradientAnim.value,
                child: AnimatedSize(
                  alignment: Alignment.topCenter,
                  duration: millis(500),
                  child: _buildCardContent(context),
                ),
              ),
            ),
            // checkmark selection button
            if (_hasSelection)
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildToggleButton(checked: widget.selected!),
              )
          ],
        ),
      ).left(checkExtraWidth),
    );
  }

  TokenType? get tokenType {
    return widget.accountDetail?.lotteryPot?.balance.type;
  }

  Widget _buildCardContent(BuildContext context) {
    return TokenPriceBuilder(
        tokenType: tokenType ?? Tokens.TOK,
        builder: (USD? price) {
          // if (price == null) { return Container(); }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(price),
              if (expanded && widget.accountDetail != null)
                _buildExpandedContent(price),
            ],
          ).top(14).bottom(minHeight ? 14 : 8);
        });
  }

  Widget _buildEfficiencyMeter(double size) {
    return _fade(
      Container(
        key: Key((efficiency != null).toString()),
        child: OrchidCircularEfficiencyIndicators.medium(efficiency ?? 0,
            size: size),
      ),
    );
  }

  Widget _buildTokenIcon(TokenType? tokenType, double size) {
    return _fade(
      SizedBox(
          key: Key(tokenType?.toString() ?? 'empty'),
          width: size,
          height: size,
          child: tokenType?.chain.icon ?? Container()),
    );
  }

  Widget _buildHeader(USD? price) {
    return Column(
      children: [
        // user identicon funder/signer
        if (!minHeight)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFunderIconAddress(),
              _buildSignerIconAddress().left(8),
            ],
          ).padx(16),

        if (!minHeight) _divider().top(8),

        // Chain/efficiency icon and balance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildChainEfficiencyIcon(),
            _buildBalanceColumn(price),
            padx(48)
          ],
        ).padx(24).pady(12),
      ],
    );
  }

  Widget _buildBalanceColumn(USD? price) {
    if (widget.accountDetail == null) {
      return Text("No account").caption.inactive;
    }
    final balanceText = _balanceText();
    var showBadge = (efficiency ?? 1.0) < MarketConditions.minEfficiency;

    // active indicates used in circuit builder
    final activeColor = Color(0xff6efac8);
    final inactiveColor = Color(0xfff88b9f);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // active / inactive label
        if (!minHeight && widget.active != null)
          Text(
            widget.active! ? s.active : s.inactive,
            style: OrchidText.caption.copyWith(
              color: widget.active! ? activeColor : inactiveColor,
            ),
          ).bottom(2),
        // if (!minHeight) pady(8),

        // balance
        _fade(
          SizedBox(
            key: Key(balanceText ?? ''),
            child: balanceText != null
                ? badge.Badge(
                    // ignorePointer: true,
                    showBadge: showBadge,
                    badgeStyle: badge.BadgeStyle(
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    badgeContent: Text('!', style: OrchidText.caption)
                        .padx(8)
                        .top(8)
                        .bottom(5),
                    // toAnimate: false,
                    position: badge.BadgePosition.topEnd(top: -5, end: -30),
                    child: Text(balanceText, style: OrchidText.highlight),
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildLoading(),
                  ),
          ),
        ),

        // price
        if (pot?.balance != null)
          Text(_usdValueText(price, pot!.balance)).caption.new_purple_bright,
      ],
    );
  }

  Widget _buildFunderIconAddress({
    TextStyle? textStyle,
    double? pad,
  }) {
    final funder =
        widget.accountDetail?.funder ?? widget.partialAccountFunderAddress;
    return _identiconAddressRow(funder, "Wallet",
        textStyle: textStyle, pad: pad);
  }

  Widget _buildSignerIconAddress({
    TextStyle? textStyle,
    double? pad,
  }) {
    final signer = widget.accountDetail?.signerAddress ??
        widget.partialAccountSignerAddress;
    return _identiconAddressRow(
      signer,
      s.orchidIdentity,
      textStyle: textStyle,
      pad: pad,
    );
  }

  Widget _identiconAddressRow(
    EthereumAddress? address,
    String emptyString, {
    TextStyle? textStyle,
    double? pad,
  }) {
    final text = address?.toString(elide: false) ?? '';
    final bool active = address != null;
    final displayText = active ? address.toString(elide: true) : emptyString;
    final style = textStyle ??
        (active ? OrchidText.body2.underlined : OrchidText.body2.inactive);
    return Row(
      children: [
        OrchidCircularIdenticon(
          address: address,
          size: 20,
          // show border for placeholder only
          showBorder: !active,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 150),
          child: FittedBox(
            child: TapToCopyText(
              text,
              displayText: displayText,
              padding: EdgeInsets.zero,
              style: style,
              textAlign: TextAlign.left,
              // disable when empty
              onTap: !active ? (_) {} : null,
            ).top(3).left(pad ?? 8),
          ),
        ),
      ],
    );
  }

  Stack _buildChainEfficiencyIcon() {
    // log("XXX: market details: ${widget.accountDetail}");
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildEfficiencyMeter(48),
        if (tokenType != null) _buildTokenIcon(tokenType!, 24),
      ],
    );
  }

  // tokenValue may be null yielding zero
  String _usdValueText(
    USD? price,
    Token tokenAmount,
    /*{bool showSuffix = true}*/
  ) {
    return USD.formatUSDValue(
        context: context, tokenAmount: tokenAmount, price: price);
  }

  String? _balanceText() {
    return widget.accountDetail == null
        ? formatCurrency(0.0, locale: context.locale, precision: 2)
        : (pot?.balance.formatCurrency(locale: context.locale, precision: 2));
  }

  Widget _buildExpandedContent(USD? price) {
    final efficiency =
        widget.accountDetail?.marketConditions?.efficiency; // or null
    final chartModel = pot != null
        ? AccountBalanceChartTicketModel(
            pot!, widget.accountDetail?.transactions ?? [])
        : null;
    final version = widget.accountDetail?.account.version;
    final versionText = version != null ? 'V$version' : '';

    final showDeposit =
        // not yet loaded (placeholder)
        pot?.effectiveDeposit == null ||
            // has net deposit
            pot!.effectiveDeposit.gtZero() ||
            // no warned amount
            !_potIsWarned;

    return Column(
      children: [
        if (!minHeight) _divider().bottom(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // balance
            _buildLabeledTokenValueRow(s.balance, pot?.balance, price),

            // deposit
            if (showDeposit)
              _buildLabeledTokenValueRow(
                      s.deposit, pot?.effectiveDeposit, price)
                  .top(13),

            // lock
            if (_potIsWarned) _buildUnlockInfo(price).top(16),

            // efficiency
            _buildEfficiencyRow(efficiency).top(16),

            // tickets
            if (chartModel != null)
              _buildTicketsRow(chartModel, efficiency).top(20),

            // wallet
            if (widget.showAddresses)
              _labeledRow(
                title: "Wallet address",
                child: _buildFunderIconAddress(
                    textStyle: OrchidText.extra_large, pad: 12),
              ).top(16),

            // identity
            if (widget.showAddresses)
              _labeledRow(
                      title: s.orchidIdentity,
                      child: _buildSignerIconAddress(
                          textStyle: OrchidText.extra_large, pad: 12))
                  .top(16),

            // contract version
            if (widget.showContractVersion)
              _labeledRow(
                title: s.contract,
                child: Text(versionText, style: OrchidText.extra_large).top(8),
              ).top(16),
            pady(16)
          ],
        ).padx(40),
      ],
    );
  }

  /*
  Widget _buildShareButton() {
    return GestureDetector(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.ios_share, color: Colors.white),
        ],
      ),
      onTap: () async {
        final String config = widget.accountDetail.account.toExportString();
        await AccountManagerPageUtil.export(context, config);
      },
    );
  }
   */

  Widget _buildTicketsRow(
      AccountBalanceChartTicketModel chartModel, double? efficiency) {
    return _labeledRow(
      titleWidget: Row(
        children: [
          Text(s.tickets, style: OrchidText.body2),
          Text("(minimum available)", style: OrchidText.caption).left(8),
        ],
      ),
      // AccountChart.buildTicketsAvailable(context, chartModel, efficiency, true)
      child: Row(
        children: [
          Text(chartModel.availableTicketsCurrentMax.toString(),
              style: OrchidText.extra_large),
        ],
      ).height(18).top(6),
    );
  }

  Widget _buildEfficiencyRow(double? efficiency) {
    return _labeledRow(
      title: s.efficiency,
      child: Row(
        children: [
          OrchidCircularEfficiencyIndicators.small(efficiency ?? 0, size: 15),
          if (efficiency != null)
            Text(
              '${(efficiency * 100.0).round()}%',
              style: OrchidText.extra_large.copyWith(
                // fontWeight: FontWeight.w400,
                color: OrchidCircularEfficiencyIndicators.colorForEfficiency(
                    efficiency),
              ),
            ).boxHeight(18).left(12),
        ],
      ).top(8),
    );
  }

  Widget _buildLabeledTokenValueRow(
    String title,
    Token? value,
    USD? price,
  ) {
    return _labeledRow(
      title: title,
      child: _buildTokenValueTextRow(value: value, price: price),
    );
  }

  // display token value and symbol on a row with usd price in a row below
  Widget _buildTokenValueTextRow({Token? value, USD? price, Color? textColor}) {
    final valueText = ((value ?? (tokenType ?? Tokens.TOK).zero).formatCurrency(
      locale: context.locale,
      minPrecision: 1,
      maxPrecision: 5,
      showPrecisionIndicator: true,
      showSuffix: false,
    ));
    final valueWidget =
        Text(valueText).extra_large.withColor(textColor ?? Colors.white);
    return TokenValueWidgetRow(
      context: context,
      child: valueWidget,
      tokenType: tokenType,
      value: value,
      price: price,
      textColor: textColor,
    );
  }

  // label row with child row below
  Widget _labeledRow({
    String? title,
    Widget? titleWidget,
    required Widget child,
    Color? textColor,
  }) {
    assert(title != null || titleWidget != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (titleWidget ??
                Text(title!, style: OrchidText.body2)
                    .withColor(textColor ?? Colors.white)
                    .top(5))
            .height(24),
        child,
      ],
    );
  }

  Widget _buildUnlockInfo(USD? price) {
    return TimedBuilder.interval(
      seconds: 1,
      builder: (context) {
        return _buildUnlockInfoImpl(price);
      },
    );
  }

  Widget _buildUnlockInfoImpl(USD? price) {
    var _pot = pot;
    if (_pot == null || !_pot.isWarned) {
      return Container();
    }
    final color = OrchidColors.status_yellow;

    final icon = Icon(_pot.isUnlocked ? Icons.lock_open : Icons.lock,
        color: color, size: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeledRow(
          titleWidget: Row(
            children: [
              icon,
              Text(_pot.isUnlocked ? "Unlocked deposit" : "Unlocking deposit")
                  .body2
                  .withColor(color)
                  .left(8)
                  .top(4),
            ],
          ),
          child: _buildTokenValueTextRow(
            value: _pot.isUnlocked ? _pot.unlockedAmount : _pot.warned,
            price: price,
            textColor: color,
          ).top(4),
        ),
        if (_pot.isUnlocking)
          _labeledRow(
            title: s.unlockTime,
            child:
                Text(_pot.unlockInString()).extra_large.withColor(color).top(4),
            textColor: color,
          ).top(4)
      ],
    );
  }

  Widget _divider() {
    return Divider(color: Colors.black, thickness: 1.0);
  }

  Widget _buildLoading() {
    if (widget.accountDetail?.funder == null ||
        widget.accountDetail?.signerAddress == null) {
      return Container();
    }
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
          color: OrchidColors.purpleCaption, strokeWidth: 1.5),
    );
  }

  Widget _buildToggleButton({required bool checked}) {
    return GestureDetector(
      onTap: () {
        if (widget.active ?? false) {
          _gradientAnim.reset();
          _gradientAnim.forward();
        }
        if (widget.onSelected != null) {
          widget.onSelected!();
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
          child: _fade(
            checked
                ? Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 5),
                    child: SvgPicture.asset(OrchidAssetSvg.toggle_checked_path,
                        width: 25, height: 25, fit: BoxFit.scaleDown),
                  )
                : SvgPicture.asset(OrchidAssetSvg.toggle_unchecked_path,
                    width: 20, height: 20, fit: BoxFit.scaleDown),
          ),
        ),
      ),
    );
  }

  // cross-fade when the child changes
  Widget _fade(Widget child) {
    return AnimatedSwitcher(duration: millis(500), child: child);
  }
}
