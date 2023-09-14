import 'package:flutter/material.dart';

class GradientBorder extends StatelessWidget {
  final GradientBorderPainter painter;
  final Widget child;
  final bool enabled;

  GradientBorder({
    Key? key,
    GradientBorderPainter? painter,
    required double strokeWidth,
    required double radius,
    required Gradient gradient,
    required this.child,
    this.enabled = true,
  })  : this.painter = painter ??
            GradientBorderPainter(
                strokeWidth: strokeWidth, radius: radius, gradient: gradient),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return CustomPaint(
      foregroundPainter: painter,
      child: child,
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final Paint _paint = Paint();
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  GradientBorderPainter(
      {required double strokeWidth,
      required double radius,
      required Gradient gradient})
      : this.strokeWidth = strokeWidth,
        this.radius = radius,
        this.gradient = gradient;

  @override
  void paint(Canvas canvas, Size size) {
    Rect outerRect = Offset.zero & size;
    var outerRRect =
        RRect.fromRectAndRadius(outerRect, Radius.circular(radius));
    Rect innerRect = Rect.fromLTWH(strokeWidth, strokeWidth,
        size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    var innerRRect = RRect.fromRectAndRadius(
        innerRect, Radius.circular(radius - strokeWidth));

    _paint.shader = gradient.createShader(outerRect);

    // Path path1 = Path()..addRRect(outerRRect);
    // Path path2 = Path()..addRRect(innerRRect);
    // var path = Path.combine(PathOperation.difference, path1, path2);

    Path path = Path()..fillType = PathFillType.evenOdd;
    path.addRRect(outerRRect);
    path.addRRect(innerRRect);

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}
