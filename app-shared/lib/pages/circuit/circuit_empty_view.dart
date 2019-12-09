import 'package:flutter/material.dart';
import 'package:orchid/pages/keys/keys_page.dart';
import '../app_colors.dart';
import '../app_text.dart';

// TODO: Remove if unused
class CircuitEmptyView extends StatelessWidget {
  final VoidCallback addHop;

  const CircuitEmptyView({Key key, this.addHop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      text: "Protect your traffic",
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0),
                  SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 45),
                      child: AppText.body(
                          text:
                              "Set up your first hop to activate your  VPN connection.\n\nA ‘hop’ is a remote server along your path to the internet that your traffic is routed through. Each hop adds a layer of indirection and obfuscation to your connection.",
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
                    child: _buildBottomButtonCallout(orientation),
                  ),
                ],
              ),
            ),

            Visibility(
              visible: orientation == Orientation.landscape,
              child: _buildBottomButtonCallout(orientation),
            ),
          ],
        ));
      },
    );
  }

  // Get started and add hop button
  Widget _buildBottomButtonCallout(Orientation orientation) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Visibility(
          visible: orientation == Orientation.portrait,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45.0),
            child: AppText.header(
                text: "Create your first hop to get started.",
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
