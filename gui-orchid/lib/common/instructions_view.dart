// @dart=2.9
import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_text.dart';

/// Instructional text with vertically arranged image, title, and body.
/// Optionally hides itself in landscape mode.
class InstructionsView extends StatelessWidget {
  final Image image;
  final String title;
  final Color titleColor;
  final String body;
  final bool hideInLandscape;
  final List<Widget> children;
  final double bodyFontSize;

  const InstructionsView({
    Key key,
    this.image,
    @required this.title,
    this.body,
    this.hideInLandscape = true,
    this.children = const <Widget>[],
    this.bodyFontSize,
    this.titleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textColor = Colors.white;
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
                        image ?? Container(),
                        SizedBox(height: 20),
                        Text(title, style: OrchidText.subtitle.copyWith(color: titleColor ?? textColor)),
                        SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 450),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 45),
                            child: body != null ?
                                Text(body, style: OrchidText.body2.copyWith(color: textColor))
                                : Container(),
                          ),
                        ),
                      ] +
                      children)),
        );
      },
    );
  }
}
