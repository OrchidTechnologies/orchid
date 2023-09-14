import 'package:flutter/material.dart';
import 'package:orchid/orchid/test_app.dart';
import 'orchid_logo.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  __TestState createState() => __TestState();
}

class __TestState extends State<_Test> with TickerProviderStateMixin {
  late NeonOrchidLogoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NeonOrchidLogoController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
                animation: _controller.listenable,
                builder: (BuildContext context, Widget? _) {
                  return NeonOrchidLogo(
                    light: _controller.value,
                    offset: _controller.offset,
                  );
                }),
          ),
          Align(
            alignment: Alignment.center,
            child: Transform.scale(
              scale: 1.5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.off();
                      },
                      child: Text("Off"),
                    ),
                    TextButton(
                      onPressed: () {
                        _controller.half();
                      },
                      child: Text("Half"),
                    ),
                    TextButton(
                      onPressed: () {
                        _controller.pulseHalf();
                      },
                      child: Text("Pulse"),
                    ),
                    TextButton(
                      onPressed: () {
                        _controller.full();
                      },
                      child: Text("On"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
