import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String tasksTitle;
  final String priority; // Values: 'low' | 'medium' | 'high' | 'done'
  final String basePriority;
  // The original priority chosen when the task was created.
  // We keep it so if the user unchecks a task, we can restore it.
  final bool isChecked;
  final Timestamp updatedAt;

  Task({
    required this.id,
    required this.tasksTitle,
    required this.priority,
    required this.basePriority,
    required this.isChecked,
    required this.updatedAt,
  });

  factory Task.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final p = (data['priority'] as String?) ?? 'low';
    final bp = (data['basePriority'] as String?) ?? p; //  old docs
    return Task(
      id: doc.id,
      tasksTitle: (data['tasksTitle'] as String?) ?? '',
      priority: p,
      basePriority: bp,
      isChecked: (data['isChecked'] as bool?) ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'tasksTitle': tasksTitle,
      'priority': priority,
      'basePriority': basePriority,
      'isChecked': isChecked,
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : updatedAt,
    };
  }
}
