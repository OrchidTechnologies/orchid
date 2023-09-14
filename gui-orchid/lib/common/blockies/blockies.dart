import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/util/svg_builder.dart';
import 'xorshift_random.dart';

// Ported from https://github.com/download13/blockies (WTFPL)
class Blockies {
  late XorShiftRandom _random;

  double rand() {
    return _random.nextDouble();
  }

  Color _createColor() {
    // Saturation is the whole color spectrum
    final h = rand() * 360;
    // Saturation goes from 40 to 100, it avoids greyish colors
    final s = (rand() * 60) + 40;
    // Lightness can be anything from 0 to 100, but probabilities are a bell curve around 50%
    final l = (rand() + rand() + rand() + rand()) * 25;
    return HSLColor.fromAHSL(
            1.0, h % 360, min(1.0, s / 100.0), min(1.0, l / 100.0))
        .toColor();
  }

  // Array of three color indices (0,1,2)
  List<int> _createImageData(int size) {
    final width = size; // Only support square icons for now
    final height = size;

    final dataWidth = (width / 2).ceil();
    final mirrorWidth = width - dataWidth;

    final data = <int>[];
    for (var y = 0; y < height; y++) {
      final row = <int>[];
      for (var x = 0; x < dataWidth; x++) {
        // this makes foreground and background color to have a 43% (1/2.3) probability
        // spot color has 13% chance
        row.add((rand() * 2.3).floor());
      }
      var r = row.sublist(0, mirrorWidth);
      r = r.reversed.toList();
      row.addAll(r);

      for (var i = 0; i < row.length; i++) {
        data.add(row[i]);
      }
    }

    return data;
  }

  SvgPicture generate({
    required EthereumAddress address,
    int size = 8,
    int scale = 16,
  }) {
    // Match Metamask's usage.
    String seed = address.toString(prefix: true, elide: false).toLowerCase();

    return SvgPicture.string(
      renderSvg(seedValue: seed, size: size, scale: scale),
    );
  }

  String renderSvg({
    required String seedValue,
    int size = 8,
    int scale = 4,
  }) {
    _random = XorShiftRandom(seedValue);

    final color = _createColor(); // preserve this
    final bgColor = _createColor();
    final spotColor = _createColor();
    final imageData = _createImageData(size);
    final width = sqrt(imageData.length);

    var svg = SvgBuilder.fromRect(0, 0, size * scale, size * scale, bgColor);
    for (var i = 0; i < imageData.length; i++) {
      if (imageData[i] > 0) {
        int row = (i / width).floor();
        int col = i % width.round();
        final fill = (imageData[i] == 1) ? color : spotColor;
        svg.addRect(
          SvgRect(col * scale, row * scale, scale, scale).fill(fill),
        );
      }
    }

    return svg.build();
  }
}
