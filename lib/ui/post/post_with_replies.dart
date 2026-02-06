import 'package:flutter/material.dart';

import 'package:pixelodon/ui/post/platform_adaptive.dart';
import 'package:pixelodon/ui/post/reply_thread.dart';
import 'package:pixelodon/ui/post/post_card.dart';
import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';

/// Facade wrapper (API-compatible placeholder with common props)
/// Migration notes:
/// - oldProp: `statusId` -> newProp: `postId`
/// - old callback names should be mapped by the host to ThreadController
class PostWithReplies extends StatelessWidget {
  final SocialPost post;
  final String postId; // kept separate for pagination contexts
  final ThreadController controller;

  const PostWithReplies({super.key, required this.post, required this.postId, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      navBarTitle: const Text('Post'),
      body: Column(
        children: [
          PostCard(post: post),
          const Divider(height: 1),
          Expanded(child: ReplyThread(controller: controller, postId: postId)),
        ],
      ),
    );
  }
}
