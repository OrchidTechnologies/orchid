import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/test_app.dart';
import 'jazzicon.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  State<_Test> createState() => _TestState();
}

class _TestState extends State<_Test> {
  @override
  Widget build(BuildContext context) {
    var addresses = [
      '0x405BC10E04e3f487E9925ad5815E4406D78B769e',
      '0xbC0de2BBDa6b0d4a8Ac7285419C9F4169f4FF8B3',
      '0x2486C586Dc52384f231fec4a96DA69620De87A56',
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: addresses.map(_doAddress).toList(),
      ),
    );
  }

  Widget _doAddress(String address) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Text(address).button,
          SizedBox(height: 24),
          ClipOval(
              child: Jazzicon().generate(
                  diameter: 200, address: EthereumAddress.from(address))),
        ],
      ),
    );
  }
}
