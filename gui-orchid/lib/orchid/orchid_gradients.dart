import 'package:flutter/material.dart';

class OrchidGradients {
  static const Gradient blackGradientBackground = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF221833), Colors.black]);

  static const Gradient bluePinkVerticalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF39C4DA),
        Color(0xFFB88DFC),
        Color(0xFFFF67B9),
      ]);

  static const Gradient bluePinkGradientTLBR = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF39C4DA),
        Color(0xFFB88DFC),
        Color(0xFFFF67B9),
      ]);

  static const LinearGradient pinkBlueGradientTLBR = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF67B9),
        Color(0xFFB88DFC),
        Color(0xFF39C4DA),
      ]);

  static final orchidPanelGradient = LinearGradient(
    begin: Alignment(-0.25, -1.0),
    end: Alignment(0.25, 1.0),
    colors: [Colors.white.withOpacity(0.2), Colors.transparent],
  );

  static final verticalTransparentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withOpacity(0.2), Colors.transparent],
  );

  static final transparentGradientTLBR = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white.withOpacity(0.2), Colors.transparent],
  );

  static final fadeOutBottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.75, 1.0],
    colors: [Colors.transparent, Colors.transparent, Colors.black],
  );
}

extension GradientExtensions on LinearGradient {
  LinearGradient rotated(double angle) {
    return LinearGradient(
      begin: this.begin,
      end: this.end,
      colors: this.colors,
      transform: GradientRotation(angle),
    );
  }
}
