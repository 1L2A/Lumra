import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/Activity/ActivityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

// ---------------------------------------------------------------------------
// ActivityController Goal:
// 1. Merging: Show CHATBOT activities + INITIAL non-completed activities permanently.
// 2. 24h Expiry: Both CHATBOT activities and INITIAL activity status docs are deleted
//    24 hours after completion.
// 3. Fallback: Only switch to _initialsStream if the merged list is totally empty.
// ---------------------------------------------------------------------------

class Activitycontroller {
  final FirebaseFirestore db;
  final AuthController authController = Get.find<AuthController>();

  Activitycontroller(this.db);

  final Activity = Rxn<Activitymodel>();
  final RxBool isChecked = false.obs;

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController timeController;

  
  void init() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    timeController = TextEditingController();
  }

  // MAIN Stream: Merges CHATBOT (realtime) with INITIAL (non-completed, sync fetch)
  Stream<List<Activitymodel>> activities$() async* {
    final uid = authController.currentUser?.uid;
    if (uid == null) {
      yield const <Activitymodel>[];
      return;
    }

    // 1. Fetch INITIAL activities (synchronously) that are NOT checked yet (fallbackMode: false)
    final initialItems = await getinitialActivity(fallbackMode: false); 

    // 2. Listen to CHATBOT activities in realtime
    await for (final q
        in db
            .collection('users')
            .doc(uid)
            .collection('activities')
            .orderBy('title')
            .snapshots()) {
      final now = DateTime.now();
      final toDelete = <DocumentReference>[];
      final userItems = <Activitymodel>[];

      // A. Process CHATBOT items
      for (final d in q.docs) {
        final m = Activitymodel.fromUserActivityDoc(d);

        // Delete CHATBOT docs AFTER 24h passes (based on expireAt)
        final isExpired = m.expireAt != null && m.expireAt!.toDate().isBefore(now);
        if (isExpired) {
          toDelete.add(d.reference);
          continue; 
        }

        userItems.add(m);
      }
      
      // B. Process INITIAL Status docs for 24h expiry
      // Query for initial activity status docs that have expired
      final statusSnap = await db
          .collection('users')
          .doc(uid)
          .collection('activityStatus')
          .where('expireAt', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in statusSnap.docs) {
        toDelete.add(doc.reference); // Add expired status docs to the batch delete
      }

      // C. Batch delete all expired docs (CHATBOT activities + INITIAL status)
      if (toDelete.isNotEmpty) {
        final batch = db.batch();
        for (final ref in toDelete) batch.delete(ref);
        await batch.commit();
      }

      // 3. Merge the lists (CHATBOT items + INITIAL non-completed items)
      final combinedList = [...userItems, ...initialItems];

      if (combinedList.isNotEmpty) {
        yield combinedList;
      } else {
        // Fallback: Only switch to the fallback stream if the combined list is COMPLETELY empty
        yield* _initialsStream(uid); 
      }
    }
  }

  // Realtime fallback stream for INITIAL templates:
  Stream<List<Activitymodel>> _initialsStream(String uid) async* {
    final templates = await _loadInitialTemplates(uid); // based on points

    await for (final statusSnap
        in db.collection('users').doc(uid).collection('activityStatus').snapshots()) {
      final Map<String, Map<String, dynamic>> statusMap = {
        for (final d in statusSnap.docs) d.id: d.data(),
      };

      final items = <Activitymodel>[];
      for (final t in templates) {
        final status = statusMap[t.id];
        final bool checked = (status?['isChecked'] ?? false) as bool;
        
        items.add(
          t.copyWith(
            isInitial: true,
            isChecked: checked, 
          ),
        );
      }
      yield items;
    }
  }

  // Loads initial templates once, filtered by the user's points band.
  Future<List<Activitymodel>> _loadInitialTemplates(String uid) async {
    // 1. Get points
    final userDoc = await db.collection('users').doc(uid).get();
    final int totalPoints = userDoc.data()?['totalPoints'] ?? 0;

    // 2. Fetch all templates
    final tplSnap = await db.collection('initialActivities').get();
    final all = tplSnap.docs
        .map((doc) => Activitymodel.fromInitialTemplateDoc(doc))
        .toList();

    // 3. Filter by band (retains the original filtering logic)
    List<Activitymodel> filtered = [];
    if (totalPoints >= 5 && totalPoints <= 8) {
      filtered = all
          .where(
            (a) => ['Short Walk', 'Light Yoga', 'Small Art'].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 9 && totalPoints <= 12) {
      filtered = all
          .where(
            (a) => ['Short Run', 'Brain Games', 'Cooking'].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 13 && totalPoints <= 16) {
      filtered = all
          .where(
            (a) => ['Team Sports', 'Fun Exercises', 'Journaling'].contains(a.title.trim()),
          )
          .toList();
    } else if (totalPoints >= 17 && totalPoints <= 20) {
      filtered = all
          .where(
            (a) => ['Advanced Yoga', 'Large Puzzle', 'Gardening'].contains(a.title.trim()),
          )
          .toList();
    }

    return filtered.isNotEmpty ? filtered : all;
  }

  // Fetches initial activities (non-realtime): used for the initialItems list in activities$().
  Future<List<Activitymodel>> getinitialActivity({
    bool fallbackMode = false,
  }) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return [];

    // 1) Load Templates filtered by points
    final candidates = await _loadInitialTemplates(uid); 

    // 2) Merge with per-user status 
    final statusDocs = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus') 
        .get();

    final Map<String, Map<String, dynamic>> statusMap = {
      for (final d in statusDocs.docs) d.id: d.data(),
    };

    final result = <Activitymodel>[];

    for (final a in candidates) {
      final status = statusMap[a.id];
      final bool checked = (status?['isChecked'] ?? false) as bool;

      if (!fallbackMode) {
        // Normal Merging Mode: Hide completed initial activities
        if (checked) continue; 
        
        result.add(a.copyWith(isInitial: true, isChecked: false));
      } else {
        // Fallback Mode: Show ALL initials (used by _initialsStream)
        result.add(a.copyWith(isInitial: true, isChecked: checked));
      }
    }

    return result;
  }

  // Toggles completion for either INITIAL or CHATBOT items.
  Future<void> toggle(Activitymodel item) async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    final nextChecked = !item.isChecked;
    final now = DateTime.now();
    final expire = now.add(const Duration(hours: 24));

    if (item.isInitial) {
      // INITIAL template -> write per-user status with 24h expiry
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activityStatus')
          .doc(item.id);

      if (nextChecked) {
        await ref.set({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(expire), 
        }, SetOptions(merge: true));
      } else {
        // Uncheck: clear status and expiry fields
        await ref.set({
          'isChecked': false,
          'checkedAt': null,
          'expireAt': null,
        }, SetOptions(merge: true));
      }
    } else {
      // CHATBOT per-user doc → set a 24h expiry time
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('activities')
          .doc(item.id);

      if (nextChecked) {
        await ref.update({
          'isChecked': true,
          'checkedAt': Timestamp.fromDate(now),
          'expireAt': Timestamp.fromDate(expire), 
        });
      } else {
        await ref.update({
          'isChecked': false,
          'checkedAt': null,
          'expireAt': null,
        });
   }
}
}


  /// Calculates the number of activities completed in the last 24 hours.
  /// This count naturally works well with the 24-hour expiry logic.
  Future<int> getDailyCompletedCount() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return 0;

    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final yesterdayTimestamp = Timestamp.fromDate(yesterday);

    int count = 0;

    // 1. Check completed INITIAL activities (via activityStatus)
    
    final statusSnap = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .get();
    count += statusSnap.docs.length;

    // 2. Check completed CHATBOT activities
    final activitySnap = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .get();
    count += activitySnap.docs.length;

    return count;
  }

  /// Calculates the number of activities completed in the last 7 days.
  /// Relies on the 'checkedAt' field which must exist for completed items (before deletion).
  Future<int> getWeeklyCompletedCount() async {
    final uid = authController.currentUser?.uid;
    if (uid == null) return 0;

    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final lastWeekTimestamp = Timestamp.fromDate(lastWeek);

    int count = 0;

    // 1. Check completed INITIAL activities (via activityStatus)
    
    final statusSnap = await db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: lastWeekTimestamp)
        .get();
    count += statusSnap.docs.length;

    // 2. Check completed CHATBOT activities
    final activitySnap = await db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .where('isChecked', isEqualTo: true)
        .where('checkedAt', isGreaterThanOrEqualTo: lastWeekTimestamp)
        .get();
    count += activitySnap.docs.length;

    return count;
  }
}
