import 'package:flutter/material.dart';
import 'package:orchid/common/app_colors.dart';

/// A list tile containing an optional image, trailing component, title,
/// and a tap gesture callback.
class PageTile extends StatelessWidget {
  final String title;
  final String imageName;
  Widget body;
  Widget trailing;
  Widget leading;
  GestureTapCallback onTap;
  Color color;
  double height;

  PageTile({
    this.title,
    this.body,
    this.imageName,
    this.onTap,
    this.leading,
    this.trailing,
    this.color = Colors.transparent,
    this.height,
  });

  PageTile.route(
      {this.title,
      this.imageName,
      @required BuildContext context,
      @required String routeName}) {
    this.onTap = () {
      Navigator.pushNamed(context, routeName);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height ?? 50,
        color: color,
        child: ListTile(
            title: Text(title),
            subtitle: body,
            leading: leading ??
                (imageName != null
                    ? Image(
                        color: AppColors.purple, image: AssetImage(imageName))
                    : null),
            trailing: trailing != null
                ? trailing
                : Icon(Icons.chevron_right, color: AppColors.purple),
            onTap: onTap));
  }
}
