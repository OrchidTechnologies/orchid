import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/util/svg_builder.dart';

// Ported from https://github.com/download13/blockies (WTFPL)
class Blockies {
  List<int> randSeed;

  // Xorshift PRNG values
  void seed(String value) {
    final chars = value.codeUnits;
    randSeed = new List.filled(4, 0, growable: false);
    for (var i = 0; i < chars.length; i++) {
      randSeed[i % 4] =
          ((Int32(randSeed[i % 4]) << 5).toInt() - (randSeed[i % 4])) +
              chars[i];
    }
  }

  double rand() {
    // based on Java's String.hashCode(), expanded to 4 32bit values
    var t = (Int32(randSeed[0]) ^ (Int32(randSeed[0]) << 11)).toInt();
    randSeed[0] = randSeed[1];
    randSeed[1] = randSeed[2];
    randSeed[2] = randSeed[3];
    randSeed[3] = (Int32(randSeed[3]) ^
            (Int32(randSeed[3]) >> 19) ^
            Int32(t) ^
            (Int32(t) >> 8))
        .toInt();
    return randSeed[3] / (1 << 31);
  }

  Color createColor() {
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
  List<int> createImageData(int size) {
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
    @required EthereumAddress address,
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
    @required String seedValue,
    int size = 8,
    int scale = 4,
  }) {
    seed(seedValue);

    final color = createColor(); // preserve this
    final bgColor = createColor();
    final spotColor = createColor();
    final imageData = createImageData(size);
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
