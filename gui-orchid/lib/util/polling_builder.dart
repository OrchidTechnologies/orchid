// @dart=2.9
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_crypto.dart';

/// A builder widget that polls an async resource requiring disposal.
class PollingBuilder<T> extends StatefulWidget {
  final Duration duration;
  final Future<T> Function() poll;
  final Widget Function(T arg) builder;

  PollingBuilder({
    Key key,
    @required this.duration,
    @required this.poll,
    @required this.builder,
  }) : super(key: key) {
    if (this.duration.inMilliseconds <= 0) {
      throw Exception("invalid duration: ${this.duration}");
    }
  }

  PollingBuilder.interval({
    Key key,
    int seconds,
    int millis,
    Future<T> Function() poll,
    Widget Function(T arg) builder,
  }) : this(
            key: key,
            duration:
                Duration(milliseconds: (seconds ?? 0) * 1000 + (millis ?? 0)),
            poll: poll,
            builder: builder);

  @override
  State<PollingBuilder> createState() => _PollingBuilderState();
}

class _PollingBuilderState<T> extends State<PollingBuilder<T>> {
  String _name;
  Timer _timer;
  T _currentValue;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.duration, _update);
    _update(null); // invoke immediately
    _name = Crypto.uuid();
  }

  void _update(_) async {
    // log("XXX: polling builder ($_name) update, duration = ${widget.duration.inMilliseconds}");
    _currentValue = await widget.poll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // log("XXX: polling builder ($_name) build");
    return widget.builder(_currentValue);
  }

  @override
  void dispose() {
    // log("XXX: polling builder ($_name) dispose");
    _timer.cancel();
    super.dispose();
  }
}
