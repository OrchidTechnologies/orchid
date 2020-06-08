import 'package:flutter/material.dart';

class AppSize {
  static const Size iphone_se = Size(320, 568);
  static const Size iphone_xs = Size(375, 812); // Original X and Xs
  static const Size iphone_xs_max = Size(414, 896); // Xs Max And Xr

  Size size;

  bool tallerThan(Size targetSize) {
    return size.height > targetSize.height;
  }

  bool widerThan(Size targetSize) {
    return size.width > targetSize.width;
  }

  AppSize(BuildContext context) {
    this.size = MediaQuery.of(context).size;
  }
}

/// Encapsulate a decision about a value or component that depends on screen height
class AdaptiveHeight<T> {
  final T large;
  final T small;
  final Size thresholdSize;

  const AdaptiveHeight(this.large, this.small,
      [this.thresholdSize = AppSize.iphone_xs]);

  /// Return the larger value if the screen height is greater than thresholdSize
  /// height, otherwise return the smaller value.
  T value(BuildContext context) {
    return MediaQuery.of(context).size.height > thresholdSize.height
        ? large
        : small;
  }
}
