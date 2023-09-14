import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Applies a BlendMode to its child.
class BlendMask extends SingleChildRenderObjectWidget {
  final BlendMode _blendMode;

  BlendMask({required BlendMode blendMode, Key? key, Widget? child})
      : _blendMode = blendMode,
        super(key: key, child: child);

  @override
  RenderObject createRenderObject(context) {
    return RenderBlendMask(_blendMode);
  }
}

class RenderBlendMask extends RenderProxyBox {
  BlendMode _blendMode;

  RenderBlendMask(BlendMode blendMode) : _blendMode = blendMode;

  @override
  void paint(context, offset) {
    context.canvas.saveLayer(offset & size, Paint()..blendMode = _blendMode);
    // paint the child layer which will then be composited down using the above blend mode.
    super.paint(context, offset);
    context.canvas.restore();
  }
}
