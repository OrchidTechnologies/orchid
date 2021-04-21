import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_account_config/orchid_account_v1.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/circuit/circuit_page.dart';
import 'package:orchid/common/scan_paste_account.dart';
import 'package:orchid/common/formatting.dart';
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
            child: _collapsed ? _buildClosedView() : _buildOpenView()),
      ),
    );
  }

  Widget _buildOpenView() {
    var iOSText = s.purchaseOrchidCreditsToConnectWithOrchid;
    var androidText = s.createOrLinkAnOrchidAccountImportAnOvpnProfile;
    var text = isApple ? iOSText : androidText;

    var iosButtonText = s.buyOrchidCredits;
    var androidButtonText = s.setup;
    var buttonText = isApple ? iosButtonText : androidButtonText;
    var buttonAction = isApple ? _onBuyCredits : _onDoSetup;

    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var topTextSpan = TextSpan(
      children: <TextSpan>[
        TextSpan(text: text, style: bodyStyle),
      ],
    );

    return Container(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTop(
              topText: topTextSpan,
              buttonText: buttonText,
              onPressed: buttonAction,
            ),
            Container(height: 0.5, color: AppColors.grey_6), // divider
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Container _buildBottom() {
    var iOSTitleText = s.haveAnOrchidAccountOrOxt;
    var androidTitleText = s.alreadyHaveAnOrchidAccount;
    var titleText = isApple ? iOSTitleText : androidTitleText;

    var iOSText = s.createOrLinkAnOrchidAccountImportAnOvpnProfile;
    var androidText = s.scanOrPasteYourExistingAccountBelow;
    var text = isApple ? iOSText : androidText;

    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var bodyText = TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: titleText,
          style: TextStyle(
              color: AppColors.neutral_1,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 16.0 / 12.0),
        ),
        TextSpan(text: '\n\n' + text, style: bodyStyle),
      ],
    );

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: 12, left: 22, right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            pady(16),
            RichText(text: bodyText),
            pady(16),
            if (isApple)
              Center(
                  child: _buildButton(
                      text: s.customSetup,
                      bgColor: Colors.white,
                      textColor: AppColors.teal_3,
                      onPressed: _onDoSetup))
            else
              ScanOrPasteOrchidAccount(
                onImportAccount: (ParseOrchidAccountResult result) async {
                  var hop = await OrchidVPNConfigV0.importAccountAsHop(
                      result.account);
                  CircuitUtils.addHopToCircuit(hop);
                },
                v0Only: true,
              ),
            pady(16)
          ],
        ),
      ),
    );
  }

  // open or closed view top, same structure
  Container _buildTop(
      {TextSpan topText, String buttonText, VoidCallback onPressed}) {
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
      child: Padding(
        padding: EdgeInsets.only(top: 0, bottom: 0, left: 22, right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Icon(Icons.error, color: AppColors.teal_3, size: 20),
                    padx(9),
                    RichText(
                        text: TextSpan(
                      text: s.newToOrchid,
                      style: TextStyle(
                          color: AppColors.neutral_1,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 16.0 / 12.0),
                    )),
                  ],
                ),
                _buildToggleButton(context)
              ],
            ),
            RichText(text: topText),
            pady(16),
            if (buttonText != null) ...[
              Center(
                  child: _buildButton(
                text: buttonText,
                onPressed: onPressed,
              )),
              pady(24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClosedView() {
    var iosText = s.purchaseOrchidCreditsLinkAnAccountOrOvpnProfileTo;
    var androidText = s.createAnOrchidAccountLinkAnExistingAccountOrImport;
    var topText = isApple ? iosText : androidText;

    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var topTextSpan = TextSpan(
      children: <TextSpan>[
        TextSpan(text: topText, style: bodyStyle),
      ],
    );

    return Container(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTop(topText: topTextSpan),
          ],
        ),
      ),
    );
  }

  Container _buildToggleButton(BuildContext context) {
    return Container(
      width: 40,
      child: FlatButton(
        child: Icon(
          _collapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppColors.neutral_1,
        ),
        onPressed: () {
          //Navigator.of(context).pop();
          setState(() {
            _collapsed = !_collapsed;
          });
        },
      ),
    );
  }

  Container _buildButton(
      {@required String text,
      Color bgColor = AppColors.teal_3,
      Color borderColor = AppColors.teal_3,
      Color textColor = Colors.white,
      VoidCallback onPressed}) {
    return Container(
      width: 197,
      height: 36,
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

  void _onBuyCredits() {
    // TODO: V1
    // CircuitUtils.purchasePAC(context);
  }

  void _onDoSetup() {
    CircuitUtils.addHop(context);
  }

  S get s {
    return S.of(context);
  }
}
