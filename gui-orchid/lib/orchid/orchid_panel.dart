import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:orchid/common/blend_mask.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

class OrchidPanel extends StatelessWidget {
  final Widget child;
  final Gradient edgeGradient;
  final double edgeStrokeWidth;
  final bool highlight;
  final double highlightAnimation;

  const OrchidPanel({
    Key key,
    this.child,
    this.edgeGradient,
    this.edgeStrokeWidth = 1.5,
    this.highlight = false,
    this.highlightAnimation = 0,
  }) : super(key: key);

  // animation 0-1
  static Gradient highlightGradient(double animation) {
    return OrchidGradients.pinkBlueGradientTLBR.rotated(animation * 2 * 3.1415);
  }

  @override
  Widget build(BuildContext context) {
    // Figma design
    // var fill = Color(0x403a3149);
    var fill = Color(0x503a3149);
    var backgroundGradient = LinearGradient(
      begin: Alignment(-0.2, -1.4),
      end: Alignment(0.2, 1.4),
      // Figma design
      // colors: [Color(0x40ffffff), Color(0x00ffffff)],
      colors: [Color(0xA0ffffff), Color(0x00ffffff)],
    );

    return ClipRect(
      child: Container(
        // Figma specifies a screen blend mode here but this blend mask does
        // not work over the backdrop filter, which can only apply to the
        // last Skia layer.
        // https://github.com/flutter/flutter/issues/48212#issuecomment-575886050
        // child: BlendMask(
        //   blendMode: BlendMode.screen,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
          child: GradientBorder(
            strokeWidth: edgeStrokeWidth,
            radius: 16,
            gradient: highlight
                ? highlightGradient(highlightAnimation)
                : (edgeGradient ?? OrchidGradients.orchidPanelGradient),
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: backgroundGradient,
                  backgroundBlendMode: BlendMode.overlay, // XXX
                  borderRadius: BorderRadius.circular(16),
                ),

                // Adding a 1% opacity here seems to solve the glitching where the
                // gradient blend mode disappears briefly with certain user interactions.
                // https://github.com/flutter/flutter/issues/57205
                // This fix came from an observation here:
                // https://github.com/flutter/flutter/issues/24031#issuecomment-439175309
                // "use an Opacity to force an offscreen buffer"
                child: Opacity(
                  opacity: 0.99,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
