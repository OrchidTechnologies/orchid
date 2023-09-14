import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/vpn/orchid_api_mock.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/util/format_currency.dart';
import 'package:orchid/api/pricing/usd.dart';

import '../app_routes.dart';

class ConnectStatusPanel extends StatelessWidget {
  final USD? bandwidthPrice;
  final double? bandwidthAvailableGB;
  final int? circuitHops;
  final bool minHeight;

  const ConnectStatusPanel({
    Key? key,
    required this.bandwidthPrice,
    required this.bandwidthAvailableGB,
    required this.circuitHops,
    this.minHeight = false,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 312,
        child: Row(
          children: [
            _buildGBPanel(context),
            padx(24),
            _buildUSDPanel(context),
            padx(24),
            _buildHopsPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGBPanel(BuildContext context) {
    // await Navigator.pushNamed(context, AppRoutes.identity);
    return _buildPanel(
        icon: SvgPicture.asset(OrchidAssetSvg.gauge_icon_path,
            width: 40, height: 35, color: Colors.white),
        text: bandwidthAvailableGB != null
            ? toFixedLocalized(bandwidthAvailableGB!,
                locale: context.locale, precision: 1)
            : '...',
        subtext: context.s.gb);
  }

  Widget _buildUSDPanel(BuildContext context) {
    var price = (bandwidthPrice != null && !MockOrchidAPI.hidePrices)
        ? '\$' + formatCurrency(bandwidthPrice!.value, locale: context.locale)
        : '...';
    return _buildPanel(
        icon: SvgPicture.asset(OrchidAssetSvg.dollars_icon_path,
            width: 40, height: 40, color: Colors.white),
        text: price,
        subtext: context.s.usdgb);
  }

  Widget _buildHopsPanel(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.circuit);
      },
      child: _buildPanel(
          icon: SvgPicture.asset(OrchidAssetSvg.hops_icon_path,
              width: 40, height: 25, color: Colors.white),
          text: circuitHops == null ? '' : "$circuitHops" + ' ' + context.s.hop,
          // No pluralization
          subtext: context.s.circuit),
    );
  }

  Widget _buildPanel({required Widget icon, required String text, required String subtext}) {
    return Container(
      width: 88,
      height: minHeight ? 74 : 40.0 + 12.0 + 74.0,
      child: OrchidPanel(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!minHeight)
            Container(
              width: 40,
              height: 40,
              child: Center(child: icon),
            ),
          if (minHeight) pady(8) else pady(12),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: OrchidText.body2).padx(8)),
          pady(4),
          Text(subtext,
              style: OrchidText.caption
                  .copyWith(color: OrchidColors.purpleCaption)),
        ],
      )),
    );
  }
}
