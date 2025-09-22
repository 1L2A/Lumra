import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';

class EncouragementMessage extends StatelessWidget {
  final String text;
  const EncouragementMessage({
    super.key,
    this.text = 'Remember, one step is still progress!',
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.lightbulb_outline, color: BColors.texBlack),
      label: Text(
        text,
        style: tt.bodyMedium?.copyWith(color: BColors.texBlack),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, BSizes.buttonHeight + 30),
        side: const BorderSide(color: BColors.texBlack),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        ),
        backgroundColor: BColors.white,
      ),
    );
  }
}
