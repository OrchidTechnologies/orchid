import 'package:flutter/material.dart';

// TODO: This is no longer needed in later versions of Flutter. Remove when redundant.

/// This is a trivial subclass of AnimatedBuilder that serves to rename
/// it more appropriately for use as a plain listenable builder.
/// (This really should be the name of the base class in Flutter core.)
class ListenableBuilderUtil extends AnimatedBuilder {
  ListenableBuilderUtil({
    Key? key,
    required Listenable listenable,
    required TransitionBuilder builder,
    Widget? child,
  }) : super(key: key, animation: listenable, builder: builder, child: child);
}

