import 'package:flutter/material.dart';

/// An interpolation between two LinearGradients.
class LinearGradientTween extends Tween<LinearGradient> {
  LinearGradientTween({
    required LinearGradient begin,
    required LinearGradient end,
  }) : super(begin: begin, end: end);

  @override
  // both begin and end are non-null
  LinearGradient lerp(double t) => LinearGradient.lerp(begin, end, t)!;
}

/// A LinearGradient that defaults to top to bottom center orientation
class VerticalLinearGradient extends LinearGradient {
  const VerticalLinearGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
    required List<Color> colors,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
  }) : super(
            begin: begin,
            end: end,
            colors: colors,
            stops: stops,
            tileMode: tileMode);
}

class HorizontalLinearGradient extends LinearGradient {
  const HorizontalLinearGradient({
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
    required List<Color> colors,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
  }) : super(
            begin: begin,
            end: end,
            colors: colors,
            stops: stops,
            tileMode: tileMode);
}
