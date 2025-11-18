import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String content;
  final String userId;
  final String userName;
  final Timestamp createdAt;
  final bool isReported;
  String? id; //Firestore doc id

  Comment({
    required this.content,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.isReported = false,
    this.id,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      content: data['content'] ?? '',
      userName: data['userName'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      id: doc.id,
      isReported: data['isReported'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return { 
      'userName': userName,
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'isReported': isReported,
    };
  }
}
