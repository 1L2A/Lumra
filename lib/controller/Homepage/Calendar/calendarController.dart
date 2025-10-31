import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/Homepage/Calendar/calendarModel.dart';

//Helper function that takes the DateTime and returns another date
//because when displaying the calander we want to display the days from the first day to the last day (not including the first day of the next month)
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime monthEndExclusive(DateTime d) => DateTime(d.year, d.month + 1, 1);
DateTime justDate(DateTime d) => DateTime(d.year, d.month, d.day);

class CalendarController extends GetxController {
  final FirebaseFirestore db;
  final String currentUid;
  CalendarController(this.db, this.currentUid);

  //the current month is the month that is going to appear
  final visibleMonth = monthStart(DateTime.now()).obs;
  final selectedDay = Rxn<DateTime>();
  //contains each day with the list of events assigned to that day
  final monthEvents = <DateTime, List<CalendarEvent>>{}.obs;

  StreamSubscription? _eventsSub;

  //track current watch window to avoid redundant resubscribes
  DateTime? _watchedStart;
  DateTime? _watchedEndExcl;

  final List<Worker> _workers = [];

  //runs once when the controller is created and calls the method _watchMonth
  @override
  void onInit() {
    super.onInit();

    // auto-select today
    final today = justDate(DateTime.now());
    if (monthStart(today) == visibleMonth.value) {
      selectedDay.value = today;
    }

    // react to month changes
    _workers.add(
      ever<DateTime>(visibleMonth, (m) async {
        await _resubscribeFor(m);
        // auto-select today when navigating to the current month, otherwise null
        final t = justDate(DateTime.now());
        selectedDay.value = (monthStart(t) == visibleMonth.value) ? t : null;
      }),
    );

    // initial subscribe
    _resubscribeFor(visibleMonth.value);
  }

  //it is used when moving between the months, and sets the previously selected day to null
  //resubscribes to the firestore by calling the method _watchMonth
  Future<void> goToMonth(DateTime m) async {
    visibleMonth.value = monthStart(m); // workers will handle re-subscribe
  }

  //stores the selected day to present the available events
  void onDayTapped(DateTime day) {
    if (day.month != visibleMonth.value.month)
      return; // ignore padding cells that are added for the overall style
    selectedDay.value = justDate(day);
  }

  //checks if the day has at least one event
  bool hasEvent(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return monthEvents.containsKey(d);
  }

  //returns the list of events in one day or an empty list
  List<CalendarEvent> eventsFor(DateTime day) {
    final d = DateTime(day.year, day.month, day.day); // local day
    return monthEvents[d] ?? const <CalendarEvent>[];
  }

  //this method is used to set up or reset the firestor listener for the month containing m
  //which is why we call it in the int and in goToMonth when we move to another month
  // 2)
  Future<void> _resubscribeFor(DateTime m) async {
    final start = monthStart(m);
    final endExcl = monthEndExclusive(m);

    // If already watching the same window, skip
    if (_watchedStart == start && _watchedEndExcl == endExcl) return;

    _watchedStart = start;
    _watchedEndExcl = endExcl;

    await _eventsSub?.cancel();

    // Build month window
    Query<Map<String, dynamic>> q = db
        .collection('events')
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(endExcl))
        .orderBy('start');

    //Key rule to prevent ADHD-only past events from appearing to caregiver:
    //Whether linked or not, fetch ONLY docs that include the logged-in user (currentUid).
    //Backfill ensures upcoming ADHD events include the caregiver, so they appear naturally.
    q = q.where('participants', arrayContains: currentUid);

    //real tim subscription where firestore pushes a new snap if the matching docs are modified
    _eventsSub = q.snapshots().listen((snap) {
      final map = <DateTime, List<CalendarEvent>>{};

      //iterate over every document in the snapshot
      for (final doc in snap.docs) {
        final ev = CalendarEvent.fromDoc(doc);
        final s = ev.start.toLocal();
        final key = DateTime(s.year, s.month, s.day);
        (map[key] ??= <CalendarEvent>[]).add(ev);
      }

      //Inside each day, sort events by their start time so the UI shows them in order
      for (final list in map.values) {
        list.sort((a, b) => a.start.compareTo(b.start));
      }

      monthEvents.assignAll(map);
      monthEvents.refresh();
    });
  }

  //Delete an existing event
  Future<void> deleteEvent(String eventId) async {
    await db.collection('events').doc(eventId).delete();

    //manually remove from local cache immediately (before Firestore pushes)
    final keysToRemove = <DateTime>[];

    monthEvents.forEach((key, list) {
      list.removeWhere((ev) => ev.id == eventId);
      if (list.isEmpty) keysToRemove.add(key); // mark empty day for removal
    });

    for (final k in keysToRemove) {
      monthEvents.remove(k);
    }

    //tell GetX observers to rebuild right away
    monthEvents.refresh();
  }

  @override
  void onClose() {
    _eventsSub?.cancel();
    for (final w in _workers) {
      w.dispose();
    }
    super.onClose();
  }
}
