import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

/// A simple widget that rebuilds at an interval
class TimedBuilder<T> extends StatefulWidget {
  final Duration duration;
  final Widget Function(BuildContext context) builder;

  TimedBuilder({
    Key? key,
    required this.duration,
    required this.builder,
  }) : super(key: key) {
    if (this.duration.inMilliseconds <= 0) {
      throw Exception("invalid duration: ${this.duration}");
    }
  }

  TimedBuilder.interval({
    int? seconds,
    int? millis,
    required Widget Function(BuildContext context) builder,
  }) : this(
            duration:
                Duration(milliseconds: (seconds ?? 0) * 1000 + (millis ?? 0)),
            builder: builder);

  @override
  State<TimedBuilder> createState() => _TimedBuilderState();
}

class _TimedBuilderState<T> extends State<TimedBuilder<T>> {
  late String _name;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.duration, _update);
    _update(null); // invoke immediately
    _name = Uuid().v4();
  }

  void _update(_) async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
