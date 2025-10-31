import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Homepage/Calendar/calendarController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/utils/customWidgets/toastservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventController extends GetxController {
  //for current User
  final FirebaseFirestore db;
  final String currentUid;
  late final CalendarController calendarController;

  //The Inputs
  final titleController = TextEditingController();
  final eventStart = Rxn<Timestamp>();
  final eventEnd = Rxn<Timestamp>();

  // Validation state for my view
  var titleFieldTouched = true.obs;
  var titleError = RxnString();
  var startError = RxnString();
  var endError = RxnString();

  var isFormValid = false.obs;

  var isEventAdded = false.obs;

  String? _originalTitle;
  Timestamp? _originalStart;
  Timestamp? _originalEnd;

  final canSubmit = false.obs;

  AddEventController(this.db, this.currentUid);

  //to get the date from the calander controller
  @override
  void onInit() {
    super.onInit();
    // register CalendarController if needed
    if (!Get.isRegistered<CalendarController>()) {
      calendarController = Get.put(
        CalendarController(this.db, this.currentUid),
      );
    } else {
      calendarController = Get.find<CalendarController>();
    }
  }

  void loadFromEvent(dynamic e) {
    // Expecting CalendarEvent with: id, title(String), start(DateTime), end(DateTime)
    titleController.text = e.title;
    eventStart.value = Timestamp.fromDate(e.start);
    eventEnd.value = Timestamp.fromDate(e.end);

    _originalTitle = e.title;
    _originalStart = eventStart.value;
    _originalEnd = eventEnd.value;

    validateTitle(titleController.text);
    validateTimes();
    updateFormValidity();
    _updateCanSubmit();
  }

  void prepareForAdd() {
    _originalTitle = null;
    _originalStart = null;
    _originalEnd = null;

    titleController.clear();
    eventStart.value = null;
    eventEnd.value = null;

    titleError.value = null;
    startError.value = null;
    endError.value = null;

    isFormValid.value = false;
    canSubmit.value = false;
  }

  // ------------------ Title validate ------------------ //
  void updateTitle(String value) {
    titleFieldTouched.value = true;
    validateTitle(value);
    updateFormValidity();
    _updateCanSubmit();
  }

  void validateTitle(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      titleError.value = "Title is required";
    } else {
      titleError.value = null; //when error no there, dont make red
    }
  }

  // ------------------ Time validate ------------------ //

  //whenever start or end changes
  void validateTimes() {
    final now = DateTime.now();
    final nowRounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    // Validate start
    if (eventStart.value == null) {
      startError.value = "Start time is required";
    } else {
      final startDate = eventStart.value!.toDate();
      final startRounded = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startDate.hour,
        startDate.minute,
      );

      if (startRounded.isBefore(nowRounded)) {
        startError.value = "Start time cannot be in the past.";
      } else {
        startError.value = null;
      }
    }

    // validate & default end
    if (eventStart.value != null) {
      if (eventEnd.value == null) {
        // default will be start + 1h
        final startDate = eventStart.value!.toDate();
        eventEnd.value = Timestamp.fromDate(
          startDate.add(const Duration(hours: 1)),
        );
        endError.value = null;
      } else if (!eventEnd.value!.toDate().isAfter(
        eventStart.value!.toDate(),
      )) {
        endError.value = "End time must be after start time";
      } else if (eventEnd.value!.toDate().isBefore(now)) {
        endError.value = "End time cannot be in the past";
      } else {
        endError.value = null;
      }
    } else {
      // if no start, don't force end
      endError.value = null;
    }
  }

  void updateFormValidity() {
    isFormValid.value =
        titleError.value == null &&
        startError.value == null &&
        endError.value == null;
  }

  //Enable button only when valid and changed (in edit mode)
  void _updateCanSubmit() {
    final editing =
        _originalTitle != null ||
        _originalStart != null ||
        _originalEnd != null;
    if (!editing) {
      canSubmit.value = isFormValid.value; // add mode
      return;
    }
    canSubmit.value = isFormValid.value && _hasChanges(); // edit mode
  }

  bool _hasChanges() {
    if (_originalTitle == null &&
        _originalStart == null &&
        _originalEnd == null) {
      return true; // add mode
    }
    final tChanged = titleController.text.trim() != (_originalTitle ?? '');
    final sChanged =
        eventStart.value?.seconds != _originalStart?.seconds ||
        eventStart.value?.nanoseconds != _originalStart?.nanoseconds;
    final eChanged =
        eventEnd.value?.seconds != _originalEnd?.seconds ||
        eventEnd.value?.nanoseconds != _originalEnd?.nanoseconds;
    return tChanged || sChanged || eChanged;
  }

  // Pick time
  Future<void> pickTime({required bool isStart}) async {
    // Get the day chosen from the calendar
    final baseDate = Get.find<CalendarController>().selectedDay.value;

    if (baseDate == null) {
      ToastService.error("Please select a date first");
      return;
    }

    // Open the time picker in input mode
    final TimeOfDay? time = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, //number input mode
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BColors.buttonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: BColors.accent,
              dayPeriodTextColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Merging the chosen date (from calendar) with the chosen time
      final finalDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );

      // Save into The Rx values
      if (isStart) {
        eventStart.value = Timestamp.fromDate(finalDateTime);
      } else {
        eventEnd.value = Timestamp.fromDate(finalDateTime);
      }
      validateTimes(); // run validation whenever a time is picked
      updateFormValidity();
      _updateCanSubmit();
    }
  }

  // ------------------ Form ------------------ //
  bool validateForm() {
    // Mark title as touched so error shows
    titleFieldTouched.value = true;

    validateTitle(titleController.text);
    validateTimes();

    // Update form validity (for the button)
    updateFormValidity();
    _updateCanSubmit();

    return endError.value == null &&
        startError.value == null &&
        titleError.value == null;
  }

  // Now adding the event
  Future<void> addEventToFirebase() async {
    if (!validateForm()) return;

    try {
      // Fetch the current user document
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUid)
          .get();

      // Extract caregiverId if any
      final userData = userDoc.data();
      final caregiverId = userData?["linkedUserId"];

      //linking the event with the other user
      final participants = [currentUid];
      if (caregiverId != null && caregiverId.toString().isNotEmpty) {
        participants.add(caregiverId);
      }

      //Add event
      await FirebaseFirestore.instance.collection("events").add({
        "title": titleController.text.trim(),
        "start": eventStart.value,
        "end": eventEnd.value,
        "participants": participants,
        "created_by": currentUid,
        "created_at": FieldValue.serverTimestamp(),
      });

      ToastService.success(
        "All done! Your event just made the calendar happier",
      );
      isEventAdded.value = true;

      //Clearing form when done
      titleController.clear();
      eventStart.value = null;
      eventEnd.value = null;
      titleError.value = null;
      startError.value = null;
      endError.value = null;
      isFormValid.value = false;
      _originalTitle = null;
      _originalStart = null;
      _originalEnd = null;
      _updateCanSubmit();
    } catch (e) {
      ToastService.error("Couldn’t save your event. Give it another go!");
    }
  }

  // Update
  Future<void> updateEventInFirebase(String eventId) async {
    if (!validateForm()) return;
    try {
      await db.collection("events").doc(eventId).update({
        "title": titleController.text.trim(),
        "start": eventStart.value,
        "end": eventEnd.value,
        "updated_at": FieldValue.serverTimestamp(),
      });
      ToastService.success("Your event is updated successfully.");
    } catch (e) {
      ToastService.error("Couldn’t update your event.");
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}
