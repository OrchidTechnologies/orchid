import 'package:flutter/material.dart';

/// Arrange a flexibly sized column of content to fill the screen normally but
/// allow it to collapse and scroll as needed to accommodate the keyboard.
///
/// This arrangement with the layout builder, scroll view, constrained box, and intrinsic height
/// allows us to fill the screen normally while remaining in a list view.  The scroll view is
/// necessary to accommodate the keyboard when the text field has focus.
/// https://docs.flutter.io/flutter/widgets/SingleChildScrollView-class.html
class AccommodateKeyboard extends StatelessWidget {
  final Widget child;

  AccommodateKeyboard({
    @required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 590, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
