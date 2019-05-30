import 'dart:ui';

/// Path related utilities
class Paths {

  /// Given points [start] and [end] calculate the quadratic bezier curve
  /// control point necessary for the curve to pass through a third
  /// point [midTarget] at the halfway point of the curve.
  /// https://stackoverflow.com/a/6712095/74975
  static Offset bezierControlForThreePoints(
      Offset start, Offset midTarget, Offset end) {
    var xc = 2 * midTarget.dx - start.dx / 2 - end.dx / 2;
    var yc = 2 * midTarget.dy - start.dy / 2 - end.dy / 2;
    return Offset(xc, yc);
  }

  /// Create a quadratic bezier curve beginning at point [start], passing
  /// through point [mid] at the halfway point of the curve, and ending at [end].
  static Path bezierThroughThreePoints(Offset start, Offset mid, Offset end) {
    Offset control = bezierControlForThreePoints(start, mid, end);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }
}
