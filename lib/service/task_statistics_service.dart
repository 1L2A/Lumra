import 'package:cloud_firestore/cloud_firestore.dart';

class TaskStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates task statistics when a new task is created
  /// Increments both total and uncompleted counters
  Future<void> onTaskCreated(String userId) async {
    final now = DateTime.now();
    final dayId = _formatDayId(now);
    final weekId = _formatWeekId(now);

    final batch = _firestore.batch();

    // Update daily stats
    final dailyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('days')
        .collection('days')
        .doc(dayId);

    batch.set(dailyRef, {
      'total': FieldValue.increment(1),
      'uncompleted': FieldValue.increment(1),
      'completed': 0, // Initialize if doesn't exist
    }, SetOptions(merge: true));

    // Update weekly stats
    final weeklyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('weeks')
        .collection('weeks')
        .doc(weekId);

    batch.set(weeklyRef, {
      'total': FieldValue.increment(1),
      'uncompleted': FieldValue.increment(1),
      'completed': 0, // Initialize if doesn't exist
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Updates task statistics when a task is checked (marked as completed)
  /// Increments completed and decrements uncompleted
  Future<void> onTaskChecked(String userId) async {
    final now = DateTime.now();
    final dayId = _formatDayId(now);
    final weekId = _formatWeekId(now);

    final batch = _firestore.batch();

    // Update daily stats
    final dailyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('days')
        .collection('days')
        .doc(dayId);

    batch.set(dailyRef, {
      'completed': FieldValue.increment(1),
      'uncompleted': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    // Update weekly stats
    final weeklyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('weeks')
        .collection('weeks')
        .doc(weekId);

    batch.set(weeklyRef, {
      'completed': FieldValue.increment(1),
      'uncompleted': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Updates task statistics when a task is unchecked (marked as incomplete)
  /// Decrements completed and increments uncompleted
  Future<void> onTaskUnchecked(String userId) async {
    final now = DateTime.now();
    final dayId = _formatDayId(now);
    final weekId = _formatWeekId(now);

    final batch = _firestore.batch();

    // Update daily stats
    final dailyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('days')
        .collection('days')
        .doc(dayId);

    batch.set(dailyRef, {
      'completed': FieldValue.increment(-1),
      'uncompleted': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Update weekly stats
    final weeklyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('weeks')
        .collection('weeks')
        .doc(weekId);

    batch.set(weeklyRef, {
      'completed': FieldValue.increment(-1),
      'uncompleted': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Gets daily statistics for a specific day
  Future<Map<String, int>> getDailyStats(String userId, DateTime date) async {
    final dayId = _formatDayId(date);
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('days')
        .collection('days')
        .doc(dayId)
        .get();

    if (!doc.exists) {
      return {'total': 0, 'completed': 0, 'uncompleted': 0};
    }

    final data = doc.data()!;
    return {
      'total': (data['total'] as int?) ?? 0,
      'completed': (data['completed'] as int?) ?? 0,
      'uncompleted': (data['uncompleted'] as int?) ?? 0,
    };
  }

  /// Gets weekly statistics for a specific week
  Future<Map<String, int>> getWeeklyStats(String userId, DateTime date) async {
    final weekId = _formatWeekId(date);
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('weeks')
        .collection('weeks')
        .doc(weekId)
        .get();

    if (!doc.exists) {
      return {'total': 0, 'completed': 0, 'uncompleted': 0};
    }

    final data = doc.data()!;
    return {
      'total': (data['total'] as int?) ?? 0,
      'completed': (data['completed'] as int?) ?? 0,
      'uncompleted': (data['uncompleted'] as int?) ?? 0,
    };
  }

  /// Formats a date into a day ID string (YYYY-MM-DD)
  String _formatDayId(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Formats a date into a week ID string (yyyy-Www)
  /// Uses ISO 8601 week numbering
  String _formatWeekId(DateTime date) {
    // Calculate the week number using ISO 8601 standard
    final weekNumber = _getWeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Calculates the week number for a given date (week starts on Sunday)
  int _getWeekNumber(DateTime date) {
    // Week starts on Sunday
    final jan1 = DateTime(date.year, 1, 1);
    final jan1Weekday = jan1.weekday;
    // If Jan 1 is Sunday (7), it's already the first Sunday
    // Otherwise, find the previous Sunday
    final firstSunday = jan1Weekday == 7
        ? jan1
        : jan1.subtract(Duration(days: jan1Weekday));

    final daysSinceFirstSunday = date.difference(firstSunday).inDays;
    return (daysSinceFirstSunday / 7).floor() + 1;
  }
}
