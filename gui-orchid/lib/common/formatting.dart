
import 'package:flutter/material.dart';

// TODO: Move to util

Widget padx(double width) {
  return SizedBox(width: width);
}

Widget pady(double height) {
  return SizedBox(height: height);
}

extension WidgetListExtensions<Widget> on List<Widget> {
  /// Adds the [value] between all elements in the list
  void spaced(double value) {
    for (int i = this.length - 1; i > 0; i--) {
      this.insert(i, SizedBox(width: value, height: value) as Widget);
    }
  }
}
