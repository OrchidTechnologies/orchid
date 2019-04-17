import 'package:flutter/material.dart';

class AppTransitions {

  static PageRouteBuilder downToUpTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, anim1, anim2) => page,
      transitionsBuilder: (context, anim1, anim2, child) => SlideTransition(
            child: child,
            position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
                .animate(anim1),
          ),
      transitionDuration: Duration(milliseconds: 300),
    );
  }
}
