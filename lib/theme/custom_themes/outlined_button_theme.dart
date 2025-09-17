import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';


/// for Secondary actions, Clear or Reset buttons,Step-by-step screens (onboarding, forms),Bottom sheets or dialogs

class BOutlinedButtonTheme {
  ///To Avoid creating instances, private constructor can not be called, Call the functions
  BOutlinedButtonTheme._();

  ///-----------LIGHT THEME-------------///
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(

    ///styling the button
    style: OutlinedButton.styleFrom(
      elevation: 0, ///No shadow under the button
      foregroundColor: BColors.black, ///color ot the text
      side: const BorderSide(color: BColors.buttonSecondary),///for the border,there are more styles
      padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
      textStyle: const TextStyle( fontSize: 16, color: BColors.black, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

  );

}
