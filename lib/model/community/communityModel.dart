import 'package:cloud_firestore/cloud_firestore.dart';


class Post {
  final String userId;
  final String userName;
  final String content;
  final bool isEdited;
  final bool isReported;
  final Timestamp createdAt;
  String id;

  Post({
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.isReported=false,
    this.isEdited=false,
    required this.id,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      isReported: data['isReported'] ?? false,
      isEdited: data['isEdited'] == true, 
      createdAt: data['createdAt'] ?? Timestamp.now(),
      id: doc.id,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt,
       if (isEdited) 'isEdited': true,   // ONLY included when true
    };
  }
}
