import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/view/Homepage/Calendar/calendarView.dart';

/// Call this from any onPressed

void openCalendar({required String currentUid}) {
  // Only create if not already registered
  if (!Get.isRegistered<CalendarController>()) {
    Get.put(
      CalendarController(FirebaseFirestore.instance, currentUid),
    ); //puts the CalendarController in the GetX's dependency graph
  }

  // Pass so it can find the right controller (later in CalendarView we will use Get.find)
  Get.to(() => const CalendarPage());
}
