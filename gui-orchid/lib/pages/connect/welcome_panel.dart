import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_account_config/orchid_account_v1.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/pages/circuit/circuit_page.dart';
import 'package:orchid/common/scan_paste_account.dart';
import 'package:orchid/common/formatting.dart';
import '../../common/app_colors.dart';
import '../app_routes.dart';

class WelcomePanel extends StatefulWidget {
  const WelcomePanel({
    Key key,
  }) : super(key: key);

  @override
  _WelcomePanelState createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel>
    with TickerProviderStateMixin {
  bool _collapsed = false;

  var bodyTextColor = AppColors.neutral_1;

  TextStyle get bodyStyle {
    return TextStyle(fontSize: 12, height: 16 / 12, color: bodyTextColor);
  }

  get titleStyle {
    return bodyStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
  }

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 16),
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedSize(
            alignment: Alignment.topCenter,
            vsync: this,
            // zero duration here breaks things
            duration: _collapsed
                ? Duration(milliseconds: 10)
                : Duration(milliseconds: 300),
            child: SingleChildScrollView(child: _buildContent())),
      ),
    );
  }

  Widget _buildContent() {
    // return _buildNoPurchaseContent();
    return OrchidPlatform.hasPurchase
        ? _buildHasPurchaseContent()
        : _buildNoPurchaseContent();
  }

  Widget _buildNoPurchaseContent() {
    return _buildCollapsiblePanel(
        content: _buildImportAccountPanel(alert: true));
  }

  Widget _buildHasPurchaseContent() {
    var purchaseTitleText = s.newToOrchid;
    var purchaseBodyTextCollapsed =
        "Buy an Orchid account for less than \$2 USD or import an existing account.";
    var purchaseBodyTextExpanded =
        "Buy an Orchid account for less than \$2 USD.";
    var bodyText =
        _collapsed ? purchaseBodyTextCollapsed : purchaseBodyTextExpanded;
    var buttonText = "Buy an Orchid Account";
    var buttonAction = _purchaseOrchidAccount;

    var content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleRow(purchaseTitleText, alert: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(bodyText, style: bodyStyle),
        ),
        if (!_collapsed) pady(16),
        if (!_collapsed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildButton(text: buttonText, onPressed: buttonAction),
          ),
        pady(24),
        if (!_collapsed)
          Container(height: 0.5, color: AppColors.grey_6), // divider
        if (!_collapsed) _buildImportAccountPanel(alert: false),
      ],
    );
    return _buildCollapsiblePanel(content: content);
  }

  // title row with alert symbol
  Padding _buildTitleRow(String titleText, {bool alert}) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8, left: 22, right: 22),
      child: Row(
        children: <Widget>[
          Row(
            children: [
              if (alert) Icon(Icons.error, color: AppColors.teal_3, size: 20),
              if (alert) padx(9),
              RichText(text: TextSpan(text: titleText, style: titleStyle)),
            ],
          ),
        ],
      ),
    );
  }

  Container _buildImportAccountPanel({bool alert}) {
    var titleText = "Have an Orchid Account?";
    var bodyText = "Import an existing account or go to settings and enable "
        "multi-hop to use the previous interface.";
    var buttonText = "Import Account";
    var buttonAction = _importOrchidAccount;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTitleRow(titleText, alert: alert),
          pady(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(bodyText, style: bodyStyle),
          ),
          pady(16),
          if (!_collapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildButton(
                text: buttonText,
                lightColor: true,
                onPressed: buttonAction,
              ),
            ),
          /*
          if (!_collapsed)
            ScanOrPasteOrchidAccount(
              spacing: screenWidth < AppSize.iphone_12_max.width ? 8 : 16,
              onImportAccount: (ParseOrchidAccountResult result) async {
                var hop =
                    await OrchidVPNConfigV0.importAccountAsHop(result.account);
                CircuitUtils.addHopToCircuit(hop);
              },
              v0Only: false,
            ),

           */
          pady(16)
        ],
      ),
    );
  }

  Container _buildCollapsiblePanel({
    Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Needed during the animated collapse - cliprrect doesn't mask during?
        borderRadius: _collapsed
            ? BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))
            : null,
      ),
      child: Stack(
        children: [
          content,
          Align(alignment: Alignment.topRight, child: _buildToggleButton()),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      // color: Colors.green,
      // width: 28,
      child: TextButton(
        child: Icon(
          _collapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: bodyTextColor,
        ),
        onPressed: () {
          setState(() {
            _collapsed = !_collapsed;
          });
        },
      ),
    );
  }

  Widget _buildButton({
    @required String text,
    VoidCallback onPressed,
    bool lightColor = false,
  }) {
    Color bgColor = lightColor ? Colors.white : AppColors.teal_3;
    Color borderColor = AppColors.teal_3;
    Color textColor = lightColor ? AppColors.teal_3 : Colors.white;

    return FlatButton(
      color: bgColor,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: borderColor, width: 1, style: BorderStyle.solid),
          borderRadius: BorderRadius.all(Radius.circular(24))),
      child: Text(text,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14.0,
            color: textColor,
          )),
    );
  }

  bool get isApple {
    return OrchidPlatform.isApple;
  }

  void _purchaseOrchidAccount() async {
    _openAccountManager(purchase: true);
  }

  void _importOrchidAccount() async {
    _openAccountManager(import: true);
  }

  void _openAccountManager({bool import = false, bool purchase = false}) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return AccountManagerPage(openToImport: import, openToPurchase: purchase);
    }));
  }

  S get s {
    return S.of(context);
  }
}
