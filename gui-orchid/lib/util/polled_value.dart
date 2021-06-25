import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PolledValue<T> extends ValueNotifier<T> {
  Timer _timer;

  PolledValue(value) : super(value);

  void poll({@required Duration period, @required Future<T> update()}) async {
    _timer = Timer.periodic(period, (timer) async {
      this.value = await update();
    });

    // Kick off the first update
    this.value = await update();
  }

  void cancel() {
    _timer.cancel();
  }

  void dispose() {
    super.dispose();
    cancel();
  }
}
