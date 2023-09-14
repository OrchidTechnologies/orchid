import 'dart:ui';
import 'package:orchid/util/color_extensions.dart';

/// Stand-in for an SVG drawing API
class SvgBuilder {
  final SvgRect base;
  final List<SvgRect> rects = [];

  SvgBuilder(this.base);

  SvgBuilder.fromRect(int x, int y, int width, int height, Color bgColor)
      : this(SvgRect(x, y, width, height).fill(bgColor));

  SvgBuilder addRect(SvgRect rect) {
    rects.add(rect);
    return this;
  }

  String build() {
    String s = '<svg x="${base.x}" y="${base.y}" '
        'width="${base.width}" height="${base.height}" '
        'xmlns="http://www.w3.org/2000/svg">';
    s += base.build();
    for (var rect in rects) {
      s += rect.build();
    }
    s += '</svg>';
    return s;
  }

  @override
  String toString() {
    return build();
  }
}

class SvgRect {
  int x, y, width, height;
  double? translateX, translateY;
  double? rotateDeg;
  int? rotateCenterX, rotateCenterY;
  String? fillColor;

  SvgRect(this.x, this.y, this.width, this.height);

  SvgRect translate(double x, double y) {
    this.translateX = x;
    this.translateY = y;
    return this;
  }

  SvgRect rotate(double deg, int x, int y) {
    this.rotateDeg = deg;
    this.rotateCenterX = x;
    this.rotateCenterY = y;
    return this;
  }

  SvgRect fill(Color color) {
    this.fillColor = color.toHexString(includeAlpha: false);
    return this;
  }

  List<String> _transforms() {
    var list = <String>[];
    if (translateX != null) {
      list.add('translate($translateX $translateY)');
    }
    if (rotateDeg != null) {
      list.add('rotate($rotateDeg $rotateCenterX $rotateCenterY)');
    }
    return list;
  }

  String build() {
    String s = '<rect x="$x" y="$y" width="$width" height="$height"';
    var transforms = _transforms();
    if (transforms.isNotEmpty) {
      s += ' transform="${transforms.join(' ')}"';
    }
    if (fillColor != null) {
      s += ' fill=\"$fillColor\"';
    }
    s += '/>';
    return s;
  }

  @override
  String toString() {
    return build();
  }
}
