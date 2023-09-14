import 'dart:async';
import 'package:flutter/material.dart';

/// Sometimes useful for comparing or debugging visual effects
class OnOff extends StatefulWidget {
  final bool? on;
  final Duration rate;
  final Widget Function(BuildContext context, bool on) builder;

  OnOff({
    Key? key,
    this.on,
    this.rate = const Duration(milliseconds: 500),
    required this.builder,
  }) : super(key: key);

  @override
  _OnOffState createState() => _OnOffState();
}

class _OnOffState extends State<OnOff> {
  bool on = true;
  late Timer timer;

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

Widget orange(Widget child) {
  return DebugColor(child: child);
}

extension DebugExtension on Widget {
  Widget get orange {
    return DebugColor(child: this);
  }

  Widget get green {
    return DebugColor(child: this, color: Colors.green);
  }

  Widget get show {
    return DebugColor(child: this, color: Colors.white.withOpacity(0.4));
  }
}

class DebugColor extends StatelessWidget {
  final Widget? child;
  final Color color;

  const DebugColor({Key? key, this.child, this.color = Colors.orange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: child ?? SizedBox(width: 200, height: 200),
    );
  }
}
