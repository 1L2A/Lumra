import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lumra_project/model/community/communityModel.dart';

class AdminPostsController extends GetxController {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  var allPosts = <Map<String, dynamic>>[].obs; // {post, collection, raw}
  var reportedPosts =
      <Map<String, dynamic>>[].obs; // فقط اللي isReported = true
  var isLoading = false.obs;

  StreamSubscription? _caregiverSub;
  StreamSubscription? _adhdSub;

  @override
  void onInit() {
    super.onInit();
    fetchAllPostsRealtime();
  }

  @override
  void onClose() {
    _caregiverSub?.cancel();
    _adhdSub?.cancel();
    super.onClose();
  }

  // -------------------------------------------------------
  //  Real-time listeners from BOTH collections
  // -------------------------------------------------------
  void fetchAllPostsRealtime() {
    isLoading.value = true;

    _caregiverSub = db.collection("CareGiverCommunityPosts").snapshots().listen(
      (snapshot) {
        _process(snapshot.docs, "CareGiverCommunityPosts");
      },
    );

    _adhdSub = db.collection("ADHDCommunityPosts").snapshots().listen((
      snapshot,
    ) {
      _process(snapshot.docs, "ADHDCommunityPosts");
      isLoading.value = false;
    });
  }

  void _process(List<QueryDocumentSnapshot> docs, String fromCollection) {
    List<Map<String, dynamic>> incoming = docs.map((doc) {
      return {
        "post": Post.fromFirestore(doc),
        "collection": fromCollection,
        "raw": doc.data(),
      };
    }).toList();

    allPosts.removeWhere((item) => item["collection"] == fromCollection);

    allPosts.addAll(incoming);

    allPosts.sort((a, b) {
      final p1 = a["post"] as Post;
      final p2 = b["post"] as Post;
      return p2.createdAt.compareTo(p1.createdAt);
    });

    reportedPosts.value = allPosts.where((item) {
      final raw = item["raw"] as Map<String, dynamic>;
      return raw["isReported"] == true;
    }).toList();
  }

  // -------------------------------------------------------
  //  Ignore → make isReported = false
  // -------------------------------------------------------
  Future<void> ignorePost(String postId, String collection) async {
    await db.collection(collection).doc(postId).update({"isReported": false});
  }

  Future<void> deleteSubcollection(
    String collection,
    String postId,
    String sub,
  ) async {
    final ref = db.collection(collection).doc(postId).collection(sub);

    final snapshots = await ref.get();

    for (var doc in snapshots.docs) {
      await ref.doc(doc.id).delete();
    }
  }

  // -------------------------------------------------------
  //  Delete permanently  +  update user deletedPostsCount
  // -------------------------------------------------------
  Future<void> deletePost(
    String postId,
    String collection,
    String userId,
  ) async {
    try {
      //await deleteSubcollection(collection, postId, "comments");
      await deleteSubcollection(collection, postId, "likes");

      await db.collection(collection).doc(postId).delete();

      final userRef = db.collection('users').doc(userId);

      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() as Map<String, dynamic>? ?? {};

        final int currentCount = data['deletedPostsCount'] == null
            ? 0
            : (data['deletedPostsCount'] is int
                  ? data['deletedPostsCount']
                  : int.tryParse(data['deletedPostsCount'].toString()) ?? 0);

        final int newCount = currentCount + 1;

        final updateData = <String, dynamic>{'deletedPostsCount': newCount};

        if (newCount >= 6 && (data['reachedSixAt'] == null)) {
          updateData['reachedSixAt'] = FieldValue.serverTimestamp();
        }

        transaction.set(userRef, updateData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error in deletePost: $e');
    }
  }
}
