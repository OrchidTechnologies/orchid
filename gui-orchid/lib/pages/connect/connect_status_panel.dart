import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/units.dart';

class ConnectStatusPanel extends StatelessWidget {
  final USD bandwidthPrice;
  final double bandwidthAvailableGB;
  final int circuitHops;

  const ConnectStatusPanel({
    Key key,
    @required this.bandwidthPrice,
    @required this.bandwidthAvailableGB,
    @required this.circuitHops,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 312,
        height: 126,
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
    var s = S.of(context);
    // await Navigator.pushNamed(context, AppRoutes.identity);
    return _buildPanel(
        icon: SvgPicture.asset('assets/svg/gauge_icon.svg',
            width: 40, height: 35, color: Colors.white),
        text: bandwidthAvailableGB != null
            ? bandwidthAvailableGB.toStringAsFixed(1)
            : "...",
        subtext: "GB");
  }

  Widget _buildUSDPanel(BuildContext context) {
    var s = S.of(context);
    var price = bandwidthPrice != null
        ? '\$' + formatCurrency(bandwidthPrice.value)
        : "...";
    return _buildPanel(
        icon: SvgPicture.asset('assets/svg/dollars_icon.svg',
            width: 40, height: 40, color: Colors.white),
        text: price,
        subtext: "USD/GB");
  }

  Widget _buildHopsPanel(BuildContext context) {
    var s = S.of(context);
    return _buildPanel(
        icon: SvgPicture.asset('assets/svg/hops_icon.svg',
            width: 40, height: 25, color: Colors.white),
        text: circuitHops == null ? '' : "$circuitHops Hop", // No pluralization
        subtext: "Circuit");
  }

  Widget _buildPanel({Widget icon, String text, String subtext}) {
    return SizedBox(
      width: 88,
      height: 126,
      child: OrchidPanel(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 40, child: Center(child: icon)),
          pady(12),
          Text(text, style: OrchidText.body2),
          pady(4),
          Text(subtext,
              style: OrchidText.caption
                  .copyWith(color: OrchidColors.purpleCaption)),
        ],
      )),
    );
  }
}
