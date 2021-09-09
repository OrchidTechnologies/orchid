import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_crypto.dart';

class OrchidIdenticon extends StatelessWidget {
  final EthereumAddress value;
  final double size;

  const OrchidIdenticon({
    Key key,
    @required this.value,
    this.size = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String svg = Jdenticon.toSvg(value.toString());
    return SvgPicture.string(svg,
        fit: BoxFit.contain, height: size, width: size);
  }
}

