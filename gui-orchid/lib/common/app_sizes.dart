import 'package:flutter/material.dart';

// TODO: Rename AppWidth
// Note: we separate AppSize and AppWidth to avoid binding widgets to changes in the app height
// unnecessarily. MediaQuery is an inherited widget and can cause unnecessary rebuilds when the layout
// changes, e.g. when the keyboard opens or closes.
class AppSize {
  static const Size small_android = Size(360, 640);
  static const Size iphone_se = Size(320, 568);
  static const Size iphone_xs = Size(375, 812); // Original X and Xs
  static const Size iphone_12_pro_max = Size(428, 926);

  double width;

  // sizeOf().width does not subscribe to height and so the inherited widget won't keep updating
  // on height changues due to e.g. keyboard opening.
  // AppSize(BuildContext context) : this.size = MediaQuery.of(context).size;
  AppSize(BuildContext ctx) : width = MediaQuery.sizeOf(ctx).width;

  bool widerThan(Size targetSize) {
    return width > targetSize.width;
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

class AppHeight {
  double height;

  AppHeight(BuildContext ctx) : height = MediaQuery.sizeOf(ctx).height;

  bool tallerThan(Size targetSize) {
    return height > targetSize.height;
  }

  bool shorterThan(Size targetSize) {
    return !tallerThan(targetSize);
  }
}
