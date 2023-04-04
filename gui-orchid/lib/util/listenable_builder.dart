// @dart=2.9

import 'package:flutter/material.dart';

/// This is a trivial subclass of AnimatedBuilder that serves to rename
/// it more appropriately for use as a plain listenable builder.
/// (This really should be the name of the base class in Flutter core.)
class ListenableBuilder extends AnimatedBuilder {
  ListenableBuilder({
    Key key,
    @required Listenable listenable,
    @required TransitionBuilder builder,
    Widget child,
  }) : super(key: key, animation: listenable, builder: builder, child: child);
}

