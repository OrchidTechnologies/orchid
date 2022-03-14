import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/util/test_app.dart';
import 'blockies.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key key}) : super(key: key);

  @override
  State<_Test> createState() => _TestState();
}

class _TestState extends State<_Test> {
  @override
  void initState() {
    super.initState();
    // _test();
  }

  @override
  Widget build(BuildContext context) {
    var address = '0x405BC10E04e3f487E9925ad5815E4406D78B769e';
    return Container(
      // color: Colors.grey.shade800,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              address,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 48),
            Blockies().generate(address: EthereumAddress.from(address)),
          ],
        ),
      ),
    );
  }
}
