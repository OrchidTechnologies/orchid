import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// TODO: Trouble actually using this as a ValueListenable<T>
class PolledValue<T> extends ValueNotifier<T> {
  Timer _timer;

  PolledValue(value) : super(value);

  void poll({@required Duration period, @required Future<T> update()}) async {
    // Kick off the first update immediately
    this.value= await update();
    // Then periodic
    _timer = Timer.periodic(period, (timer) async {
      this.value = await update();
    });
  }

  void cancel() {
    _timer.cancel();
  }
}
