import 'dart:math';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/account/account_detail_store.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/util/units.dart';
import '../../orchid/orchid_circular_identicon.dart';
import '../../orchid/orchid_panel.dart';
import '../../orchid/orchid_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/util/collections.dart';

/// Displays the account info for each hop in the Circuit and offers
/// the "manage accounts" button used on the connect page.
class ManageAccountsCard extends StatefulWidget {
  final Circuit circuit;

  final int initiallySelectedIndex;

  // When true shrinks the identicon a bit and adjusts the overall height for it.
  // (This is a small adjustment used when the screen is short.)
  final bool minHeight;

  final VoidCallback onManageAccountsPressed;

  final Function(int selectedIndex) onSelectIndex;

  const ManageAccountsCard({
    Key key,
    this.circuit,
    this.initiallySelectedIndex = 0,
    this.minHeight = false,
    this.onManageAccountsPressed,
    this.onSelectIndex,
  }) : super(key: key);

  @override
  _ManageAccountsCardState createState() => _ManageAccountsCardState();
}

class _ManageAccountsCardState extends State<ManageAccountsCard> {
  AccountDetailStore _accountDetailStore;

  // The selected hop account index
  int _selectedIndex;

  void _setSelectedIndex(int i) {
    setState(() {
      _selectedIndex = i;
    });
    if (widget.onSelectIndex != null) {
      widget.onSelectIndex(i);
    }
  }

  CircuitHop get _selectedHop {
    if (_hopCount <= _selectedIndex) {
      return null;
    }
    return widget.circuit.hops[_selectedIndex];
  }

  int get _hopCount {
    return widget.circuit.hops.length;
  }

  @override
  void initState() {
    super.initState();
    this._selectedIndex = widget.initiallySelectedIndex;
    _accountDetailStore =
        AccountDetailStore(onAccountDetailChanged: _accountDetailChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.minHeight ? 174 : 180,
      child: widget.circuit == null
          ? Container()
          : Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildCardBody(),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildCardTop(),
                ),
                if (_hopCount > 1)
                  Align(
                    alignment: Alignment.center,
                    child: _buildHopSelectorButtons(),
                  ),
              ],
            ),
    );
  }

  Padding _buildHopSelectorButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              _setSelectedIndex(max(_selectedIndex - 1, 0));
            },
            child: Icon(
              Icons.chevron_left,
              color: Colors.white,
            ),
          ),
          padx(212),
          TextButton(
            onPressed: () {
              _setSelectedIndex(
                  min(_selectedIndex + 1, widget.circuit.hops.length - 1));
            },
            child: Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTop() {
    if (_hopCount == 0) {
      return OrchidCircularIdenticon(address: null);
    }
    // map the hops to icons
    var icons = widget.circuit.hops
        .mapIndexed((hop, i) {
          final selected = i == _selectedIndex;
          final afterSelected = i - 1 == _selectedIndex;

          final baseSize = widget.minHeight ? 48.0 : 60.0;
          var icon = _buildTappableIconForHop(hop, i, selected, baseSize);

          // Position using padding and animate the size change.
          final spacing = 40.0;
          final leftPad = max(
              0.0, i * spacing + (selected ? -4 : 0) + (afterSelected ? 4 : 0));
          final topPad = (selected ? 0.0 : 5.0);
          final shrink = 0.8;
          final size = selected ? baseSize : baseSize * shrink;
          return Padding(
            key: Key(i.toString()),
            padding: EdgeInsets.only(left: leftPad, top: topPad),
            child: AnimatedContainer(
                width: size,
                height: size,
                duration: Duration(milliseconds: 200),
                curve: Curves.easeOutSine,
                child: FittedBox(fit: BoxFit.contain, child: icon)),
          );
        })
        .toList()
        .reversed
        .toList();

    // Move selected to the front (note that the list is reversed for the stack)
    icons.add(icons.removeAt(_hopCount - _selectedIndex - 1));

    return Container(
      width: 300,
      child: FittedBox(fit: BoxFit.scaleDown, child: Stack(children: icons)),
    );
  }

  Widget _buildTappableIconForHop(
      CircuitHop hop, int index, bool selected, double baseSize) {
    return GestureDetector(
      onTap: () {
        _setSelectedIndex(index);
      },
      child: _buildIconForHop(hop, selected, baseSize),
    );
  }

  Widget _buildIconForHop(CircuitHop hop, bool selected, double baseSize) {
    final fade = 0.5;
    switch (hop.protocol) {
      case HopProtocol.Orchid:
        var _hop = hop as OrchidHop;
        var account = _accountDetailStore.get(_hop.account);
        return OrchidCircularIdenticon(
          address: account.signerAddress,
          fade: selected ? 1.0 : fade,
        );
        break;
      case HopProtocol.OpenVPN:
        return OrchidCircularIdenticon(
          image: Padding(
            padding: const EdgeInsets.all(8.0),
            child: OrchidAsset.svg.openvpn,
          ),
          fade: selected ? 1.0 : fade,
        );
        break;
      case HopProtocol.WireGuard:
        return OrchidCircularIdenticon(
          image: Padding(
            padding: const EdgeInsets.all(8.0),
            child: OrchidAsset.svg.wireguard,
          ),
          fade: selected ? 1.0 : fade,
        );
        break;
    }
    throw Exception();
  }

  SizedBox _buildCardBody() {
    return SizedBox(
        width: 312,
        height: 150,
        child: OrchidPanel(
            child: Center(
                child: Padding(
          padding: const EdgeInsets.only(top: 17.0),
          child: _selectedHop != null
              ? _buildCardContentForHop(_selectedHop)
              : _buildOrchidHopCardContent(null),
        ))));
  }

  Widget _buildCardContentForHop(CircuitHop hop) {
    switch (hop.protocol) {
      case HopProtocol.Orchid:
        return _buildOrchidHopCardContent(hop as OrchidHop);
        break;
      case HopProtocol.OpenVPN:
        // Note: duplicated in manage accounts card
        return Padding(
          padding: const EdgeInsets.only(bottom: 17.0),
          child: Text(s.openVPNHop).title,
        );
      case HopProtocol.WireGuard:
        // Note: duplicated in manage accounts card
        return Padding(
          padding: const EdgeInsets.only(bottom: 17.0),
          child: Text(s.wireguardHop).title,
        );
        break;
    }
    throw Exception();
  }

  Widget _buildOrchidHopCardContent(OrchidHop orchidHop) {
    final _selectedAccount =
        orchidHop != null ? _accountDetailStore.get(orchidHop.account) : null;
    final signerAddress = _selectedAccount?.signerAddress;
    final text = signerAddress == null ? s.noAccountSelected : signerAddress.toString(elide: true);
    final textWidth = signerAddress == null ? null : 120.0;
    final balanceText = signerAddress == null
        ? formatCurrency(0.0, locale: context.locale, digits: 2)
        : (_selectedAccount.lotteryPot?.balance
                ?.formatCurrency(digits: 2, locale: context.locale) ??
            "...");
    final efficiency = _selectedAccount?.marketConditions?.efficiency;
    var showBadge = (_selectedAccount?.marketConditions?.efficiency ?? 1.0) <
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
            textAlign: TextAlign.center,
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
        _buildManageAccountsButton(context, showBadge),
      ],
    );
  }

  Widget _buildManageAccountsButton(BuildContext context, bool showBadge) {
    return GestureDetector(
      onTap: widget.onManageAccountsPressed,
      child: Badge(
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
    );
  }

  void _accountDetailChanged() {
    setState(() {}); // Trigger a UI refresh
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    _accountDetailStore.dispose();
    super.dispose();
  }
}
