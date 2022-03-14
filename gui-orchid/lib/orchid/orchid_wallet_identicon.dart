import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/blockies/blockies.dart';
import 'package:orchid/common/jazzicon/jazzicon.dart';

/// Supports Jazzicon and Blockies
class OrchidWalletIdenticon extends StatelessWidget {
  final EthereumAddress address;

  const OrchidWalletIdenticon({
    Key key,
    @required this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: UserPreferences().useBlockiesIdenticons.stream(),
        builder: (context, snapshot) {
          final useBlockies = snapshot.data;
          if (address == null || useBlockies == null) {
            return Container();
          }
          return ClipOval(
            child: useBlockies
                ? Blockies().generate(address: address, size: 8, scale: 3)
                : Jazzicon().generate(address: address, diameter: 24),
          );
        });
  }
}
