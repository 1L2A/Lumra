import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String text;
  final String userId;
  final Timestamp createdAt;
  final bool isReported;
  String? id; //Firestore doc id

  Comment({
    required this.text,
    required this.userId,
    required this.createdAt,
    required this.isReported,
    this.id,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      id: doc.id,
      isReported: data['isReported'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'userId': userId,
      'createdAt': createdAt,
      'isReported': isReported,
    };
  }
}
