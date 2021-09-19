import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/common/link_text.dart';
import 'orchid_colors.dart';
import 'package:styled_text/styled_text.dart';
import 'package:url_launcher/url_launcher.dart';

// This is replacing AppText
// normal = w400 = regular
// medium = w500
class OrchidText {
  static TextStyle title = medium_20_050;
  static TextStyle subtitle = medium_18_025;

  // Flutter sizes text based on the EM-box, not the font metrics.
  // https://api.flutter.dev/flutter/painting/TextStyle/height.html
  static TextStyle button = medium_18_025.copyWith(height: 1.9);

  static TextStyle highlight = regular_24_050;
  static TextStyle body1 = medium_16_025;
  static TextStyle body2 = regular_16_025;
  static TextStyle caption = regular_14;

  static TextStyle medium_20_050 = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontSize: 20,
      height: 1.0);

  static TextStyle normal_14 = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.normal,
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

  static TextStyle normal_18_025 = TextStyle(
    color: Colors.white,
    fontSize: 18,
    height: 1.0,
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );
  static TextStyle regular_18_025 = normal_18_025;
  static TextStyle medium_18_025 = normal_18_025.medium;

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

  static LinkTextSpan buildLearnMoreLinkTextSpan(
      {BuildContext context, Color color}) {
    return LinkTextSpan(
      text: S.of(context).learnMore,
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

  TextStyle get bold {
    return this.copyWith(fontWeight: FontWeight.bold);
  }
}

/// styled_text package extensions
extension LinkTextStyleExtensions on TextStyle {
  /// Create an action tag that opens a URL on tap
  StyledTextActionTag link(String url) {
    return StyledTextActionTag(
      (text, attributes) {
        return launch(url, forceSafariVC: false);
      },
      style: this,
    );
  }
}

// todo: move these to a generic util file
extension TextExtensions on Text {
  Text copyWith(
    String data, {
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
      data ?? this.data,
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
  TextStyle get tappable {
    return purpleBright;
  }

  TextStyle get linkStyle {
    return this.copyWith(
        color: OrchidColors.purple_ffb88dfc,
        decoration: TextDecoration.underline);
  }
}

extension OrchidTextExtensions on Text {
  Text get title {
    return this.copyWith(this.data, style: OrchidText.title);
  }

  Text get button {
    return this.copyWith(this.data, style: OrchidText.button);
  }

  Text get highlight {
    return this.copyWith(this.data, style: OrchidText.highlight);
  }

  Text get body1 {
    return this.copyWith(this.data, style: OrchidText.body1);
  }

  Text get body2 {
    return this.copyWith(this.data, style: OrchidText.body2);
  }

  Text get caption {
    return this.copyWith(this.data, style: OrchidText.caption);
  }
}
