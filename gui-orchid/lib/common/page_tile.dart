import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_text.dart';

/// A list tile containing an optional image, trailing component, title,
/// and a tap gesture callback.
class PageTile extends StatelessWidget {
  final String title;
  final String? imageName;
  final Widget? body;
  final Widget? trailing;
  final Widget? leading;
  late final GestureTapCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  PageTile({
    required this.title,
    this.body,
    this.imageName,
    this.onTap,
    this.leading,
    this.trailing,
    this.backgroundColor = Colors.transparent,
    this.height,
    this.textColor,
  });

  PageTile.route(
      {required this.title,
      this.imageName,
      this.leading,
      required BuildContext context,
      required String routeName,
      this.textColor,
      this.body,
      this.trailing,
      this.backgroundColor,
      this.height}) {
    this.onTap = () => Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: height ?? 50,
        color: backgroundColor,
        child: ListTile(
            // contentPadding: EdgeInsets.zero,
            title:
                Text(title, style: OrchidText.body2.copyWith(color: textColor)),
            subtitle: body,
            leading: leading ??
                (imageName != null
                    ? Image(color: Colors.white, image: AssetImage(imageName!))
                    : null),
            trailing: trailing != null
                ? trailing
                : Icon(Icons.chevron_right, color: Colors.white),
            onTap: onTap));
  }
}
