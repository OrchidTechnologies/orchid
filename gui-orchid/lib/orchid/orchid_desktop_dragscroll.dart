import 'dart:ui';
import 'package:flutter/material.dart';

// The default scroll behavior on desktop (with a mouse) does not support dragging.
class OrchidDesktopDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}
