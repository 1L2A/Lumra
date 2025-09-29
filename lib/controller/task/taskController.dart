import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/model/task/task.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskController({required this.userId});
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('tasks');
  //DONOT REMOVE THE COMMENTS
  // Hide expired tasks right away (TTL will delete them later) هو كذا طريقته مايتعامل بالثواني
  //we will cancel the TTL because google cloud doesn’t allow direct billing
  // Stream<List<Task>> getTasks() {
  //   return _col
  //       .where('expireAt', isGreaterThan: Timestamp.now()) // filter only
  //       .orderBy('order', descending: true) // single sort key
  //       .snapshots()
  //       .map((snap) => snap.docs.map(Task.fromFirestore).toList());
  // }
  // FREE REORDERING: sort by 'order' only; filter expired in memory.
  Stream<List<Task>> getTasks() {
    return _col.orderBy('order', descending: true).snapshots().map((snap) {
      final now = DateTime.now();
      final all = snap.docs.map(Task.fromFirestore).toList();

      return all.where((t) {
        final ts = t.expireAt; // may be null
        if (ts == null) return true; // keep if no expireAt (NEXT SPRINT)
        return ts.toDate().isAfter(now); // filter only when non null
      }).toList();
    });
  }

  Future<void> addTask(Task task) async {
    final data = task.toFirestore(useServerTimestamp: true);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['order'] = DateTime.now().microsecondsSinceEpoch; // higher = higher
    data['expireAt'] =
        (data['expireAt'] as Timestamp?) ??
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    await _col.add(data);
  }

  Future<void> reorderTasks(
    List<Task> tasks,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, moved);

    final batch = _firestore.batch();
    int base = DateTime.now().millisecondsSinceEpoch; // newest at top
    for (int i = 0; i < tasks.length; i++) {
      batch.update(_col.doc(tasks[i].id), {
        'order': base - i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  //DO NOT DELETEeeeeee!!!!
  // Stream<List<Task>> getTasks() {
  //   final col = _firestore.collection('users').doc(userId).collection('tasks');

  //   return col
  //       .where('expireAt', isGreaterThan: Timestamp.now())
  //       .snapshots()
  //       .map((snap) => snap.docs.map((d) => Task.fromFirestore(d)).toList());
  // }

  // Future<void> addTask(Task task) async {
  //   final col = _firestore.collection('users').doc(userId).collection('tasks');

  //   // Ensure every new task has expireAt = now + 24hours
  //   final data = task.toFirestore(useServerTimestamp: true);
  //   data['expireAt'] =
  //       (data['expireAt'] as Timestamp?) ??
  //       Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

  //   await col.add(data);
  // }

  /// When checked -> priority becomes 'done'.
  /// When unchecked -> priority becomes the doc's basePriority (previous priority).
  Future<void> updateTaskStatus(String taskId, bool isChecked) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);

    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>? ?? {};

    final currentPriority = (data['priority'] as String?) ?? 'low';
    final basePriority = (data['basePriority'] as String?) ?? currentPriority;
    final newPriority = isChecked ? 'done' : basePriority;

    await docRef.update({
      'isChecked': isChecked,
      'priority': newPriority,
      'basePriority': basePriority,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getTaskCount() async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();
    return snap.docs.length;
  }

  Future<int> getOpenTaskCount() async {
    //need it for next sprint
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('isChecked', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
  //ALSO FOR NEXT SPRINT

  Future<int> getActiveTaskCount() async {
    final nowTs = Timestamp.now();
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('expireAt', isGreaterThan: nowTs)
        .get();
    return snap.docs.length;
  }

  // if we want the cap to apply to open tasks only:
  Future<int> getOpenActiveTaskCount() async {
    final nowTs = Timestamp.now();
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('expireAt', isGreaterThan: nowTs)
        .where('isChecked', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
