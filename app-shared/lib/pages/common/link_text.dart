import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A text span that is styled as a link and launches an external web viewer
/// for the associated URL.
class LinkTextSpan extends TextSpan {
  LinkTextSpan({TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(url, forceSafariVC: false);
              });
}

class LinkText extends StatelessWidget {
  TextStyle style;
  String url;
  String text;
  TextOverflow overflow;

  LinkText(this.text, {this.style, @required this.url, this.overflow = TextOverflow.ellipsis});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Text(text ?? url, style: style, overflow: overflow),
      onTap: () {
        launch(url, forceSafariVC: false);
      },
    );
  }
}
