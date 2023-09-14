import 'package:flutter/widgets.dart';

class TripleTapGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onTripleTap;
  final maxInterval = 300;

  const TripleTapGestureDetector({
    Key? key,
    required this.child,
    required this.onTripleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime? lastTap;
    int count = 0;

    return GestureDetector(
      onTap: () {
        var now = DateTime.now();
        if (lastTap == null ||
            now.difference(lastTap!).inMilliseconds < maxInterval) {
          count++;
          if (count >= 3) {
            count = 0;
            lastTap = null;
            onTripleTap();
          }
        }
        lastTap = now;
      },
      child: child,
    );
  }
}
