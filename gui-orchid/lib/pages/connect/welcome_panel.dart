import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/circuit/circuit_page.dart';
import 'package:orchid/pages/common/formatting.dart';
import '../app_colors.dart';

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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
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
    S s = S.of(context);
    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var topText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text: "Purchase Orchid Credits to connect with Orchid.",
            style: bodyStyle),
      ],
    );

    return Container(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTop(
              topText: topText,
              buttonText: "Buy Orchid Credits",
              onPressed: _onBuyCredits,
            ),
            Container(height: 0.5, color: AppColors.grey_6), // divider
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Container _buildBottom() {
    S s = S.of(context);
    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var bodyText = TextSpan(
      children: <TextSpan>[
        TextSpan(
          text: "Have an Orchid Account or OXT?",
          style: TextStyle(
              color: AppColors.neutral_1,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 16.0 / 12.0),
        ),
        TextSpan(
            text:
                "\n\nCreate or link an Orchid account, import an OVPN profile or build a multi-hop connection.",
            style: bodyStyle),
      ],
    );

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: 12, left: 22, right: 22),
        child: Column(
          children: <Widget>[
            pady(16),
            RichText(text: bodyText),
            pady(16),
            Center(
                child: _buildButton(
              text: "Custom Setup",
              bgColor: Colors.white,
              textColor: AppColors.teal_3,
              onPressed: _onDoSetup
            )),
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
                      text: "New to Orchid?",
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
    var textColor = AppColors.neutral_1;
    var bodyStyle = TextStyle(fontSize: 12, height: 16 / 12, color: textColor);
    var topText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text:
                "Purchase Orchid Credits, link an account or OVPN profile to get started.",
            style: bodyStyle),
      ],
    );

    return Container(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTop(topText: topText),
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

  void _onBuyCredits() {
    CircuitUtils.purchasePAC(context);
  }

  void _onDoSetup() {
    CircuitUtils.addHop(context);

  }
}
