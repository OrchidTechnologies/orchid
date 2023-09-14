import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/orchid/test_app.dart';
import 'orchid_logo.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(child: NeonOrchidLogo()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 300, height: 100, child: _TestPanel()),
              pady(24),
              SizedBox(width: 300, height: 100, child: _TestPanel()),
              pady(24),
              SizedBox(width: 300, height: 100, child: _TestPanel()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestPanel extends StatelessWidget {
  const _TestPanel({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var fill = Color(0x403a3149);
    var backgroundGradient = LinearGradient(
      begin: Alignment(-0.2, -1.4),
      end: Alignment(0.2, 1.4),
      colors: [Color(0x40ffffff), Color(0x00ffffff)],
    );

    return ClipRect(
      child: OnOff(
        // on: true,
        builder: (context, on) {
          // the blend has no effect over the backdrop filter
          return _TestBlendMask(
            key: Key(on.toString()),
            enabled: on,
            blendMode: BlendMode.screen,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: backgroundGradient,
                    backgroundBlendMode:
                        BlendMode.overlay,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Opacity(
                    // opacity: on ? 1.0 : 0.99,
                    // opacity: 0.99,
                    opacity: 1.0,
                    child: _buildChild(on: on),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Center _buildChild({required bool on}) {
    return Center(
        child: Text(
      "Test Panel",
      style: TextStyle(fontSize: 24, color: Colors.white),
    ));
  }
}

class _TestBlendMask extends SingleChildRenderObjectWidget {
  final BlendMode _blendMode;
  final bool enabled;

  _TestBlendMask({
    required BlendMode blendMode,
    this.enabled = true,
    Key? key,
    Widget? child,
  })  : _blendMode = blendMode,
        super(key: key, child: child);

  // @override
  // void updateRenderObject(BuildContext context, RenderBlendMask renderObject) {
  //   renderObject._blendMode = _blendMode;
  //   renderObject._opacity = _opacity;
  // }

  @override
  RenderObject createRenderObject(context) {
    if (enabled) {
      return _TestRenderBlendMask(_blendMode);
    } else {
      return RenderProxyBox();
    }
  }
}

class _TestRenderBlendMask extends RenderProxyBox {
  final BlendMode _blendMode;

  _TestRenderBlendMask(BlendMode blendMode) : _blendMode = blendMode;

  @override
  void paint(context, offset) {
    context.canvas.saveLayer(
      offset & size,
      Paint()
        ..blendMode = _blendMode
        // this would blur the child contents to be composited down
        //..imageFilter = ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    );
    // paint the child layer which will then be composited down using the above blend mode and filter.
    super.paint(context, offset);
    context.canvas.restore();
  }
}
