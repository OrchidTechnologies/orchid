import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

/// The paged introductory screens.
/// Adapted from: https://github.com/pyozer/introduction_screen
class WalkthroughPages extends StatefulWidget {
  final bool showSkipButton;
  final ValueChanged<int> onChange;
  final Size dotSize;
  final EdgeInsets dotsSpacing;
  final bool isProgress;
  final int animationDuration;

  WalkthroughPages({
    Key key,
    this.showSkipButton = true,
    this.onChange,
    this.dotSize = const Size.fromRadius(5.0),
    this.dotsSpacing = const EdgeInsets.all(12.0),
    this.isProgress = true,
    this.animationDuration = 300,
  }) : super(key: key);

  @override
  _IntroductionScreenState createState() => _IntroductionScreenState();

  Widget buildPage(BuildContext context,
      {String imageName, String titleText, String bodyText}) {
    double screenWidth = MediaQuery.of(context).size.width;
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
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 280, maxWidth: 480),
              child: Text(titleText,
                  textAlign: TextAlign.center, style: AppText.headerStyle),
            ),
            SizedBox(height: 21),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 280, maxWidth: 400),
              child: Text(bodyText,
                  textAlign: TextAlign.center,
                  style: AppText.bodyStyle.copyWith(
                      color: AppColors.neutral_2, letterSpacing: 0.25)),
            ),
            Spacer(flex: 2),
          ],
        ));
  }

  List<Widget> buildPages(BuildContext context) {
    return [
      buildPage(context,
          imageName: 'assets/images/illustration_1.png',
          titleText: "You've arrived at the natural internet",
          bodyText:
              "At Orchid, our mission is to create open internet access for everyone, everywhere.\n\nIt starts here with our decentralized, secure, private, open-source VPN."),
      buildPage(context,
          imageName: 'assets/images/illustration_2.png',
          titleText: "We're breaking down information barriers",
          bodyText:
              "We believe in ad-free, unrestricted bandwidth without censorship and regional restrictions.\n\nOrchid is decentralized, which means that your information won't be stored or owned by any one corporation or person."),
      buildPage(context,
          imageName: 'assets/images/illustration_3.png',
          titleText: "Thanks for being an Alpha user!",
          bodyText:
              "We appreciate you taking part and would love to hear your feedback! Look for our feedback tab in the navigation drawer.")
    ];
  }
}

class _IntroductionScreenState extends State<WalkthroughPages> {
  PageController _pageController;
  int _currentPage = 0;
  bool _isSkipPressed = false;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  void _onNext() {
    animateScroll(min(_currentPage + 1, widget.buildPages(context).length - 1));
  }

  void onDone() {
    UserPreferences().setWalkthroughCompleted(true);
    Navigator.of(context).pop();
  }

  Future<void> _onSkip() async {
    setState(() => _isSkipPressed = true);
    await animateScroll(widget.buildPages(context).length - 1);
    setState(() => _isSkipPressed = false);
  }

  Future<void> animateScroll(int page) async {
    setState(() => _isScrolling = true);
    await _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: widget.animationDuration),
      curve: Curves.easeIn,
    );
    setState(() => _isScrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    var pages = widget.buildPages(context);
    final isLastPage = (_currentPage == pages.length - 1);
    bool isSkipBtn = (!_isSkipPressed && !isLastPage && widget.showSkipButton);

    final skipBtn = Opacity(
      opacity: isSkipBtn ? 1.0 : 0.0,
      child: ControlButton("SKIP", onPressed: _onSkip),
    );

    final nextBtn = ControlButton(
      "NEXT",
      color: AppColors.purple_2,
      alignment: TextAlign.right,
      onPressed: _isScrolling ? null : _onNext,
    );

    final doneBtn = ControlButton(
      "DONE",
      color: AppColors.purple_2,
      onPressed: onDone,
    );

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(4),
          // Min space with no custom widgets
          child: AppBar(backgroundColor: AppColors.purple, elevation: 0.0)),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.grey_7, AppColors.grey_6])),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: BouncingScrollPhysics(),
                children: pages,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (widget.onChange != null) widget.onChange(index);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Row(
                children: [
                  skipBtn,
                  Expanded(
                    child: Center(
                      child: widget.isProgress
                          ? DotsIndicator(
                              numberOfDot: pages.length,
                              position: _currentPage,
                              dotSpacing: widget.dotsSpacing,
                              dotSize: widget.dotSize,
                              dotActiveSize: widget.dotSize,
                              dotActiveColor: AppColors.purple_3,
                              dotColor: AppColors.purple_3.withOpacity(0.3),
                            )
                          : const SizedBox(),
                    ),
                    flex: 36,
                  ),
                  isLastPage ? doneBtn : nextBtn,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  String text;
  TextAlign alignment;
  Color color;

  ControlButton(this.text,
      {this.alignment = TextAlign.left,
      this.onPressed,
      this.color = AppColors.grey_3});

  @override
  Widget build(BuildContext context) {
    var textStyle =
        AppText.buttonStyle.copyWith(color: color, letterSpacing: 1.25);
    var textChild = Text(text, textAlign: alignment, style: textStyle);

    return FlatButton(
      //color: Colors.green,
      onPressed: onPressed,
      child: textChild,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }
}

/// From https://github.com/Pyozer/dots_indicator
class DotsIndicator extends StatelessWidget {
  static const Size kDefaultSize = const Size.square(9.0);
  static const EdgeInsets kDefaultSpacing = const EdgeInsets.all(6.0);
  static const ShapeBorder kDefaultShape = const CircleBorder();

  final int numberOfDot;
  final int position;
  final Color dotColor;
  final Color dotActiveColor;
  final Size dotSize;
  final Size dotActiveSize;
  final ShapeBorder dotShape;
  final ShapeBorder dotActiveShape;
  final EdgeInsets dotSpacing;

  DotsIndicator(
      {Key key,
      @required this.numberOfDot,
      this.position = 0,
      this.dotColor = Colors.grey,
      this.dotActiveColor = Colors.lightBlue,
      this.dotSize = kDefaultSize,
      this.dotActiveSize = kDefaultSize,
      this.dotShape = kDefaultShape,
      this.dotActiveShape = kDefaultShape,
      this.dotSpacing = kDefaultSpacing})
      : assert(numberOfDot != null),
        assert(position != null),
        assert(dotColor != null),
        assert(dotActiveColor != null),
        assert(dotSize != null),
        assert(dotActiveSize != null),
        assert(dotShape != null),
        assert(dotActiveShape != null),
        assert(dotSpacing != null),
        assert(position < numberOfDot,
            "The position must be inferior of numberOfDot (position start at 0). Example for active last dot: numberOfDot=3 / position=2"),
        super(key: key);

  List<Widget> _buildDots() {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDot; i++) {
      final color = (i == position) ? dotActiveColor : dotColor;
      final size = (i == position) ? dotActiveSize : dotSize;
      final shape = (i == position) ? dotActiveShape : dotShape;

      dots.add(
        Container(
          width: size.width,
          height: size.height,
          margin: dotSpacing,
          decoration: ShapeDecoration(color: color, shape: shape),
        ),
      );
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildDots(),
      ),
    );
  }
}
