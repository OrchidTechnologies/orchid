import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TapToCopyText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final EdgeInsets padding;

  // Callback to be used in lieu of the default copy functionality
  final void Function(String text) onTap;

  const TapToCopyText(this.text,
      {Key key, this.style, this.padding, this.onTap})
      : super(key: key);

  @override
  _TapToCopyTextState createState() => _TapToCopyTextState();

  static copyTextToClipboard(String text) async {
    return Clipboard.setData(ClipboardData(text: text));
  }
}

class _TapToCopyTextState extends State<TapToCopyText> {
  String _showText = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      _showText = widget.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.only(top: 16, bottom: 16),
        child: Text(
          _showText,
          overflow: TextOverflow.ellipsis,
          style: widget.style,
        ),
      ),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap(widget.text);
        } else {
          _doCopy();
        }
      },
    );
  }

  void _doCopy() async {
    TapToCopyText.copyTextToClipboard(widget.text);
    setState(() {
      _showText = S.of(context).copied;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _showText = widget.text;
    });
  }
}
