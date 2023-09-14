import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/test_app.dart';

void main() {
  runApp(TestApp(scale: 1.0, content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSimpleButton(),
          OrchidActionButton(
                  text: "TEST 1.0",
                  onPressed: () {
                    log("Test 1");
                  },
                  enabled: true)
              .top(24),
          OrchidActionButton(
                  text: "TEST 2.0",
                  onPressed: () {
                    log("Test 2");
                  },
                  enabled: false)
              .top(24),
          OrchidActionButton(text: "NEW TEST 2.0", onPressed: null).top(24),
          OrchidOutlineButton(
              text: "OUTLINE",
              onPressed: () {
                log("Test 2");
              }).top(24),
        ],
      ),
    );
  }

  TextButton _buildSimpleButton() {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 32),
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        padding: EdgeInsets.all(16),
      ),
      onPressed: () {},
      child: const Text('Simple Button'),
    );
  }
}
