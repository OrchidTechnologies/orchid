import 'orchid.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/link_text.dart';
import 'package:styled_text/styled_text.dart';
import 'package:url_launcher/url_launcher.dart';

// This is replacing AppText
// normal = w400 = regular
// medium = w500
class OrchidText {
  static TextStyle extra_large = title.size(22); // w500
  static TextStyle title = medium_20_050; // w500
  static TextStyle subtitle = medium_18_025;

  // Flutter sizes text based on the EM-box, not the font metrics.
  // https://api.flutter.dev/flutter/painting/TextStyle/height.html
  static TextStyle button = medium_18_025.copyWith(height: 1.9);

  static TextStyle highlight = regular_24_050; // w400
  static TextStyle body1 = medium_16_025; // w500
  static TextStyle body2 = regular_16_025; // w400
  static TextStyle caption = regular_14; // w400

  static TextStyle medium_20_050 = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontSize: 20,
      height: 1.0);

  static TextStyle normal_14 = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.normal,
      // w400
      color: Colors.white,
      fontSize: 14,
      height: 1.0);
  static TextStyle regular_14 = normal_14;

  static TextStyle normal_16_025 = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.normal,
      color: Colors.white,
      fontSize: 16,
      height: 1.0,
      letterSpacing: 0.25);
  static TextStyle regular_16_025 = normal_16_025;
  static TextStyle medium_16_025 = normal_16_025.medium;
  static TextStyle medium_14 = normal_14.medium;

  static TextStyle normal_18_025 = TextStyle(
    color: Colors.white,
    fontSize: 18,
    height: 1.0,
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    // w400
    letterSpacing: 0.25,
  );
  static TextStyle regular_18_025 = normal_18_025; // w400
  static TextStyle medium_18_025 = normal_18_025.medium; // w500

  static TextStyle normal_24_050 = TextStyle(
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    color: Colors.white,
    fontSize: 24,
    height: 1.0,
    letterSpacing: 0.50,
  );
  static TextStyle regular_24_050 = normal_24_050;

  static TextStyle medium_24_050 = regular_24_050.medium;

  static TextStyle linkStyle =
      body2.copyWith(decoration: TextDecoration.underline).tappable;

  // ?? migrate to link items below
  static LinkTextSpan buildLearnMoreLinkTextSpan(
      {required BuildContext context, required Color color}) {
    return LinkTextSpan(
      text: S.of(context)!.learnMore,
      style: OrchidText.body2.copyWith(color: color),
      url: OrchidUrls.partsOfOrchidAccount,
    );
  }
}

// todo: move these to a generic util file
extension TextStyleExtensions on TextStyle {
  TextStyle get black {
    return this.copyWith(color: Colors.black);
  }

  TextStyle get red {
    return this.copyWith(color: Colors.red);
  }

  TextStyle get white {
    return this.copyWith(color: Colors.white);
  }

  // mainly for debugging
  TextStyle get orange {
    return this.copyWith(color: Colors.orange);
  }

  TextStyle get medium {
    return this.copyWith(fontWeight: FontWeight.w500);
  }

  TextStyle get semibold {
    return this.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle get bold {
    return this.copyWith(fontWeight: FontWeight.bold);
  }

  TextStyle height(double height) {
    return this.withHeight(height);
  }

  TextStyle withHeight(double height) {
    return this.copyWith(height: height);
  }

  TextStyle size(double size) {
    return this.copyWith(fontSize: size);
  }
}

/// styled_text package extensions
extension LinkTextStyleExtensions on TextStyle {
  /// Create an action tag that opens a URL on tap
  StyledTextActionTag link(String url) {
    return StyledTextActionTag(
      (text, attributes) async {
        await launch(url, forceSafariVC: false);
      },
      style: this,
    );
  }
}

// todo: move these to a generic util file
extension TextExtensions on Text {
  Text copyWith({
    style,
    strutStyle,
    textAlign,
    textDirection,
    locale,
    softWrap,
    overflow,
    textScaleFactor,
    maxLines,
    semanticsLabel,
    textWidthBasis,
    textHeightBehavior,
  }) {
    return Text(
      this.data ?? '',
      style: style ?? this.style,
      strutStyle: strutStyle ?? this.strutStyle,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      locale: locale ?? this.locale,
      softWrap: softWrap ?? this.softWrap,
      overflow: overflow ?? this.overflow,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      maxLines: maxLines ?? this.maxLines,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      textWidthBasis: textWidthBasis ?? textWidthBasis,
      textHeightBehavior: textHeightBehavior ?? textHeightBehavior,
    );
  }
}

extension OrchidTextStyleExtensions on TextStyle {
  TextStyle get purpleBright {
    return this.copyWith(color: OrchidColors.purple_bright);
  }

