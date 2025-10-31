import 'package:flutter/material.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/confirmEventDelete.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/eventTitle.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/format.dart';
import 'package:lumra_project/view/Homepage/Calendar/eventWidgets/addEventView.dart';
import 'package:get/get.dart';

class BottomArea extends StatelessWidget {
  final DateTime selected;

  const BottomArea({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CalendarController>();

    return Obx(() {
      final textTheme = Theme.of(context).textTheme;
      final dayKey = DateTime(selected.year, selected.month, selected.day);
      final events = List<CalendarEvent>.from(
        c.monthEvents[dayKey] ?? const [],
      );
      final dateLabel =
          '${weekdayName(selected.weekday)}, ${monthName(selected.month)} ${selected.day}';

      final today = DateTime.now();
      final isPastDay = DateTime(
        selected.year,
        selected.month,
        selected.day,
      ).isBefore(DateTime(today.year, today.month, today.day));
      final canAdd = !isPastDay;
      final canEditOnThisDay = !isPastDay;

      void _openAddSheet() {
        //made it looks like popping up from the bottom
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: BColors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          builder: (context) => const FractionallySizedBox(
            heightFactor: 0.75,
            child: AddEventView(),
          ),
        );
      }

      void _openEditSheet(CalendarEvent event) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.75,
            child: AddEventView(eventToEdit: event),
          ),
        );
      }

      Future<void> _confirmAndDelete(CalendarEvent evt) async {
        final ok = await DeleteDialog.show(context);
        if (ok != true) return;

        try {
          final cal = Get.find<CalendarController>();
          await cal.deleteEvent(evt.id);
          ToastService.success("Your event is deleted successfully.");
        } catch (e) {
          ToastService.error("Failed to delete the event");
        }
      }

      //if there is no events it is going to contain "Tue, September 30" + the add button
      if (events.isEmpty) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: BColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        dateLabel,
                        style: (textTheme.titleMedium ?? const TextStyle())
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              color: BColors.black,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: canAdd
                          ? BColors.primary
                          : BColors.darkGrey.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 14,
                      color: canAdd
                          ? BColors.white
                          : BColors.darkGrey.withOpacity(0.5),
                    ),
                    label: Text(
                      'Add Event',
                      style: textTheme.labelMedium?.copyWith(
                        color: canAdd
                            ? BColors.white
                            : BColors.darkGrey.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: canAdd
                        ? _openAddSheet
                        : null, // disabled if past
                  ),
                ],
              ),
            ],
          ),
        );
      }

      //if there is event then it will contain the events (ordered) with a '+' icon to add more
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 35),
        decoration: BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      dateLabel,
                      style: (textTheme.titleMedium ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: BColors.black,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: canAdd
                        ? BColors.primary.withOpacity(0.1)
                        : BColors.darkGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: canAdd
                        ? 'Add event'
                        : 'Cannot add events to past dates',
                    icon: Icon(
                      Icons.add,
                      color: canAdd
                          ? BColors.primary
                          : BColors.darkGrey.withOpacity(0.5),
                      size: 16,
                    ),
                    onPressed: canAdd
                        ? _openAddSheet
                        : null, // disabled if past
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ClipRect(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => SizedBox(height: BSizes.sm),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return _SwipeableEventItem(
                        event: e,
                        onEdit: () => _openEditSheet(e),
                        onDelete: () => _confirmAndDelete(e),
                        child: EventTile(event: e),
                        editEnabled: canEditOnThisDay,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SwipeableEventItem extends StatefulWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget child;
  final bool editEnabled;

  const _SwipeableEventItem({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.child,
    this.editEnabled = true,
  });

  @override
  State<_SwipeableEventItem> createState() => _SwipeableEventItemState();
}

class _SwipeableEventItemState extends State<_SwipeableEventItem> {
  double _dragOffset = 0.0;
  static const double _actionWidth = 60.0;
  static const double _maxDragDistance = _actionWidth * 2;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        -_maxDragDistance,
        0.0,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _dragOffset = _dragOffset < -_maxDragDistance / 2
          ? -_maxDragDistance
          : 0.0;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (_dragOffset != 0.0) {
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editBg = widget.editEnabled
        ? BColors.info.withOpacity(0.2)
        : BColors.darkGrey.withOpacity(0.12);
    const editIconEnabled = BColors.info;
    final editIcon = widget.editEnabled
        ? editIconEnabled
        : BColors.darkGrey.withOpacity(0.6);
    return ClipRect(
      child: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onTapDown: _handleTapDown,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0.0);
                      if (!widget.editEnabled) {
                        ToastService.error(
                          'You cannot edit events on past days.',
                        );
                        return;
                      }
                      widget.onEdit();
                    },
                    child: Container(
                      width: _actionWidth,
                      decoration: BoxDecoration(
                        color: editBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.edit, size: 24, color: editIcon),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0.0);
                      widget.onDelete();
                    },
                    child: Container(
                      width: _actionWidth,
                      decoration: BoxDecoration(
                        color: BColors.error.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: BColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              color: BColors.white,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final beginOffset = const Offset(0, 0.02);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(
                    '${widget.event.id}_${widget.event.start}_${widget.event.end}',
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
