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
  final RxMap<String, double> activityCounts = <String, double>{}.obs;
  final Map<String, String> _globalActivityMap = {};
  Map<String, double> _customActivityCounts = {};
  Map<String, double> _systemActivityCounts = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customActivitySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _systemActivitySub;

  // NEW for weekly and daily:
  int? _currentMood; // 1–5 or null
  double _taskPercent = 0; // 0–100
  int _focusMinutesCache = 0; // 0–240
  int _activitiesCount = 0; // total completed

  // composite daily score (0–100) and weekly array (Sun=0..Sat=6)
  final RxDouble dailyScore = 0.0.obs;
  final RxList<double> weeklyScores = List<double>.filled(7, 0.0).obs;
  final RxList<double> weeklyHistory = <double>[].obs;

  Timer? _midnightTimer;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    print('⚡⚡ DASHBOARD DEBUG ACTIVE (DashboardController.onInit) ⚡⚡');
    _initAll();
  }

  Future<void> _initAll() async {
    final caregiverUid = authController.currentUser!.uid;

    try {
      final snap = await db.collection('users').doc(caregiverUid).get();
      final data = snap.data()!;

      // from your users collection
      adhdUid = data['linkedUserId'] as String;
      print('[DEBUG] _initAll → adhdUid=$adhdUid');

      // Load weekly scores + history first
      await _loadWeeklyScores();
      await _loadWeeklyHistory();
      print(
        '[DEBUG] _initAll → loaded weeklyScores=${weeklyScores.toList()}, weeklyHistory=${weeklyHistory.toList()}',
      );

      // Handle week change (shift + reset) once per week
      await _ensureWeekBoundary();

      _isInitialized = true;

      // attach all realtime listeners that use adhdUid
      _listenToAdhdTasks();
      _listenToDailyMood();
      _listenToFocusSessions();
      // 3. Start Activity Listeners
      _listenToCustomActivities();
      _listenToSystemActivities();

      _scheduleMidnightSave(); // schedule daily saving at midnight
    } catch (e) {
      print('[DEBUG] _initAll ERROR → $e');
      totalTasks.value = 0;
      checkedTasks.value = 0;
      dailyMood.value = null;
      todayFocusMinutes.value = 0;
    }
  }

  // ---------- WEEK BOUNDARY HANDLING ----------

  // helper: Sunday = 0 .. Saturday = 6
  int _dayIndex(DateTime d) {
    return d.weekday % 7;
  }

  String _weekKeyFor(DateTime now) {
    final idx = _dayIndex(now); // 0..6
    // Sunday-based week start
    final weekStart = DateTime(now.year, now.month, now.day - idx);
    final y = weekStart.year.toString().padLeft(4, '0');
    final m = weekStart.month.toString().padLeft(2, '0');
    final d = weekStart.day.toString().padLeft(2, '0');
    return '$y-$m-$d'; // e.g. "2025-11-30" for week starting Sunday
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da'; // e.g. 2025-11-30
  }

  Future<void> _ensureWeekBoundary() async {
    final now = DateTime.now();
    final currentWeekKey = _weekKeyFor(now); // Sunday-based
    final doc = await db.collection('users').doc(adhdUid).get();
    final data = doc.data() ?? {};

    final prevWeekKey = data['weeklyWeekKey'] as String?;

    print(
      '[DEBUG] _ensureWeekBoundary → prevWeekKey=$prevWeekKey, '
      'currentWeekKey=$currentWeekKey, weeklyScores=${weeklyScores.toList()}, '
      'weeklyHistory=${weeklyHistory.toList()}',
    );

    // 1) First ever → just store key, no shift/reset
    if (prevWeekKey == null) {
      await db.collection('users').doc(adhdUid).set({
        'weeklyWeekKey': currentWeekKey,
      }, SetOptions(merge: true));

      print(
        '[DEBUG] _ensureWeekBoundary → first run, '
        'set weeklyWeekKey=$currentWeekKey (no shift/reset)',
      );
      return;
    }

    // 2) If we go to same or OLDER week → do NOT shift/reset
    if (currentWeekKey.compareTo(prevWeekKey) <= 0) {
      print(
        '[DEBUG] _ensureWeekBoundary → currentWeekKey <= prevWeekKey '
        '($currentWeekKey <= $prevWeekKey) → no shift/reset',
      );
      return;
    }

    // 3) Only now: we moved FORWARD to a NEW week → finalize old week
    final scores = List<double>.from(weeklyScores);
    double lastWeekAvg = 0.0;
    if (scores.isNotEmpty) {
      final sum = scores.fold<double>(0.0, (s, v) => s + v);
      lastWeekAvg = sum / scores.length;
    }

    print(
      '[DEBUG] _ensureWeekBoundary → NEWER WEEK, '
      'lastWeekAvg=$lastWeekAvg, oldScores=$scores',
    );

    final hist = List<double>.from(weeklyHistory);
    hist.add(lastWeekAvg);
    if (hist.length > 8) {
      final removed = hist.removeAt(0);
      print('[DEBUG] _ensureWeekBoundary → removed oldest week=$removed');
    }

    final resetWeek = List<double>.filled(7, 0.0);
    weeklyHistory.assignAll(hist);
    weeklyScores.assignAll(resetWeek);

    await db.collection('users').doc(adhdUid).set({
      'weeklyHistory': hist,
      'weeklyDashboard': resetWeek,
      'weeklyWeekKey': currentWeekKey,
    }, SetOptions(merge: true));

    print(
      '[DEBUG] _ensureWeekBoundary → AFTER shift history=$hist, '
      'resetWeek=$resetWeek, saved weeklyWeekKey=$currentWeekKey',
    );
  }

  Future<void> _loadWeeklyScores() async {
    final doc = await db.collection('users').doc(adhdUid).get();
    final data = doc.data();
    if (data != null && data['weeklyDashboard'] is List) {
      final raw = data['weeklyDashboard'] as List;
      final arr = List<double>.filled(7, 0.0);
      final len = raw.length < 7 ? raw.length : 7;
      for (int i = 0; i < len; i++) {
        arr[i] = (raw[i] as num).toDouble();
      }
      weeklyScores.assignAll(arr);
      print('[DEBUG] _loadWeeklyScores → weeklyScores=$arr');
    } else {
      print(
        '[DEBUG] _loadWeeklyScores → no weeklyDashboard found, using zeros',
      );
    }
  }

  // load last 8 weeks history from Firestore
  Future<void> _loadWeeklyHistory() async {
    final doc = await db.collection('users').doc(adhdUid).get();
    final data = doc.data();
    if (data != null && data['weeklyHistory'] is List) {
      final raw = data['weeklyHistory'] as List;
      final list = raw.map((e) => (e as num).toDouble()).toList();

      // keep only last 8 items
      if (list.length > 8) {
        weeklyHistory.assignAll(list.sublist(list.length - 8));
      } else {
        weeklyHistory.assignAll(list);
      }
      print(
        '[DEBUG] _loadWeeklyHistory → weeklyHistory=${weeklyHistory.toList()}',
      );
    } else {
      print('[DEBUG] _loadWeeklyHistory → no weeklyHistory found');
    }
  }

  // ---------- LISTENERS (unchanged logic) ----------

  void _listenToAdhdTasks() {
    _tasksSub?.cancel();

    _tasksSub = db
        .collection('users')
        .doc(adhdUid)
        .collection('tasks')
        .snapshots()
        .listen(
          (snap) {
            final now = DateTime.now();

            final todayKey =
                '${now.year.toString().padLeft(4, '0')}-'
                '${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}';

            final todayDocs = snap.docs.where((d) {
              final data = d.data();

              final dk = data['dateKey'];
              if (dk is String) {
                return dk == todayKey;
              }

              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                return dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day;
              }

              return true;
            }).toList();

            final int total = todayDocs.length; // tasks for today only
            final int checked = todayDocs
                .where((d) => d.data()['isChecked'] == true)
                .length;

            totalTasks.value = total;
            checkedTasks.value = checked;

            updateTaskProgress(checked, total);
          },
          onError: (e) {
            print('[DEBUG] _listenToAdhdTasks ERROR → $e');
            totalTasks.value = 0;
            checkedTasks.value = 0;
            updateTaskProgress(0, 0);
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
              updateDailyMood(null);
              return;
            }

            final val = data['dailyMood'];
            int? moodInt;
            if (val is int) {
              moodInt = val;
            } else if (val is num) {
              moodInt = val.toInt();
            }

            dailyMood.value = moodInt;
            updateDailyMood(moodInt);
          },
          onError: (_) {
            dailyMood.value = null;
            updateDailyMood(null);
          },
        );
  }

  void _listenToFocusSessions() {
    _focusSub?.cancel();

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
            final minutes = (totalSeconds / 60).round();
            todayFocusMinutes.value = minutes;
            updateFocusMinutes(minutes);
          },
          onError: (_) {
            todayFocusMinutes.value = 0;
            updateFocusMinutes(0);
          },
        );
  }

  String _getCategoryFromId(String activityId) {
    final String id = activityId.trim();
    switch (id) {
      case '0twbkE4nsbAjGacxFTaI':
        return 'Mindfulness';
      case '5bC5hiEUr7T0IKZ1W2RV':
        return 'Creative';
      case 'opO3WTWQU1aY1CuH6qit':
        return 'Sport';
      case 'Activity4':
        return 'Sport';
      case 'Activity5':
        return 'Learning';
      case 'Activity6':
        return 'Creative';
      case 'Activity7':
        return 'Sport';
      case 'Activity8':
        return 'Sport';
      case 'Activity9':
        return 'Creative';
      case 'Activity10':
        return 'Mindfulness';
      case 'Activity11':
        return 'Learning';
      case 'Activity12':
        return 'mindfulness';
      default:
        return 'other';
    }
  }

  void _listenToCustomActivities() {
    _customActivitySub?.cancel();
    _customActivitySub = db
        .collection('users')
        .doc(adhdUid)
        .collection('activities')
        .where('isChecked', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          final Map<String, double> tempCounts = {};

          for (var doc in snap.docs) {
            final data = doc.data();
            String category = (data['category'] ?? 'other')
                .toString()
                .toLowerCase();

            if (tempCounts.containsKey(category)) {
              tempCounts[category] = tempCounts[category]! + 1;
            } else {
              tempCounts[category] = 1;
            }
          }

          _customActivityCounts = tempCounts;
          _mergeAndPublishActivityCounts();
        });
  }

  void _listenToSystemActivities() {
    _systemActivitySub?.cancel();

    _systemActivitySub = db
        .collection('users')
        .doc(adhdUid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          final Map<String, double> tempCounts = {};

          for (var doc in snap.docs) {
            final String activityId = doc.id;
            String category = _getCategoryFromId(activityId).toLowerCase();

            if (tempCounts.containsKey(category)) {
              tempCounts[category] = tempCounts[category]! + 1;
            } else {
              tempCounts[category] = 1;
            }
          }

          _systemActivityCounts = tempCounts;
          _mergeAndPublishActivityCounts();
        });
  }

  void _mergeAndPublishActivityCounts() {
    final Map<String, double> merged = {};

    _customActivityCounts.forEach((key, value) {
      merged[key] = value;
    });

    _systemActivityCounts.forEach((key, value) {
      if (merged.containsKey(key)) {
        merged[key] = merged[key]! + value;
      } else {
        merged[key] = value;
      }
    });

    activityCounts.value = merged;

    final totalCompleted = merged.values.fold<double>(0, (sum, v) => sum + v);
    updateActivitiesCount(totalCompleted.toInt());
  }

  // ---------- SCORING HELPERS ----------

  double _moodScore() {
    if (_currentMood == null) return 0.0;
    final m = _currentMood!.clamp(1, 5);
    return (m - 1) / 4.0;
  }

  double _taskScore() {
    if (_taskPercent <= 0) return 0.0;
    return (_taskPercent / 100.0).clamp(0.0, 1.0);
  }

  double _focusScore() {
    if (_focusMinutesCache <= 0) return 0.0;
    final focusPoints = _focusMinutesCache / 30.0; // 30 min = 1 point
    const maxPoints = 8.0; // 240 / 30
    return (focusPoints / maxPoints).clamp(0.0, 1.0);
  }

  double _activityScore() {
    if (_activitiesCount <= 0) return 0.0;

    const maxPoints = 4.0;
    final activityPoints = _activitiesCount.toDouble();

    return (activityPoints / maxPoints).clamp(0.0, 1.0);
  }

  void _recomputeDailyScore() {
    if (!_isInitialized) return;
    final mood = _moodScore();
    final task = _taskScore();
    final focus = _focusScore();
    final act = _activityScore();

    final combined = (mood + task + focus + act) / 4.0;
    dailyScore.value = combined * 100.0;

    _updateWeeklyScoresLive();
    _updateWeeklyHistoryRealtime();
    _saveRealtimeScores();
  }

  double get currentWeekAverage {
    if (weeklyScores.isEmpty) return 0.0;

    final nonZero = weeklyScores.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0.0;

    final sum = nonZero.fold<double>(0.0, (p, e) => p + e);
    return sum / nonZero.length;
  }

  void updateTaskProgress(int completed, int total) {
    if (total <= 0) {
      _taskPercent = 0;
    } else {
      _taskPercent = (completed / total) * 100.0;
    }
    _recomputeDailyScore();
  }

  void updateFocusMinutes(int minutes) {
    _focusMinutesCache = minutes.clamp(0, 240);
    _recomputeDailyScore();
  }

  void updateDailyMood(int? mood) {
    _currentMood = mood;
    _recomputeDailyScore();
  }

  void updateActivitiesCount(int count) {
    _activitiesCount = count.clamp(0, 1000);
    _recomputeDailyScore();
  }

  // ---------- WEEKLY SCORES + HISTORY (REALTIME) ----------

  // keep weeklyScores for today’s index updated
  void _updateWeeklyScoresLive() {
    final idx = _dayIndex(DateTime.now());
    if (weeklyScores.length < 7) {
      weeklyScores.assignAll(List<double>.filled(7, 0.0));
    }
    weeklyScores[idx] = dailyScore.value;
    weeklyScores.refresh();
    print(
      '[DEBUG] _updateWeeklyScoresLive → idx=$idx, weeklyScores=${weeklyScores.toList()}',
    );
  }

  // Only this function updates weeklyHistory realtime (last index)
  Future<void> _updateWeeklyHistoryRealtime() async {
    if (!_isInitialized) return;

    final scores = List<double>.from(weeklyScores);
    double avg = 0.0;
    if (scores.isNotEmpty) {
      final sum = scores.fold<double>(0.0, (s, v) => s + v);
      avg = sum / scores.length;
    }

    print(
      '[DEBUG] _updateWeeklyHistoryRealtime → weeklyScores=$scores, avg=$avg, BEFORE=${weeklyHistory.toList()}',
    );

    final updated = List<double>.from(weeklyHistory);
    if (updated.isEmpty) {
      // first week slot
      updated.add(avg);
    } else {
      // current week is always last index
      updated[updated.length - 1] = avg;
    }

    weeklyHistory.assignAll(_trimTo8(updated));

    await db.collection('users').doc(adhdUid).set({
      'weeklyHistory': weeklyHistory.toList(),
    }, SetOptions(merge: true));

    print(
      '[DEBUG] _updateWeeklyHistoryRealtime → AFTER=${weeklyHistory.toList()}',
    );
  }

  // ensure lists never exceed 8 items
  List<double> _trimTo8(List<double> list) {
    if (list.length <= 8) return list;
    return list.sublist(list.length - 8);
  }

  // Save weeklyDashboard only (no weeklyHistory here anymore)
  Future<void> _saveRealtimeScores() async {
    if (!_isInitialized) return;

    print(
      '[DEBUG] _saveRealtimeScores → weeklyDashboard=${weeklyScores.toList()}',
    );

    await db.collection('users').doc(adhdUid).set({
      'weeklyDashboard': weeklyScores.toList(),
    }, SetOptions(merge: true));
  }

  // ---------- MIDNIGHT SAVE (ONLY weeklyDashboard) ----------

  Future<void> _saveDailyScoreToWeekArray() async {
    final now = DateTime.now();
    final dayIdx = _dayIndex(now);

    print(
      '[DEBUG] _saveDailyScoreToWeekArray → dayIdx=$dayIdx, BEFORE weeklyScores=${weeklyScores.toList()}',
    );

    if (weeklyScores.length < 7) {
      final fill = List<double>.filled(7, 0.0);
      for (int i = 0; i < weeklyScores.length && i < 7; i++) {
        fill[i] = weeklyScores[i];
      }
      weeklyScores.assignAll(fill);
    }

    weeklyScores[dayIdx] = dailyScore.value;

    await db.collection('users').doc(adhdUid).set({
      'weeklyDashboard': weeklyScores.toList(),
    }, SetOptions(merge: true));

    print(
      '[DEBUG] _saveDailyScoreToWeekArray → AFTER weeklyScores=${weeklyScores.toList()}',
    );
  }

  void _scheduleMidnightSave() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    print(
      '[DEBUG] _scheduleMidnightSave → now=$now, tomorrow=$tomorrow, diff=$diff',
    );

    _midnightTimer = Timer(diff, () async {
      print(
        '[DEBUG] _scheduleMidnightSave TIMER FIRED → calling _saveDailyScoreToWeekArray',
      );
      await _saveDailyScoreToWeekArray();
      _scheduleMidnightSave();
    });
  }

  @override
  void onClose() {
    _tasksSub?.cancel();
    _moodSub?.cancel();
    _focusSub?.cancel();
    _customActivitySub?.cancel();
    _systemActivitySub?.cancel();
    _midnightTimer?.cancel();
    super.onClose();
  }
}
