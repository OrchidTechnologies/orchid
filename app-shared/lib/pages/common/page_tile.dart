import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

/// A list tile containing an optional image, trailing component, title,
/// and a tap gesture callback.
class PageTile extends StatelessWidget {
  final String title;
  final String imageName;
  Widget trailing;
  GestureTapCallback onTap;
  Color color;

  PageTile(
      {this.title,
      this.imageName,
      this.onTap,
      this.trailing,
      this.color = Colors.transparent });

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
        height: 50,
        color: color,
        child: ListTile(
            title: Text(title),
            leading: imageName != null
                ? Image(color: AppColors.purple, image: AssetImage(imageName))
                : null,
            trailing: trailing != null
                ? trailing
                : Icon(Icons.chevron_right, color: AppColors.purple),
            onTap: onTap));
  }
}
