import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/model/Homepage/Reminders/reminderModel.dart';

class ReminderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUid;

  ReminderController({required this.currentUid});

  /// Stream of upcoming reminders for real-time updates.
  /// Firestore listener combined with a 1-minute tick ensures items
  /// disappear exactly when they end, even without writes.
  Stream<List<ReminderModel>> get upcomingRemindersStream {
    final StreamController<List<ReminderModel>> controller =
        StreamController<List<ReminderModel>>.broadcast();

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;
    Timer? tickTimer;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> latestDocs = const [];

    void emitFilteredNow() {
      final DateTime now = DateTime.now();
      final DateTime next24Hours = now.add(const Duration(hours: 24));

      final List<ReminderModel> reminders =
          latestDocs
              .map((doc) {
                try {
                  return ReminderModel.fromFirestore(doc);
                } catch (_) {
                  return null;
                }
              })
              .where((r) => r != null)
              .cast<ReminderModel>()
              .where((r) => r.end.isAfter(now) || r.end.isAtSameMomentAs(now))
              .where((r) => r.start.isBefore(next24Hours))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));

      if (!controller.isClosed) {
        controller.add(reminders);
      }
    }

    controller.onListen = () {
      firestoreSub = _firestore
          .collection('events')
          .where('participants', arrayContains: currentUid)
          .snapshots()
          .listen(
            (snapshot) {
              latestDocs = snapshot.docs;
              emitFilteredNow();
            },
            onError: (error, stack) {
              if (!controller.isClosed) {
                controller.addError(error, stack);
              }
            },
          );

      tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        emitFilteredNow();
      });

      emitFilteredNow();
    };

    controller.onCancel = () async {
      await firestoreSub?.cancel();
      tickTimer?.cancel();
      await controller.close();
    };

    return controller.stream;
  }
}
