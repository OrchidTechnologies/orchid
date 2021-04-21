import 'package:flutter/material.dart';
import 'package:orchid/common/app_colors.dart';

/// Min space app bar with no custom widgets.
class SmallAppBar extends StatelessWidget implements PreferredSizeWidget {
  Widget build(BuildContext context) {
    return AppBar(backgroundColor: AppColors.purple, elevation: 0.0);
  }

  @override
  Size get preferredSize => Size.fromHeight(4);
}
