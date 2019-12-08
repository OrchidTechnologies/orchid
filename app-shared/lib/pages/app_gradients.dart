import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

import 'common/gradients.dart';

class AppGradients {
  static const Gradient verticalGrayGradient1 =
      VerticalLinearGradient(colors: [AppColors.grey_7, AppColors.grey_6]);

  static const Gradient purpleL3BlueL3Gradient = VerticalLinearGradient(
      colors: [Color(0xff52319c), Color(0xff5f45ba), Color(0xff4566ba)]);

  static const Gradient basicGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.grey_7, AppColors.grey_6]);

  static Gradient purpleTileHorizontal = HorizontalLinearGradient(
      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600]);
}
