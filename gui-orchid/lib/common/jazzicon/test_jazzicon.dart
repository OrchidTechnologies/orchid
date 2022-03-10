// @dart=2.9
import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/util/test_app.dart';
import 'jazzicon.dart';

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
  Widget build(BuildContext context) {
    var address = '0x405BC10E04e3f487E9925ad5815E4406D78B769e';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(address).button,
          SizedBox(height: 48),
          ClipOval(
            child: Jazzicon().generateFromHexString(
              256,
              '0x405BC10E04e3f487E9925ad5815E4406D78B769e',
            ),
          ),
        ],
      ),
    );
  }
}
