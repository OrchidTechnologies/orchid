import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_identicon.dart';

class OrchidCircularIdenticon extends StatelessWidget {
  final EthereumAddress address;

  const OrchidCircularIdenticon({
    Key key,

    /// Address may be null to indicate inactive state
    this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var active = address != null;
    var image = OrchidIdenticon(value: address, size: 60);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: active ? Color(0xff8C61E1) : Color(0xff504960),
          width: 2,
        ),
        color: Color(0xff261b38),
      ),
      child: active
          ? ClipRRect(borderRadius: BorderRadius.circular(50.0), child: image)
          : null,
    );
  }
}
