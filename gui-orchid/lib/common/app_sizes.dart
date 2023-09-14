import 'package:flutter/material.dart';

class AppSize {
  static const Size small_android = Size(360, 640);
  static const Size iphone_se = Size(320, 568);
  static const Size iphone_xs = Size(375, 812); // Original X and Xs
  static const Size iphone_12_pro_max = Size(428, 926);

  Size size;

  AppSize(BuildContext context) : this.size = MediaQuery.of(context).size;

  bool tallerThan(Size targetSize) {
    return size.height > targetSize.height;
  }

  bool shorterThan(Size targetSize) {
    return !tallerThan(targetSize);
  }

  bool widerThan(Size targetSize) {
    return size.width > targetSize.width;
  }

  bool narrowerThan(Size targetSize) {
    return !widerThan(targetSize);
  }

  bool narrowerThanWidth(double width) {
    return !widerThan(Size(width, 0));
  }

  static Widget constrainMaxSizeDefaults(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 450, maxHeight: AppSize.iphone_12_pro_max.height),
          child: child),
    );
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
