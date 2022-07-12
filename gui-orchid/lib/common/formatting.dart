import 'package:flutter/material.dart';

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

  /// Adds the [value] between all elements in the list
  List<Widget> separatedWith(Widget value) {
    var list = List<Widget>.from(this);
    for (int i = this.length - 1; i > 0; i--) {
      list.insert(i, value);
    }
    return list;
  }

  List<Widget> surroundedWith(Widget value) {
    var list = List<Widget>.from(this).separatedWith(value);
    list.insert(0, value);
    list.add(value);
    return list;
  }
}

extension WidgetExtensions on Widget {
  Widget pad(double pad) {
    return Padding(padding: EdgeInsets.all(pad), child: this);
  }

  Widget pady(double pad) {
    return Padding(
        padding: EdgeInsets.only(top: pad, bottom: pad), child: this);
  }

  Widget padx(double pad) {
    return Padding(
        padding: EdgeInsets.only(left: pad, right: pad), child: this);
  }

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

  Widget width(double width) {
    return SizedBox(width: width, child: this);
  }

  Widget height(double height) {
    return SizedBox(height: height, child: this);
  }

  Widget boxHeight(double height) {
    return this.height(height);
  }

  Widget size(double width, double height) {
    return SizedBox(width: width, height: height, child: this);
  }
}
