import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

///A Chip is a small, rounded UI element used to represent:
///a tag
///a category
///a filter
///an action
///a user input
///NOTE: CAN BE DELETED IF NOT NEEDED, IF YOU DO JUST DELETED IT FORM THE: theme.dart

class BChipTheme {
  BChipTheme._();

  static ChipThemeData lightBottomSheetTheme = ChipThemeData(
    backgroundColor: BColors.white,
    disabledColor: Colors.grey.withOpacity(0.4),
    selectedColor: BColors.primary,
    checkmarkColor: Colors.white,
    labelStyle: const TextStyle(color: BColors.black),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    shape: const StadiumBorder(),
  );
}
