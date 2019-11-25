import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TapToCopyText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TapToCopyText(this.text, {Key key, this.style}) : super(key: key);

  @override
  _TapToCopyTextState createState() => _TapToCopyTextState();
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
      child: Text(_showText, style: widget.style),
      onTap: _onTap,
    );
  }

  void _onTap() async {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() {
      _showText = "Copied...";
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _showText = widget.text;
    });
  }
}
