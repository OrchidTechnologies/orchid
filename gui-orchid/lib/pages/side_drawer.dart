import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import '../common/tap_copy_text.dart';
import 'app_routes.dart';

/// The application side drawer
class SideDrawer extends StatefulWidget {
  @override
  _SideDrawerState createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  String? _version;

  @override
  void initState() {
    super.initState();
    OrchidAPI().versionString().then((value) {
      log("got version: $value");
      setState(() {
        _version = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: OrchidGradients.blackGradientBackground,
            border:
                Border(right: BorderSide(color: OrchidColors.purple_ff8c61e1)),
          ),
          child: buildContent(context),
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        // top logo
        Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0, bottom: 24),
            child: DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: SvgPicture.asset(
                OrchidAssetSvg.orchid_logo_side_path,
                width: 100,
                height: 112,
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SideDrawerTile(
                  title: s.trafficAnalysis,
                  svgName: OrchidAssetSvg.traffic_path,
                  showDetail: true,
                  hoffset: 4.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.traffic);
                  }),
              SideDrawerTile(
                  title: s.accountManager,
                  svgName: OrchidAssetSvg.payments_path,
                  showDetail: true,
                  hoffset: 4.0,
                  onPressed: () {
                    AppRoutes.pushAccountManager(context);
                  }),
              SideDrawerTile(
                  title: s.circuitBuilder,
                  svgName: OrchidAssetSvg.hops_icon_path,
                  showDetail: true,
                  hoffset: 2.5,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.circuit);
                  }),
              SideDrawerTile(
                  title: s.settings,
                  svgName: OrchidAssetSvg.settings_gear_path,
                  showDetail: true,
                  hoffset: 2.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  }),
              SideDrawerTile(
                  title: s.help,
                  icon: Icons.help_outline,
                  showDetail: true,
                  hoffset: 1.0,
                  onPressed: () {
                    Navigator.pushNamed(context, '/help/overview');
                  }),
              SideDrawerTile(
                  title: s.privacyPolicy,
                  svgName: OrchidAssetSvg.privacy_path,
                  showDetail: true,
                  hoffset: 2.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.privacy);
                  }),
              SideDrawerTile(
                  title: s.openSourceLicenses,
                  svgName: OrchidAssetSvg.document_path,
                  showDetail: true,
                  hoffset: 3.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.open_source);
                  }),
            ],
          ),
        ),

        // Version info at the bottom
        SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              divider(),
              SizedBox(height: 16),
              TapToCopyText(
                  s.version + ": " + (_version ?? "<" + s.noVersion + ">"),
                  key: ValueKey(_version),
                  style: OrchidText.caption),
            ],
          ),
        )
      ],
    );
  }

  Widget divider() {
    return Divider(
      color: Colors.white.withAlpha((0.12 * 255).toInt()),
      height: 1.0,
    );
  }

  S get s {
    return S.of(context)!;
  }
}

class SideDrawerTile extends StatelessWidget {
  final String title;
  final String? imageName;
  final String? svgName;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool showDetail;
  final double hoffset;

  SideDrawerTile({
    required this.title,
    this.imageName,
    this.svgName,
    this.icon,
    required this.onPressed,
    this.showDetail = false,
    this.hoffset = 0,
  }) : super() {
    assert(imageName != null || icon != null || svgName != null);
  }

  @override
  Widget build(BuildContext context) {
    Widget leading = svgName != null
        ? SizedBox(width: 20, height: 20, child: SvgPicture.asset(svgName!))
        : (imageName != null
            ? Image(
                height: 20,
                width: 20,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                color: Colors.white,
                image: AssetImage(imageName!))
            : Icon(icon, color: Colors.white, size: 24));
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: OrchidPanel(
        edgeGradient: OrchidGradients.orchidPanelEdgeGradientMoreVertical,
        child: Container(
          child: ListTile(
              contentPadding: EdgeInsets.only(left: 16, right: 16),
              horizontalTitleGap: 0,
              leading: Padding(
                padding: EdgeInsets.only(left: hoffset),
                child: leading,
              ),
              trailing: showDetail
                  ? Icon(Icons.chevron_right, color: AppColors.white)
                  : null,
              title: Text(title,
                  textAlign: TextAlign.left,
                  style: OrchidText.subtitle.copyWith(height: 1.5)),
              onTap: onPressed),
        ),
      ),
    );
  }
}
