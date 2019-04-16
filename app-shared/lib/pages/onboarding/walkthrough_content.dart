import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// A informational page consisting of either:
///   - A logo, header text, body text, and image or
///   - header text, body text, and an image.
class WalkthroughContent extends StatelessWidget {
  final String imageName;
  final String titleText;
  final String bodyText;

  /// Show the image below the text without a logo
  final bool imageAtBottom;

  const WalkthroughContent({
    Key key,
    @required this.imageName,
    @required this.titleText,
    @required this.bodyText,
    this.imageAtBottom = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    var headerTextBox = ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 480),
      child: Text(titleText,
          textAlign: TextAlign.center, style: AppText.headerStyle),
    );

    var bodyTextBox = ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 400),
      child: Text(bodyText,
          textAlign: TextAlign.center,
          style: AppText.bodyStyle
              .copyWith(color: AppColors.neutral_2, letterSpacing: 0.25)),
    );

    if (imageAtBottom) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: <Widget>[
              // For large screens distribute the space a bit, else fixed margin.
              screenWidth > 640 ? Spacer(flex: 1) : SizedBox(height: 48),
              headerTextBox,
              SizedBox(height: 20),
              bodyTextBox,
              SizedBox(height: 68),
              Image.asset(imageName),
              Spacer(flex: 2),
            ],
          ));
    } else {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: <Widget>[
              // For large screens distribute the space a bit, else fixed margin.
              screenWidth > 640 ? Spacer(flex: 1) : SizedBox(height: 40),
              Image.asset('assets/images/name_logo.png'),
              SizedBox(height: 28),
              Image.asset(imageName),
              SizedBox(height: 28),
              headerTextBox,
              SizedBox(height: 21),
              bodyTextBox,
              Spacer(flex: 2),
            ],
          ));
    }
  }

  Widget buildText(BuildContext context) {
    return Column(
      children: <Widget>[],
    );
  }
}
