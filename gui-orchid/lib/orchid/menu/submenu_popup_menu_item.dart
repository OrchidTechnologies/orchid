import 'package:orchid/orchid/orchid.dart';

/// A PopupMenuItem that builds its child with a builder accepting an expanded flag.
/// Tapping on this (parent) menu item toggles the expanded flag.
class SubmenuPopopMenuItemBuilder<T> extends PopupMenuItem<T> {
  final Widget Function(bool expanded) builder;

  SubmenuPopopMenuItemBuilder({
    Key? key,
    required this.builder,
    VoidCallback? onTap,
  }) : super(key: key, onTap: onTap, child: Container());

  @override
  PopupMenuItemState<T, SubmenuPopopMenuItemBuilder<T>> createState() =>
      SubmenuPopupMenuItemState<T>();
}

class SubmenuPopupMenuItemState<T>
    extends PopupMenuItemState<T, SubmenuPopopMenuItemBuilder<T>> {
  bool expanded = false;

  @override
  Widget buildChild() {
    return widget.builder(expanded);
  }

  @override
  void handleTap() {
    widget.onTap?.call();
    setState(() {
      expanded = !expanded;
    });
    // Do not dismiss by default
    // Navigator.pop<T>(context, widget.value);
  }
}
