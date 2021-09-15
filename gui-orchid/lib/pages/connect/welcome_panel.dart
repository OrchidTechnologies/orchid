import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: _buildBodyText(bodyText),
          ),
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
        if (_collapsed) pady(16),
        if (!_collapsed) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: _buildBodyText(bodyText),
          ),
          pady(16),
          Center(child: _buildBuyButton()),
          if (isAndroid) pady(16),
          if (isAndroid)
            Center(child: _buildUseCryptoWalletButton(lightColor: true)),
          pady(16),
          Center(child: _buildUseAnotherAccountButton()),
          pady(24),
        ] else
          pady(8),
      ],
    );
    return _buildCollapsiblePanel(content: content);
  }

  Widget _buildBodyText(String bodyText) {
    var bodyStyle = OrchidText.body2.black;
    return SizedBox(width: 294, child: Text(bodyText, style: bodyStyle));
  }

  Widget _buildBuyButton() {
    var text = s.buyCredits.toUpperCase();
    var action = _purchaseOrchidAccount;
    return _buildButton(text: text, onPressed: action);
  }

  Widget _buildUseAnotherAccountButton() {
    var text = s.useAnotherAccount.toUpperCase();
    var action = _importOrchidAccount;
    return _buildButton(text: text, lightColor: true, onPressed: action);
  }

  Widget _buildUseCryptoWalletButton({bool lightColor = false}) {
    var text = s.useCryptoWallet.toUpperCase();
    var action = _openDapp;
    return _buildButton(text: text, lightColor: lightColor, onPressed: action);
  }

  // title row with alert symbol
  Widget _buildTitleRow(String titleText, {bool alert}) {
    var titleStyle = OrchidText.subtitle.black;
    return Padding(
      padding: EdgeInsets.only(top: 24, bottom: 8, left: 24, right: 24),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            if (alert)
              Transform.translate(
                offset: Offset(0, -2),
                child: Icon(Icons.error,
                    color: OrchidColors.dark_ff3a3149, size: 20),
              ),
            if (alert) padx(16),
            RichText(
              text: TextSpan(text: titleText, style: titleStyle),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildCollapsiblePanel({
    Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: OrchidColors.highlight,
        // Needed during the animated collapse - cliprrect doesn't mask during?
        borderRadius: _collapsed
            ? BorderRadius.only(
                bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))
            : null,
      ),
      child: Stack(
        children: [
          content,
          Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: _buildToggleButton(),
              )),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      child: TextButton(
        child: Icon(
          _collapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: OrchidColors.dark_ff3a3149,
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
    bool lightColor = false,
    VoidCallback onPressed,
  }) {
    Color backgroundColor =
        lightColor ? Colors.transparent : OrchidColors.dark_background;
    Color borderColor = OrchidColors.dark_ff3a3149;
    Color textColor = lightColor ? Colors.black : Colors.white;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 294,
        height: 52,
        child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: borderColor, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.all(Radius.circular(16)))),
          onPressed: onPressed,
          child: Text(
            text,
            style: OrchidText.button.copyWith(color: textColor),
          ),
        ),
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
