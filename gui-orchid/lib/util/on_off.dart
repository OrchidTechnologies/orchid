import 'dart:async';
import 'package:flutter/widgets.dart';

/// Sometimes useful for comparing or debugging visual effects
class OnOff extends StatefulWidget {
  final bool on;
  final Duration rate;
  final Widget Function(BuildContext context, bool on) builder;

  OnOff({
    Key key,
    this.on,
    this.rate = const Duration(milliseconds: 500),
    this.builder,
  }) : super(key: key);

  @override
  _OnOffState createState() => _OnOffState();
}

class _OnOffState extends State<OnOff> {
  bool on = true;
  Timer timer;

  void initState() {
    super.initState();
    timer = Timer.periodic(widget.rate, (timer) {
      setState(() {
        on = !on;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.on ?? on);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
