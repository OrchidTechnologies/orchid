
import 'package:flutter/material.dart';

const neutral_1 = const Color(0xff3a3149);
const neutral_5 = const Color(0xffd5d7e2);
const neutral_7 = const Color(0xfffbfbfe);
const teal_4 = const Color(0xff4eb6c6);

BoxDecoration textFieldFocusedDecoration = BoxDecoration(
    color: neutral_7,
    borderRadius: BorderRadius.circular(4.0),
    border: Border.all(color: teal_4, width: 2.0));

BoxDecoration textFieldEnabledDecoration = BoxDecoration(
    color: neutral_7,
    borderRadius: BorderRadius.circular(4.0),
    border: Border.all(color: neutral_5, width: 2.0));

TextStyle logStyle = const TextStyle(
    fontFamily: "VT323", fontSize: 16.0, color: neutral_1);
