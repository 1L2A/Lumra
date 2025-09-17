import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class BCheckboxTheme {

  BCheckboxTheme._();


  ///----LIGHT THEME---///
  static CheckboxThemeData lightCheckBoxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),

    ///color of the icon, sets the color of the checkmark icon (✔) inside the checkbox.
    checkColor: MaterialStateProperty.resolveWith( (states) { ///allows you to give different colors depending on the state (selected, hovered, pressed, etc.).
      if (states.contains(MaterialState.selected)){
        return BColors.white;}
      else {
        return BColors.black;}

  }),
      fillColor: MaterialStateProperty.resolveWith( (states) {
        if (states.contains(MaterialState.selected)){
          return BColors.primary;}
        else {
          return Colors.transparent;} ///OR BLACK OR WHITE IF YOU WANT IT MORE VISIBLE?

      }),
  );

}