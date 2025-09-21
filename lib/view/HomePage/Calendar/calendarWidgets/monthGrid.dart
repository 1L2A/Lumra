import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/dayCell.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month; // first day of month
  final bool Function(DateTime day) hasEvent; // ask controller
  final DateTime? selected; // current selection
  final void Function(DateTime day) onTapDay; // notify controller

  const MonthGrid({
    super.key,
    required this.month,
    required this.hasEvent,
    required this.selected,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks =
        first.weekday % 7; //number of empty slots before the first day

    //list to hold all grid cells
    final cells = <Widget>[];

    //adds the blank cells before the first day of the month starts (like if the first day is on Tuesday, sun and mon will be blank)
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    //adds the day cells
    for (var d = 1; d <= totalDays; d++) {
      final date = DateTime(month.year, month.month, d);
      cells.add(
        Obx(() {
          final isSelected =
              selected != null &&
              selected!.year == date.year &&
              selected!.month == date.month &&
              selected!.day == date.day;

          return DayCell(
            day: d,
            hasEvent: hasEvent(
              date,
            ), // will re-check reactively -> to add the red dot that will be added in the dayCell
            isSelected: isSelected,
            onTap: () => onTapDay(date),
          );
        }),
      );
    }

    //fills the last row with blanks
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        padding: const EdgeInsets.only(bottom: 8),
        crossAxisCount: 7,
        childAspectRatio: 1.05,
        physics: const BouncingScrollPhysics(),
        children: cells,
      ),
    );
  }
}
