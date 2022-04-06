import 'package:orchid/dapp.dart';

// TODO: refactor with _buildExpandableMenuItem and move to orchid
/// A PopupMenuItem that builds its child with a builder accepting an expanded flag.
/// Tapping on this (parent) menu item toggles the expanded flag.
class SubmenuPopopMenuItem<T> extends PopupMenuItem<T> {
  final Widget Function(bool expanded) builder;

  SubmenuPopopMenuItem({
    Key key,
    this.builder,
    VoidCallback onTap,
  }) : super(key: key, onTap: onTap, child: Container());

  @override
  PopupMenuItemState<T, SubmenuPopopMenuItem<T>> createState() =>
      SubmenuPopupMenuItemState<T>();
}

class SubmenuPopupMenuItemState<T>
    extends PopupMenuItemState<T, SubmenuPopopMenuItem<T>> {
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
