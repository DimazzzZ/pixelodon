import 'package:flutter/foundation.dart';

import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/tree_builder.dart';
import 'package:pixelodon/ui/post/reply_thread.dart';

/// A simple in-memory demo controller implementation
class InMemoryThreadController implements ThreadController {
  @override
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  @override
  final ValueNotifier<List<ReplyNode>> nodes = ValueNotifier<List<ReplyNode>>([]);

  final List<SocialPost> _flat = [];
  late String _rootId;

  InMemoryThreadController({List<SocialPost>? seed}) {
    if (seed != null) _flat.addAll(seed);
  }

  @override
  Future<void> loadInitial(String postId) async {
    _rootId = postId;
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    nodes.value = buildReplyTree(_flat);
    isLoading.value = false;
  }

  @override
  Future<void> loadMoreAfter() async {
    // Simulate noop for demo
  }

  @override
  Future<void> loadMoreBefore() async {
    // Simulate noop for demo
  }

  @override
  void onBoost(ReplyNode node) {
    node.post.counts.boosts += 1;
    nodes.notifyListeners();
  }

  @override
  void onFavourite(ReplyNode node) {
    node.post.counts.favourites += 1;
    nodes.notifyListeners();
  }

  @override
  void onOpenReplies(ReplyNode node) {
    node.isCollapsed = !node.isCollapsed;
    nodes.notifyListeners();
  }

  @override
  void onProfileTap(Author author) {
    // Host app should navigate; no-op here
  }

  @override
  void onReply(ReplyNode node) {
    node.post.counts.replies += 1;
    nodes.notifyListeners();
  }

  @override
  void onShare(ReplyNode node) {
    // Host app should share; no-op here
  }
}
