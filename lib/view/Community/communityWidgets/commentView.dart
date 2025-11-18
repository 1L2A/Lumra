import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Community/PostController.dart';
import 'package:lumra_project/model/community/comments.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/text_theme.dart';

/// ----------------------
/// Reactive Comments List
/// ----------------------
class CommentsListView extends StatelessWidget {
  final PostControllerX controller = Get.find<PostControllerX>();
  final Function(Comment) onReport;
  final bool isShrinkWrap;
  final ScrollPhysics scrollPhysics;
  final String postId;

  CommentsListView({
    super.key,
    required this.onReport,
    required this.postId,
    this.isShrinkWrap = true,
    this.scrollPhysics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //Decide Which lisrt to display
      final comments = controller.commentsForPost(postId);
     
      // Handle empty state
      if (comments.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(
              // to make centerd
              top:  130 ,
            ),
            child: Image.asset(
              'assets/images/NoComments.png',
              width: 295,
              height: 295,
              fit: BoxFit.contain,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: comments.length,
        shrinkWrap: isShrinkWrap,
        separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
        itemBuilder: (context, index) => _commentCard(context,comments[index]),
      );
    });
  }
 
  Widget _commentCard(BuildContext context, Comment comment) {
    const double avatarSize = 30; // smaller profile photo

    return Container(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
        border: Border.all(color: BColors.secondry),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header: profile + username + report
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: BColors.secondry, width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/AvatarSimple.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: BSizes.sm),
                  Text(
                    comment.userName,
                    style: BTextTheme.lightTextTheme.labelLarge,
                  ),
                ],
              ),
              /// Report button
              IconButton(
                icon: const Icon(Icons.flag_outlined, size: BSizes.iconMd - 2),
                color: comment.isReported ? Colors.red : BColors.darkGrey,
                tooltip: 'Report comment', onPressed: () {  },
              ),
            ],
          ),

          const SizedBox(height: BSizes.sm),

          /// Comment content
          Padding(
            padding: const EdgeInsets.only(left: BSizes.sm),
            child: Text(
              comment.content,
              style: BTextTheme.lightTextTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: BSizes.md),

          /// Posted date
          Padding(
            padding: const EdgeInsets.only(left: BSizes.sm),
            child: Text(
              'Commented ${comment.createdAt.toDate().toLocal().toString().split(" ")[0]}',
              style: BTextTheme.lightTextTheme.labelMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: BColors.darkGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
