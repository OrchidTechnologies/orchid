import 'package:flutter/material.dart';

import 'style.dart';

class LogViewController {
  final key = GlobalKey<LogViewState>();

  void log(String s) {
    key.currentState?.log(s);
  }

  int length() {
    return key.currentState?.length() ?? 0;
  }
}

class LogView extends StatefulWidget {
  final bool autohide;

  LogView({
    LogViewController controller,
    this.autohide = true,
  }) : super(key: controller.key);

  @override
  LogViewState createState() => LogViewState();
}

class LogViewState extends State<LogView> {
  String _logText = "";

  void log(String s) {
    setState(() {
      _logText += s + "\n";
    });
  }

  int length() {
    return _logText.length;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget.autohide || length() > 0,
      child: Container(
        constraints: BoxConstraints(maxHeight: 400),
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _logText,
            textAlign: TextAlign.left,
            style: logStyle,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          border: Border.all(width: 2.0, color: neutral_5),
        ),
      ),
    );
  }
}
