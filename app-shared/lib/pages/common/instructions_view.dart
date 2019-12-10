import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_text.dart';

/// Instructional text with vertically arranged image, title, and body.
/// Optionally hides itself in landscape mode.
class InstructionsView extends StatelessWidget {
  final Image image;
  final String title;
  final String body;
  final bool hideInLandscape;
  final List<Widget> children;
  final double bodyFontSize;

  const InstructionsView(
      {Key key,
      this.image,
      @required this.title,
      @required this.body,
      this.hideInLandscape = true,
      this.children = const <Widget>[],
      this.bodyFontSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textColor = Color(0xff504960);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation builderOrientation) {
        // Orientation builder provides the parent widget orientation, not
        // necessarily the device. Fetch device orientation.
        var orientation = MediaQuery.of(context).orientation;
        return Visibility(
          visible: orientation == Orientation.portrait || !hideInLandscape,
          child: SafeArea(
              child: Column(
            children: <Widget>[
                  //Spacer(flex: 1),
                  image ?? Container(),
                  SizedBox(height: 20),
                  AppText.header(
                      text: title,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 20.0),
                  SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 45),
                      child: AppText.body(
                          text: body,
                          fontWeight: FontWeight.w500,
                          fontSize: bodyFontSize ?? 11.0,
                          color: textColor),
                    ),
                  ),
                ] +
                children +
                <Widget>[
                  Spacer(flex: 1),
                ],
          )),
        );
      },
    );
  }
}
