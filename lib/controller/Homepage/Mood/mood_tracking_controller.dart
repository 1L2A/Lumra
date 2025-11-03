import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // for date formatting (yyyy-MM-dd)
import 'package:lumra_project/controller/auth/auth_controller.dart';

class MoodTrackingController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  String get getCurrentUserId => _userId;

  // inside MoodTrackingController
  Stream<DocumentSnapshot<Map<String, dynamic>>> userMoodStream() {
    return _userDoc.snapshots();
  }

  /// Get current user ID
  String get _userId {
    final user = _authController.currentUser;
    if (user == null) throw Exception("No user is logged in.");
    return user.uid;
  }

  ///  Reference to the current user document
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  /// Helper → format DateTime to "yyyy-MM-dd"
  String _todayString([DateTime? date]) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(date ?? DateTime.now());
  }

  // -------------------------------------------------------------
  //  INITIALIZATION LOGIC
  // -------------------------------------------------------------

  /// Load today's mood.
  /// If none found, set default dailyMood=3 and MoodChosenToday=false
  Future<int> getTodayMood() async {
    final doc = await _userDoc.get();

    if (doc.exists) {
      final data = doc.data()!;
      final hasDaily = data.containsKey('dailyMood');
      if (hasDaily) {
        final chosen = data['MoodChosenToday'] ?? false;
        return chosen ? data['dailyMood'] ?? 3 : 3;
      }
    }

    // If no mood data exists → initialize
    await _userDoc.set({
      'dailyMood': 3,
      'MoodChosenToday': false,
    }, SetOptions(merge: true));

    return 3;
  }

  // -------------------------------------------------------------
  //  USER INTERACTION
  // -------------------------------------------------------------

  /// When the user chooses a mood emoji manually
  Future<void> setTodayMood(int moodValue) async {
    await checkAndResetIfNeeded();

    await _userDoc.set({
      'dailyMood': moodValue,
      'MoodChosenToday': true,
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  //  DAILY RESET LOGIC
  // -------------------------------------------------------------

  /// Reset at midnight → mood=3, not chosen
  Future<void> resetDailyMood() async {
    await _userDoc.set({
      'dailyMood': 3,
      'MoodChosenToday': false,
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // WEEKLY HANDLING
  // -------------------------------------------------------------

  /// Add today’s mood to the weekly list
  Future<void> _addToWeekly(int moodValue) async {
    final doc = await _userDoc.get();

    final now = DateTime.now();
    final todayStr = _todayString(now);

    if (!doc.exists) {
      await _userDoc.set({
        'weeklyMood': {
          'days': [moodValue],
          'lastAdded': todayStr,
        },
      }, SetOptions(merge: true));
      return;
    }

    final data = doc.data()!;
    final weekly = data['weeklyMood'] ?? {'days': [], 'lastAdded': todayStr};
    final List<int> days = List<int>.from(weekly['days'] ?? []);

    days.add(moodValue);

    await _userDoc.set({
      'weeklyMood': {'days': days, 'lastAdded': todayStr},
    }, SetOptions(merge: true));
  }

  /// Return current weekly array
  Future<List<int>> getWeeklyArray() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final weekly = data['weeklyMood'] ?? {'days': []};
    final days = List<int>.from(weekly['days'] ?? []);

    // If a week is complete, reset
    if (days.length >= 7) {
      await _userDoc.set({
        'weeklyMood': {'days': [], 'lastAdded': _todayString()},
      }, SetOptions(merge: true));
    }

    return days;
  }

  // -------------------------------------------------------------
  // DAILY CHECK — RUN ON APP OPEN
  // -------------------------------------------------------------

  Future<void> checkAndResetIfNeeded() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final weeklyData =
        data['weeklyMood'] ?? {'days': [], 'lastAdded': _todayString()};
    final List<int> days = List<int>.from(weeklyData['days'] ?? []);
    final lastAddedStr = weeklyData['lastAdded'] as String? ?? _todayString();
    final now = DateTime.now();

    DateTime? lastAddedDate;
    try {
      lastAddedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(lastAddedStr);
    } catch (e) {
      print(' Invalid lastAdded format ($lastAddedStr). Using today.');
      lastAddedDate = now;
    }

    // Compare by calendar day (ignores hour) but keep time for storage
    final DateTime lastAddedDay = DateTime(
      lastAddedDate.year,
      lastAddedDate.month,
      lastAddedDate.day,
    );
    final DateTime todayDay = DateTime(now.year, now.month, now.day);

    final diffDays = todayDay.difference(lastAddedDay).inDays;
    print(
      ' checkAndResetIfNeeded → lastAdded=$lastAddedStr | now=${_todayString()} | diffDays=$diffDays',
    );

    // Same calendar day → no action
    if (diffDays <= 0) return;

    if (diffDays == 1) {
      // ✅ Before resetting, add yesterday's final mood to weekly list
      final yesterdayDoc = await _userDoc.get();
      final yesterdayData = yesterdayDoc.data() ?? {};
      final yesterdayMood = yesterdayData['dailyMood'] ?? 3;
      await _addToWeekly(yesterdayMood);

      // ✅ Then reset daily for the new day
      await _userDoc.set({
        'dailyMood': 3,
        'MoodChosenToday': false,
      }, SetOptions(merge: true));

      print("🕛 New day — yesterday's mood added to weekly and daily reset.");
    } else if (diffDays > 1) {
      //  Missed multiple days → fill missed days with 3
      final missed = (diffDays - 1).clamp(0, 365);
      for (int i = 0; i < missed; i++) {
        days.add(3);
      }

      await _userDoc.set({
        'dailyMood': 3,
        'MoodChosenToday': false,
        'weeklyMood': {
          'days': days,
          //  Keep full date + time string
          'lastAdded': _todayString(now),
        },
      }, SetOptions(merge: true));

      print(" Missed $missed day(s) — filled with 3s and updated lastAdded.");
    }
  }
}
