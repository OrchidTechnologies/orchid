import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/common/formatting.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/app_colors.dart';

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
    var titleText = s.yourAccountIsEmpty;
    var bodyText = s.toConnectEitherAddCryptoUsingTheOrchidDappOr;

    var content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleRow(titleText, alert: true),
        if (!_collapsed) ...[
          _buildBodyText(bodyText),
          pady(16),
          if (OrchidPlatform.hasPurchase)
            _buildBuyButton()
          else
            _buildUseCryptoWalletButton(),
          pady(16),
          _buildUseAnotherAccountButton(),
          pady(24),
        ],
      ],
    );
    return _buildCollapsiblePanel(content: content);
  }

  Widget _buildHasPurchaseContent() {
    var titleText = s.yourAccountIsEmpty;
    var bodyText = s.toConnectEitherAddCreditsUsingAnInappPurchaseOr;

    bool isAndroid = OrchidPlatform.isAndroid;
    var content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleRow(titleText, alert: true),
        if (!_collapsed) ...[
          _buildBodyText(bodyText),
          pady(16),
          _buildBuyButton(),
          if (isAndroid) pady(16),
          if (isAndroid) _buildUseCryptoWalletButton(lightColor: true),
          pady(16),
          _buildUseAnotherAccountButton(),
          pady(24),
        ],
      ],
    );
    return _buildCollapsiblePanel(content: content);
  }

  Padding _buildBodyText(String bodyText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(bodyText, style: bodyStyle),
    );
  }

  Widget _buildBuyButton() {
    var text = s.buyCredits;
    var action = _purchaseOrchidAccount;
    return _buildButton(text: text, onPressed: action);
  }

  Widget _buildUseAnotherAccountButton() {
    var text = s.useAnotherAccount;
    var action = _importOrchidAccount;
    return _buildButton(text: text, lightColor: true, onPressed: action);
  }

  Widget _buildUseCryptoWalletButton({bool lightColor = false}) {
    var text = s.useCryptoWallet;
    var action = _openDapp;
    return _buildButton(text: text, lightColor: lightColor, onPressed: action);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: FlatButton(
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
      ),
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

  void _openDapp() async {
    launch(OrchidUrls.accountOrchid, forceSafariVC: false);
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
