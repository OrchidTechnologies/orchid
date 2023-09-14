import 'package:flutter/material.dart';
import 'orchid_asset.dart';

/// A wrapper that controls an AnimationController with logic for the logo.
class NeonOrchidLogoController {
  final TickerProvider vsync;
  late AnimationController _animController;
  late AnimationController _offsetController;

  // Listenable for use with AnimatedBuilder
  Listenable get listenable {
    return Listenable.merge([_animController, _offsetController]);
  }

  double get value {
    return _animController.value;
  }

  double get offset {
    return _offsetController.value;
  }

  NeonOrchidLogoController({required this.vsync}) {
    this._animController = AnimationController(
        duration: Duration(milliseconds: 1000), vsync: vsync);
    this._offsetController = AnimationController(
        duration: Duration(milliseconds: 3500), vsync: vsync);
    this._offsetController.repeat(reverse: true);
  }

  void off() {
    _animController.animateTo(0.0);
  }

  void half() {
    _animController.animateTo(0.5);
  }

  void full() {
    _animController.animateTo(1.0);
  }

  void pulseHalf() {
    double low = 0.2;
    double high = 0.50;
    var target = value > (low + high) / 2 ? low : high;
    // a new animation will cancel the current and this will never "complete"
    _animController
        .animateTo(target,
            duration: Duration(milliseconds: 900), curve: Curves.linear)
        .whenComplete(() => pulseHalf());
  }

  void dispose() {
    _animController.dispose();
    _offsetController.dispose();
  }
}

class NeonOrchidLogo extends StatelessWidget {
  final double light; // 0-1 light level
  final double offset; // 0-1 CRT lines offset
  final bool showBackground;

  // curves for the various layers of the logo
  final Curve _crtAnim = const Interval(0.0, 0.5, curve: Curves.linear);
  final Curve _neonAnim = const Interval(0.25, 1.0, curve: Curves.linear);
  final Curve _neonGlowAnim = const Interval(0.5, 1.0, curve: Curves.linear);
  final Curve _backgroundGlowAnim =
      const Interval(0.5, 1.0, curve: Curves.linear);
  final Curve _offsetAnim =
      const Interval(0.0, 1.0, curve: Curves.easeInOutSine);

  const NeonOrchidLogo({
    Key? key,
    this.light = 1.0,
    this.offset = 0.0,
    this.showBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crtSpacing = 11.5;
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (showBackground)
            Opacity(
                opacity: _backgroundGlowAnim.transform(light),
                child: OrchidAsset.image.background_glow),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, _offsetAnim.transform(offset) * crtSpacing),
                child: Opacity(
                    opacity: _neonGlowAnim.transform(light),
                    child: OrchidAsset.image.crt_lines_blue),
              ),
              Opacity(
                  opacity: _crtAnim.transform(light),
                  child: OrchidAsset.image.crt_lines_purple),
              Transform.translate(
                offset: Offset(-12, -22),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                        opacity: _neonGlowAnim.transform(light),
                        child: OrchidAsset.image.logo_glow),
                    Opacity(
                        opacity: _neonAnim.transform(light),
                        child: OrchidAsset.image.logo_neon_stroke),
                    OrchidAsset.image.logo_outline,
                  ],
                ),
              ),
            ],
          ),
          // I think this is preventing an error on the first frame rendering.
          Container(width: 1, height: 1),
        ],
      ),
    );
  }
}
