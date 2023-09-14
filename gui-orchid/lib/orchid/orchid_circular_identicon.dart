import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_identicon.dart';

class OrchidCircularIdenticon extends StatelessWidget {
  final EthereumAddress? address;
  final double size;

  // Use the supplied image instead of generating the identicon
  final Widget? image;

  // Applies an opacity to the identicon image revealing the dark circular background
  final double fade;

  final bool showBorder;

  const OrchidCircularIdenticon({
    Key? key,

    /// Address may be null to indicate inactive state
    this.address,
    this.size = 60,
    this.fade = 1.0,
    this.image,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var active = address != null || image != null;
    // var icon = image ?? OrchidLegacyIdenticon(value: address, size: size);
    var icon = image ?? OrchidIdenticon(address: address);

    var borderDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(size / 2),
      border: Border.all(
        color: active ? Color(0xff8C61E1) : Color(0xff504960),
        width: 2,
      ),
      color: Color(0xff261b38),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      // child: ColorFiltered(
      //   colorFilter: ColorFilter.mode(
      //       Colors.black.withOpacity(1.0-fade), BlendMode.saturation),
      // colorFilter: ColorFilter.mode(Colors.grey, BlendMode.dst),
      // colorFilter: ColorFilter.mode(Colors.grey, BlendMode.dst),
      child: Container(
        width: size,
        height: size,
        decoration: showBorder ? borderDecoration : null,
        child: active ? Opacity(opacity: fade, child: icon) : null,
        // child: active ? image : null,
      ),
    );
  }
}
