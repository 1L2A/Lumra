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
    disabledColor: Colors.grey.withOpacity(0.4),
    labelStyle: const TextStyle(color: Colors.black), ///(text inside the chip)
    selectedColor: BColors.primary, ///when Selected
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
    checkmarkColor: Colors.white, ///If the chip is selectable (ChoiceChip or FilterChip), a checkmark icon may appear when it's selected
  ); // BottomSheetThemeData

}
