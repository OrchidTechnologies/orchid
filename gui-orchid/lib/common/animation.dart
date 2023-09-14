import 'package:flutter/material.dart';

class AnimatedVisibility extends StatelessWidget {
  final Widget child;
  final bool show;
  final Duration duration;

  AnimatedVisibility({
    Key? key,
    required this.show,
    required this.child,
    Duration? duration,
  })  : this.duration = duration ?? Duration(milliseconds: 330),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: duration,
      crossFadeState:
          show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: child,
      secondChild: Container(),
    );
  }
}
