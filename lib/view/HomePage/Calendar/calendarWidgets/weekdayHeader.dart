import 'package:flutter/material.dart';

//create the header widget
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    //wraps the whole row in a padding widget
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),

      //to lay the weekdays horizontally
      child: Row(
        children: labels
            .map(
              //map each string in labels to a widget
              (e) => Expanded(
                child: Center(
                  child: Text(
                    e,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
