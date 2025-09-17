import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class BElevatedButtonTheme {
  ///To Avoid creating instances, private constructor can not be called, Call the functions
  BElevatedButtonTheme._();

  ///-----------LIGHT THEME-------------///
  //can be called as an attribute
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    ///styling the button
    style: ElevatedButton.styleFrom(
      ///an elevation could be added giving a floating look
      foregroundColor: BColors.white,
      ///color ot the text
      backgroundColor: BColors.buttonPrimary,
      disabledForegroundColor: Colors.grey,
      disabledBackgroundColor: Colors.grey,
      side: const BorderSide(color: BColors.buttonPrimary),
      ///for the border,there are more styles
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(
          fontSize: 16, color: BColors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

}


