import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/model/Homepage/Reminders/reminderModel.dart';

class ReminderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUid;

  ReminderController({required this.currentUid});

  // Observable list of upcoming reminders
  final upcomingReminders = <ReminderModel>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchUpcomingReminders();
  }

  /// Fetches events that start within the next 24 hours
  Future<void> _fetchUpcomingReminders() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final now = DateTime.now();
      final next24Hours = now.add(const Duration(hours: 24));

      // Query events that start within the next 24 hours
      final query = _firestore
          .collection('events')
          .where('participants', arrayContains: currentUid)
          .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('start', isLessThanOrEqualTo: Timestamp.fromDate(next24Hours))
          .orderBy('start', descending: false);

      final snapshot = await query.get();

      final reminders = snapshot.docs
          .map((doc) => ReminderModel.fromFirestore(doc))
          .toList();

      upcomingReminders.assignAll(reminders);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load reminders: ${e.toString()}';
      upcomingReminders.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream of upcoming reminders for real-time updates
  Stream<List<ReminderModel>> get upcomingRemindersStream {
    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));

    return _firestore
        .collection('events')
        .where('participants', arrayContains: currentUid)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('start', isLessThanOrEqualTo: Timestamp.fromDate(next24Hours))
        .orderBy('start', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Refresh reminders manually
  Future<void> refreshReminders() async {
    await _fetchUpcomingReminders();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
