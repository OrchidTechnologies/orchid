import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/keys/keys_page.dart';
import '../app_colors.dart';
import '../app_text.dart';

// TODO: Remove if unused
class CircuitEmptyView extends StatelessWidget {
  final VoidCallback addHop;

  const CircuitEmptyView({Key key, this.addHop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return SafeArea(
            child: Stack(
          children: <Widget>[
            // Title, instructions, and image
            Align(
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  Spacer(flex: 1),
                  AppText.header(
                      text: s.protectYourTraffic,
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0),
                  SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 45),
                      child: AppText.body(
                          text: s.setUpYourFirstHopToActivateYourVpnConnection +
                              "\n\n" +
                              s.aHopIsARemoteServerAlongYourPathTo +
                              ' ' +
                              s.eachHopAddsALayerOfIndirectionAndObfuscationTo,
                          fontSize: 15.0,
                          color: AppColors.neutral_1),
                    ),
                  ),
                  Spacer(flex: 1),
                  Visibility(
                    visible: orientation == Orientation.portrait,
                    child: Column(
                      children: <Widget>[
                        Image.asset("assets/images/group3.png"),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: orientation == Orientation.portrait,
                    child: Spacer(flex: 2),
                  ),
                  Visibility(
                    visible: orientation == Orientation.portrait,
                    child: _buildBottomButtonCallout(context, orientation),
                  ),
                ],
              ),
            ),

            Visibility(
              visible: orientation == Orientation.landscape,
              child: _buildBottomButtonCallout(context, orientation),
            ),
          ],
        ));
      },
    );
  }

  // Get started and add hop button
  Widget _buildBottomButtonCallout(BuildContext context, Orientation orientation) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Visibility(
          visible: orientation == Orientation.portrait,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45.0),
            child: AppText.header(
                text: S.of(context).createYourFirstHopToGetStarted,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20.0),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Image.asset("assets/images/drawnArrow.png"),
            FloatingAddButton(onPressed: addHop),
          ],
        ),
      ],
    );
  }
}
