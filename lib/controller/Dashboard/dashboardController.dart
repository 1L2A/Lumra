import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore db;
  final AuthController authController = Get.find<AuthController>();

  DashboardController(this.db);

  /// ADHD user ID linked to this caregiver
  late final String adhdUid;

  /// Reactive counts for UI
  final totalTasks = 0.obs;
  final checkedTasks = 0.obs;

  final RxnInt dailyMood = RxnInt();

  /// NEW by JANA: today's total focus minutes for the ADHD user
  final todayFocusMinutes = 0.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _moodSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _focusSub; // NEW
  @override
  void onInit() {
    super.onInit();
    _initAll();
  }

  Future<void> _initAll() async {
    final caregiverUid = authController.currentUser!.uid;

    try {
      final snap = await db.collection('users').doc(caregiverUid).get();
      final data = snap.data()!;

      //from your users collection
      adhdUid = data['linkedUserId'] as String;

      // attach all realtime listeners that use adhdUid
      _listenToAdhdTasks();
      _listenToDailyMood();
      _listenToFocusSessions();
    } catch (e) {
      totalTasks.value = 0;
      checkedTasks.value = 0;
      dailyMood.value = null;
      todayFocusMinutes.value = 0;
    }
  }

  // Realtime listener on /users/{adhdUid}/tasks
  void _listenToAdhdTasks() {
    _tasksSub?.cancel();

    _tasksSub = db
        .collection('users')
        .doc(adhdUid)
        .collection('tasks')
        .snapshots()
        .listen(
          (snap) {
            final docs = snap.docs;

            final int total = docs.length; //total number of tasks
            final int checked =
                docs //checked tasks
                    .where((d) => d.data()['isChecked'] == true)
                    .length;

            totalTasks.value = total;
            checkedTasks.value = checked;
          },
          onError: (e) {
            totalTasks.value = 0;
            checkedTasks.value = 0;
          },
        );
  }

  void _listenToDailyMood() {
    _moodSub?.cancel();

    _moodSub = db
        .collection('users')
        .doc(adhdUid) // ADHD user's doc
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            if (data == null || !data.containsKey('dailyMood')) {
              dailyMood.value = null; // hasn't chosen yet
              return;
            }

            // Might be stored as int or num in Firestore, so cast safely
            final val = data['dailyMood'];
            dailyMood.value = val;
          },
          onError: (_) {
            dailyMood.value = null;
          },
        );
  }

  void _listenToFocusSessions() {
    _focusSub?.cancel();

    // compute "today" range
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _focusSub = db
        .collection('users')
        .doc(adhdUid) // ADHD user focus sessions
        .collection('focus_sessions')
        .where('startedAt', isGreaterThanOrEqualTo: startOfDay)
        .where('startedAt', isLessThan: endOfDay)
        .snapshots()
        .listen(
          (snap) {
            int totalSeconds = 0;
            for (final doc in snap.docs) {
              final data = doc.data();
              final seconds = (data['actualSeconds'] ?? 0) as int;
              totalSeconds += seconds;
            }
            todayFocusMinutes.value = (totalSeconds / 60).round();
          },
          onError: (_) {
            todayFocusMinutes.value = 0;
          },
        );
  }

  @override
  void onClose() {
    _tasksSub?.cancel();
    _moodSub?.cancel();
    _focusSub?.cancel();
    super.onClose();
  }
}
