// @dart=2.9
import 'package:flutter/material.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/util/test_app.dart';

void main() {
  runApp(TestApp(scale: 1.0, content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrchidActionButton(text: "TEST 1.0", onPressed: () {}, enabled: true),
          pady(24),
          OrchidActionButton(text: "TEST 2.0", onPressed: () {}, enabled: false),
        ],
      ),
    );
  }
}
