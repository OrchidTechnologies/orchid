import 'dart:ui';
import 'package:flutter/material.dart';

import 'orchid_colors.dart';

class OrchidCircularEfficiencyIndicators {
  // Reeturn the main color and glow color for the efficiency
  static Color colorForEfficiency(double efficiency) {
    return _colorAndGlowColorForEfficiency(efficiency)[0];
  }

  static List<Color> _colorAndGlowColorForEfficiency(double? efficiency) {
    if (efficiency == null || efficiency < 0.3) {
      return [Color(0xffff6f97), Color(0xffff6f97)];
    }
    if (efficiency >= 0.3 && efficiency <= 0.7) {
      return [Color(0xffFFEBAF), Color(0xffffb969)];
    }
    return [Color(0xff6efac8), Color(0xff99f5cb)];
  }

  static OrchidCircularProgressIndicator small(double efficiency,
      {double size = 16}) {
    var colors = _colorAndGlowColorForEfficiency(efficiency);
    return OrchidCircularProgressIndicator(
      size: size,
      value: efficiency,
      color: colors[0],
      glowColor: colors[1],
      blur: 4.0,
      stroke: 2.0,
    );
  }

  static OrchidCircularProgressIndicator medium(double efficiency,
      {double size = 40}) {
    var colors = _colorAndGlowColorForEfficiency(efficiency);
    return OrchidCircularProgressIndicator(
      size: size,
      value: efficiency,
      color: colors[0],
      glowColor: colors[1],
      blur: 4.0,
      stroke: 3.0,
    );
  }

  static OrchidCircularProgressIndicator large(double efficiency) {
    var colors = _colorAndGlowColorForEfficiency(efficiency);
    return OrchidCircularProgressIndicator(
      size: 60,
      value: efficiency,
      color: colors[0],
      glowColor: colors[1],
      blur: 4.0,
      stroke: 5.0,
    );
  }
}

class OrchidCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final double size;
  final Color color;
  final Color glowColor;
  final double blur;
  final double stroke;
  final Color backgroundColor;

  OrchidCircularProgressIndicator({
    Key? key,
    this.value = 0.5,
    this.size = 64.0,
    this.blur = 16.0,
    this.stroke = 2.0,
    this.color = Colors.deepPurple,
    this.glowColor = Colors.deepPurple,
    this.backgroundColor = const Color(0x66FFFFFF),
  }) : super(key: key);

  static OrchidCircularProgressIndicator smallIndeterminate(
      {double size = 20, double stroke = 2.0}) {
    return OrchidCircularProgressIndicator(
      size: size,
      value: null,
      color: OrchidColors.purple_bright,
      glowColor: OrchidColors.purple_bright,
      blur: 4.0,
      stroke: stroke,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.decal,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(color),
              value: value,
              strokeWidth: stroke,
            ),
          ),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(glowColor),
            strokeWidth: stroke,
            value: value,
            backgroundColor: backgroundColor,
          ),
        ],
      ),
    );
  }
}
