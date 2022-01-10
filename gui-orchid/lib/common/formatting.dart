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

extension PaddingExtensions on Widget {
  Widget top(double pad) {
    return Padding(padding: EdgeInsets.only(top: pad), child: this);
  }
  Widget bottom(double pad) {
    return Padding(padding: EdgeInsets.only(bottom: pad), child: this);
  }
  Widget left(double pad) {
    return Padding(padding: EdgeInsets.only(left: pad), child: this);
  }
  Widget right(double pad) {
    return Padding(padding: EdgeInsets.only(right: pad), child: this);
  }
}
