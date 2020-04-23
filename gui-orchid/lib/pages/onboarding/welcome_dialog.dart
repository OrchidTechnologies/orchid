import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/formatting.dart';
import '../app_colors.dart';

class WelcomeDialog extends StatelessWidget {
  final VoidCallback onBuyCredits;
  final VoidCallback onSeeOptions;

  const WelcomeDialog({
    Key key,
    @required this.onBuyCredits,
    @required this.onSeeOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    S s = S.of(context);
    var textColor = Color(0xff3A3149);
    var bodyStyle = TextStyle(fontSize: 15, color: textColor);

    var topText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text: s.buyPrepaidCreditsToGetStartedTheresNoMonthlyFee,
            style: bodyStyle),
      ],
    );

    var bodyText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text: s.haveAnOrchidAccountOrVpnSubscription,
            style: TextStyle(
                color: textColor,
                fontSize: 17.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                height: 1.29)),
        TextSpan(
            text: "\n\n" + s.linkYourExistingOrchidAccountOrEnterAnOvpnProfile,
            style: TextStyle(
                color: textColor,
                fontSize: 15.0,
                letterSpacing: -0.24,
                height: 1.33)),
      ],
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      contentPadding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                color: Color(0xffE7EAF4),
                child: Padding(
                  padding: EdgeInsets.only(top: 12, left: 30, right: 30),
                  child: Column(
                    children: <Widget>[
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            RichText(
                                text: TextSpan(
                                    text: s.needAnAccount,
                                    style: AppText.dialogTitle.copyWith(
                                        fontWeight: FontWeight.bold))),
                            _buildCloseButton(context)
                          ],
                        ),
                      ),
                      RichText(text: topText),
                      pady(16),
                      Center(
                          child: _buildButton(
                              text: s.buyCredits,
                              onPressed: () {
                                Navigator.pop(context);
                                onBuyCredits();
                              })),
                      pady(24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 12, left: 30, right: 30),
                child: Column(
                  children: <Widget>[
                    pady(16),
                    RichText(text: bodyText),
                    pady(16),
                    Center(
                        child: _buildButton(
                            text: s.seeTheOptions,
                            bgColor: Colors.white,
                            textColor: AppColors.purple_3,
                            onPressed: () {
                              Navigator.pop(context);
                              onSeeOptions();
                            })),
                    pady(16)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildCloseButton(BuildContext context) {
    return Container(
      width: 40,
      child: FlatButton(
        child: Icon(Icons.close),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Container _buildButton(
      {@required String text,
      Color bgColor = AppColors.purple_3,
      Color borderColor = AppColors.purple_3,
      Color textColor = Colors.white,
      VoidCallback onPressed}) {
    return Container(
      width: 210,
      height: 48,
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
}
