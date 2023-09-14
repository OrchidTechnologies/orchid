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

// https://stackoverflow.com/a/53503738/74975
class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
      builder: builder,
      maintainState: maintainState,
      settings: settings,
      fullscreenDialog: fullscreenDialog);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    /*
    // Experimenting with making this one-way.
    if (animation.status == AnimationStatus.reverse) {
      var begin = Offset.zero;
      var end = Offset(0.0, 1.0);
      var tween = Tween(begin: begin, end: end);
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(
          position: offsetAnimation,
          child: child
      );
    } else {
      return child;
    }
     */
    return child;
  }
}
