import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/util/color_extensions.dart';
import 'package:orchid/util/svg_builder.dart';
import 'mersenne_random.dart';

/// Render an identicon from rotated and translated overlapping rects.
// Ported from https://github.com/MetaMask/jazzicon (ISC License 2020 MetaMask)
class Jazzicon {
  late MersenneTwisterRandom _random;

  static final colors = [
    ColorExtensions.fromHexString('#01888C'), // teal
    ColorExtensions.fromHexString('#FC7500'), // bright orange
    ColorExtensions.fromHexString('#034F5D'), // dark teal
    ColorExtensions.fromHexString('#F73F01'), // orange red
    ColorExtensions.fromHexString('#FC1960'), // magenta
    ColorExtensions.fromHexString('#C7144C'), // raspberry
    ColorExtensions.fromHexString('#F3C100'), // goldenrod
    ColorExtensions.fromHexString('#1598F2'), // lightning blue
    ColorExtensions.fromHexString('#2465E1'), // sail blue
    ColorExtensions.fromHexString('#F19E02'), // gold
  ];

  SvgPicture generate({required int diameter, required EthereumAddress address}) {
    return generateFromHexString(diameter, address.toString());
  }

  /*
    e.g.
    <svg x="0" y="0" width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <rect x="0" y="0" width="100" height="100"
            transform="translate(-8.181464718033592 -14.462894101831216) rotate(249.1 50 50)" fill="#034f5d"/>
      <rect x="0" y="0" width="100" height="100"
            transform="translate(-35.81588898993925 -17.7965916791912) rotate(262.2 50 50)" fill="#f73f01"/>
      <rect x="0" y="0" width="100" height="100"
            transform="translate(-32.33297094503105 85.8163052812376) rotate(143.7 50 50)" fill="#fc1960"/>
    </svg>
  */
  SvgPicture generateFromHexString(int diameter, String hexString) {
    final seed = _hexStringToSeed(hexString);
    _random = MersenneTwisterRandom(seed);

    var remainingColors = _hueShift(List.from(colors));
    final bgColor = _genColor(remainingColors);
    var svg = SvgBuilder.fromRect(0, 0, diameter, diameter, bgColor);

    var shapeCount = 4;
    for (var i = 0; i < shapeCount - 1; i++) {
      _genShape(remainingColors, diameter, i, shapeCount - 1, svg);
    }
    return SvgPicture.string(svg.build());
  }

  // Matching Metamask's pre-processing of the value
  int _hexStringToSeed(String address) {
    final addr = address.substring(2, 10);
    return int.parse(addr, radix: 16);
  }

  void _genShape(List<Color> remainingColors, int diameter, int index,
      int total, SvgBuilder svg) {
    var center = (diameter / 2).round();
    var rect = SvgRect(0, 0, diameter, diameter);

    var firstRot = _random.nextDouble();
    var angle = pi * 2 * firstRot;
    var velocity =
        diameter / total * _random.nextDouble() + (index * diameter / total);
    var tx = (cos(angle) * velocity);
    var ty = (sin(angle) * velocity);
    rect.translate(tx, ty);

    var secondRot = _random.nextDouble();
    var rot = (firstRot * 360) + secondRot * 180;
    rect.rotate(rot, center, center);

    var fillColor = _genColor(remainingColors);
    rect.fill(fillColor);

    svg.addRect(rect);
  }

  Color _genColor(List<Color> colors) {
    // Superfluous value generation here matches original prng sequence.
    _random.nextDouble();
    var idx = (colors.length * _random.nextDouble()).floor();
    return colors.removeAt(idx);
  }

  List<Color> _hueShift(List<Color> colors) {
    final wobble = 30;
    var amount = (_random.nextDouble() * 30) - (wobble / 2);
    var rotate = (Color color) => _colorRotate(color, amount);
    return colors.map(rotate).toList();
  }

  Color _colorRotate(Color color, double degrees) {
    var hsl = HSLColor.fromColor(color);
    var hue = hsl.hue;
    hue = (hue + degrees) % 360;
    hue = hue < 0 ? 360 + hue : hue;
    hsl = HSLColor.fromAHSL(color.opacity, hue, hsl.saturation, hsl.lightness);
    return hsl.toColor();
  }
}
