import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A text span that is styled as a link and launches an external web viewer
/// for the associated URL.
class LinkTextSpan extends TextSpan {
  LinkTextSpan({TextStyle? style, required String url, String? text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(url, forceSafariVC: false);
              });
}

class LinkText extends StatelessWidget {
  final TextStyle? style;
  final String? url;
  final VoidCallback? onTapped;
  final String? text;
  final TextOverflow overflow;

  LinkText(this.text,
      {this.style,
      this.url,
      this.onTapped,
      this.overflow = TextOverflow.ellipsis});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Text(text ?? url ?? '', style: style, overflow: overflow),
      onTap: onTapped ?? _openURL,
    );
  }

  _openURL() {
    launch(url ?? '', forceSafariVC: false);
  }
}
