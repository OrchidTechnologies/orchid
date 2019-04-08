import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

class AppText {
  static TextStyle headerStyle = TextStyle(
    letterSpacing: 0.0,
    // Eyeballing this. What is in Zeplin doesn't seem to to line height / font size.
    height: 1.32,
    color: AppColors.text_header_purple,
    fontWeight: FontWeight.w500,
    fontFamily: "Roboto",
    fontStyle: FontStyle.normal,
    fontSize: 24.0,
  );

  static Text header(
      {text: String,
      textAlign: TextAlign.center,
      color: AppColors.text_header_purple,
      fontWeight: FontWeight.w500,
      fontFamily: "Roboto",
      fontStyle: FontStyle.normal,
      fontSize: 24.0}) {
    return Text(text,
        textAlign: textAlign,
        style: TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            fontSize: fontSize));
  }

  static TextStyle bodyStyle = TextStyle(
      color: AppColors.text_body,
      letterSpacing: 0.0,
      height: 1.32,
      fontWeight: FontWeight.w400,
      fontFamily: "Roboto",
      fontStyle: FontStyle.normal,
      fontSize: 14.0);

  static Text body(
      {text: "",
      textAlign: TextAlign.center,
      color: AppColors.text_body,
      letterSpacing: 0.0,
      lineHeight: 1.32,
      fontWeight: FontWeight.w400,
      fontFamily: "Roboto",
      fontStyle: FontStyle.normal,
      fontSize: 14.0}) {
    return Text(text,
        textAlign: textAlign,
        style: TextStyle(
            color: color,
            letterSpacing: letterSpacing,
            height: lineHeight,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            fontSize: fontSize));
  }

  static TextStyle hintStyle = TextStyle(
      color: AppColors.neutral_1,
      letterSpacing: 0.15,
      //height: 1.5,
      fontWeight: FontWeight.w400,
      fontFamily: "Roboto",
      fontStyle: FontStyle.normal,
      fontSize: 16.0);
}