  TextStyle get newPurpleBright {
    return this.copyWith(color: OrchidColors.new_purple_bright);
  }

  TextStyle get tappable {
    return purpleBright;
  }

  TextStyle get inactive {
    return _copyWithColor(OrchidColors.inactive);
  }

  TextStyle disabledIf(bool isInactive) {
    return isInactive ? this.inactive : this;
  }

  TextStyle enabledIf(bool isActive) {
    return isActive ? this : this.inactive;
  }

  TextStyle get blueHightlight {
    return this.copyWith(color: OrchidColors.blue_highlight);
  }

  TextStyle get linkStyle {
    return this.copyWith(
        color: OrchidColors.tappable, decoration: TextDecoration.underline);
  }

  TextStyle get underlined {
    return this.copyWith(decoration: TextDecoration.underline);
  }

  TextStyle _copyWithColor(Color color) {
    return this.copyWith(color: color);
  }
}

extension OrchidTextExtensions on Text {
  Text get extra_large {
    return this.copyWith(style: OrchidText.extra_large);
  }

  Text get title {
    return this.copyWith(style: OrchidText.title);
  }

  Text get subtitle {
    return this.copyWith(style: OrchidText.subtitle);
  }

  Text get button {
    return this.copyWith(style: OrchidText.button);
  }

  Text get highlight {
    return this.copyWith(style: OrchidText.highlight);
  }

  Text get body1 {
    return this.copyWith(style: OrchidText.body1);
  }

  Text get body2 {
    return this.copyWith(style: OrchidText.body2);
  }

  Text get caption {
    return this.copyWith(style: OrchidText.caption);
  }

  Text get linkStyle {
    return this.copyWith(style: OrchidText.linkStyle);
  }

  Text height(double height) {
    return this.copyWith(style: this.style?.copyWith(height: height));
  }

  Text get white {
    return this.copyWith(style: this.style?.copyWith(color: Colors.white));
  }

  Text get black {
    return this.copyWith(style: this.style?.copyWith(color: Colors.black));
  }

  Text get tappable {
    return this
        .copyWith(style: this.style?.copyWith(color: OrchidColors.tappable));
  }

  Text get error {
    return this
        .copyWith(style: this.style?.copyWith(color: OrchidColors.status_red));
  }

  Text get inactive {
    return withColor(OrchidColors.inactive);
  }

  Text inactiveIf(bool isInactive) {
    return isInactive ? inactive : this;
  }

  Text activeIf(bool isActive) {
    return isActive ? this : inactive;
  }

  Text get new_purple_bright {
    return this.copyWith(
        style: this.style?.copyWith(color: OrchidColors.new_purple_bright));
  }

  Text get center {
    return this.copyWith(textAlign: TextAlign.center);
  }

  Text get bold {
    return this.copyWith(style: this.style?.bold);
  }

  Text get semibold {
    return this.copyWith(style: this.style?.semibold);
  }

  Text get medium {
    return this.copyWith(style: this.style?.medium);
  }

  Widget link({required String url, TextStyle? style}) {
    return RichText(
        key: Key(url),
        text: LinkTextSpan(
          text: this.data,
          style: style ?? this.style,
          url: url,
        ));
  }

  Widget linkButton({required VoidCallback onTapped, TextStyle? style}) {
    return LinkStyleTextButton(
      this.data ?? '',
      style: style ?? this.style,
      onTapped: onTapped,
    );
  }

  Text withColor(Color? color) {
    return this
        .copyWith(style: (this.style ?? TextStyle()).copyWith(color: color));
  }

  Text withStyle(TextStyle style) {
    return this.copyWith(style: style);
  }

  Text withStyleIf(TextStyle style, bool value) {
    return value ? this.withStyle(style) : this;
  }
}
