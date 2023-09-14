import 'package:flutter/material.dart';

/// A widget that wraps its child in a tap gesture detector that clears focus.
/// The effect is that taps that are not handled by child widgets (e.g. taps
/// "outside" the active components) cause focus to clear, removing the keyboard.
///
class TapClearsFocus extends StatelessWidget {
  const TapClearsFocus({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: child,
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        });
  }
}
