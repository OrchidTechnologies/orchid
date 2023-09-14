import 'package:flutter/material.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/orchid/test_app.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DebugColor();
  }
}
