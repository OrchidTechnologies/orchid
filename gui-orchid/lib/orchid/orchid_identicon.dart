import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/cupertino.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/common/blockies/blockies.dart';
import 'package:orchid/common/jazzicon/jazzicon.dart';

/// Supports Jazzicon and Blockies
class OrchidIdenticon extends StatelessWidget {
  final EthereumAddress? address;

  const OrchidIdenticon({
    Key? key,
    this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserPreferencesUI().useBlockiesIdenticons.builder(
      (bool? useBlockies) {
        if (address == null || useBlockies == null) {
          return Container();
        }
        return ClipOval(
          child: useBlockies
              ? Blockies().generate(address: address!, size: 8, scale: 3)
              : Jazzicon().generate(address: address!, diameter: 24),
        );
      },
    );
  }
}

@deprecated
class OrchidLegacyIdenticon extends StatelessWidget {
  final EthereumAddress value;
  final double size;

  const OrchidLegacyIdenticon({
    Key? key,
    required this.value,
    this.size = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String svg = Jdenticon.toSvg(value.toString());
    return SvgPicture.string(svg,
        fit: BoxFit.contain, height: size, width: size);
  }
}
