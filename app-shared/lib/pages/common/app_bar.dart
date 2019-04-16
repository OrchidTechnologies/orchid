import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

class SmallAppBar {

  static Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(4),
        // Min space with no custom widgets
        child: AppBar(backgroundColor: AppColors.purple, elevation: 0.0));
  }
}

