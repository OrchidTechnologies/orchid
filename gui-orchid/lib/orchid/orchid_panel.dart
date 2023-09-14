import 'dart:ui';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/common/gradient_border.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

class OrchidPanel extends StatelessWidget {
  final Widget? child;
  final Gradient? edgeGradient;
  final Gradient backgroundGradient;
  final Color backgroundFillColor;
  final double edgeStrokeWidth;
  final bool highlight;
  final double highlightAnimation;

  static const defaultBackgroundGradient = const LinearGradient(
    begin: Alignment(-0.2, -1.4),
    end: Alignment(0.2, 1.4),
    // Figma design
    colors: [Color(0xA0ffffff), Color(0x00ffffff)],
  );

  static const defaultBackgroundFill = const Color(0x503a3149);

  static const verticalBackgroundGradient = const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0x80ffffff), Color(0x00000000)],
  );

  static final verticalBackgroundFill =
      OrchidColors.dark_ff3a3149.withOpacity(0.25);

  // animation 0-1
  static Gradient highlightGradient(double animation) {
    return OrchidGradients.pinkBlueGradientTLBR.rotated(animation * 2 * 3.1415);
  }

  const OrchidPanel({
    Key? key,
    this.child,
    this.edgeGradient,
    this.backgroundGradient = defaultBackgroundGradient,
    this.backgroundFillColor = defaultBackgroundFill,
    this.edgeStrokeWidth = 1.5,
    this.highlight = false,
    this.highlightAnimation = 0,
  }) : super(key: key);

  OrchidPanel.vertical({
    Key? key,
    Widget? child,
    Gradient? edgeGradient,
    double edgeStrokeWidth = 1.5,
    bool highlight = false,
    double highlightAnimation = 0,
  }) : this(
          key: key,
          child: child,
          edgeGradient: edgeGradient,
          edgeStrokeWidth: edgeStrokeWidth,
          highlight: highlight,
          highlightAnimation: highlightAnimation,
          backgroundGradient: OrchidPanel.verticalBackgroundGradient,
          backgroundFillColor: OrchidPanel.verticalBackgroundFill,
        );

  @override
  Widget build(BuildContext context) {
    // Figma design

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // Figma specifies a screen blend mode here but this blend mask does
        // not work over the backdrop filter, which can only apply to the
        // last Skia layer.
        // https://github.com/flutter/flutter/issues/48212#issuecomment-575886050
        // child: BlendMask(
        //   blendMode: BlendMode.screen,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
          // border
          child: GradientBorder(
            strokeWidth: edgeStrokeWidth,
            radius: 16,
            gradient: highlight
                ? highlightGradient(highlightAnimation)
                : (edgeGradient ?? OrchidGradients.orchidPanelEdgeGradient),
            // fill
            child: Container(
              decoration: BoxDecoration(
                color: backgroundFillColor,
                borderRadius: BorderRadius.circular(16),
              ),
              // background gradient
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
