import 'package:flutter/material.dart';

class AppSizes {
  static const Size iphone_xs = Size(375, 812);
  static const Size iphone_xs_max = Size(414, 896);
}

/// Encapsulate a decision about a value or component that depends on screen height
class AdaptiveHeight<T> {
  final T large;
  final T small;
  final Size thresholdSize;

  const AdaptiveHeight(
      this.large,
      this.small,
      [this.thresholdSize = AppSizes.iphone_xs]);

  /// Return the larger value if the screen height is greater than thresholdSize
  /// height, otherwise return the smaller value.
  T value(BuildContext context) {
    return MediaQuery.of(context).size.height > thresholdSize.height
        ? large
        : small;
  }
}

