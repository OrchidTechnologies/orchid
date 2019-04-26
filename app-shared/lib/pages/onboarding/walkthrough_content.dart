import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/app_buttons.dart';

enum WalkthroughContentImageLocation { Top, Bottom }

/// A informational page consisting of a layout of one of the following columns:
///   - Logo, header text, body text, and optional image
///   - Header text, body text, and optional image.
/// Supply only one of bodyText or bodyRichText.
///
class WalkthroughContent extends StatelessWidget {
  final String imageName;
  final String titleText;
  final String bodyText;
  final TextSpan bodyRichText;
  final WalkthroughContentImageLocation imageLocation;

  const WalkthroughContent({
    Key key,
    this.imageName,
    @required this.titleText,
    this.bodyText,
    this.bodyRichText,
    this.imageLocation = WalkthroughContentImageLocation.Top,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(bodyText == null || bodyRichText == null);
    double screenHeight = MediaQuery.of(context).size.height;

    var headerTextBox = WalkthroughHeaderTextBox(titleText: titleText);
    var bodyTextBox = WalkthroughBodyTextBox(bodyText: bodyText, bodyRichText: bodyRichText);
    var image = imageName != null ? Image.asset(imageName) : Container();

    if (imageLocation == WalkthroughContentImageLocation.Top) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: <Widget>[
              // For large screens distribute the space a bit, else fixed margin.
              screenHeight >= AppSizes.iphone_xs.height ? Spacer(flex: 1) : SizedBox(height: 40),
              Image.asset('assets/images/name_logo.png'),
              SizedBox(height: 28),
              image,
              SizedBox(height: 28),
              headerTextBox,
              SizedBox(height: 21),
              bodyTextBox,
              Spacer(flex: 2),
            ],
          ));
    } else {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: <Widget>[
              // For large screens distribute the space a bit, else fixed margin.
              screenHeight >= AppSizes.iphone_xs.height ? Spacer(flex: 1) : SizedBox(height: 48),
              headerTextBox,
              SizedBox(height: 20),
              bodyTextBox,
              SizedBox(height: 68),
              image,
              Spacer(flex: 3),
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

class WalkthroughBodyTextBox extends StatelessWidget {
  const WalkthroughBodyTextBox({
    Key key,
    this.bodyText,
    this.bodyRichText,
  }) : super(key: key);

  final String bodyText;
  final TextSpan bodyRichText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 400),
      child: bodyText != null
          ? Text(bodyText,
              textAlign: TextAlign.center,
              style: AppText.bodyStyle.copyWith(
                  color: AppColors.neutral_2,
                  letterSpacing: 0.25,
                  // TODO: This is an approximation, the numbers in Zeplin would indicate 1.42 but
                  // TODO: that appears way too large.
                  height: 1.23))
          : RichText(
              textAlign: TextAlign.center,
              text: bodyRichText,
            ),
    );
  }
}

class WalkthroughHeaderTextBox extends StatelessWidget {
  const WalkthroughHeaderTextBox({
    Key key,
    @required this.titleText,
  }) : super(key: key);

  final String titleText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 280, maxWidth: 480),
      child: Text(titleText,
          textAlign: TextAlign.center, style: AppText.headerStyle),
    );
  }
}

/// A column of next / skip ("do this later") buttons used with walkthrough content.
class NextSkipButtons {
  static Column build(
      {@required VoidCallback onNext, @required VoidCallback onSkip}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildNextButton(onNext: onNext),
        SizedBox(height: 4),
        LinkStyleTextButton(
          "I'll do this later",
          onPressed: onSkip,
        ),
        SizedBox(height: 12)
      ],
    );
  }

  static Container buildNextButton({VoidCallback onNext}) {
    return Container(
          width: 180,
          child: RoundedRectRaisedButton(
            text: 'NEXT',
            onPressed: onNext,
          ));
  }
}
