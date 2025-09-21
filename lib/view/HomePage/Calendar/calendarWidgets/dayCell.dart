import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class DayCell extends StatelessWidget {
  final int day;
  final bool hasEvent;
  final bool isSelected;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.day,
    required this.hasEvent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //cell color
    final bg = isSelected
        ? BColors.secondry.withOpacity(.18)
        : Colors.transparent;

    //cell boarder
    final border = isSelected ? BColors.primary : Colors.transparent;

    //text in cell color
    final fg = isSelected ? BColors.textprimary : BColors.texBlack;

    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      //for tap ripple feedback
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),

      //container for each day cell
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
            width: (hasEvent || isSelected) ? 1 : 0,
          ),
        ),

        //stack to layer the content inside each other
        child: Stack(
          children: [
            Align(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '$day',
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ),

            //show a dot
            if (hasEvent && !isSelected)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: BColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
