import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart' as app;
import 'package:pixelodon/providers/service_providers.dart';

import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/tree_builder.dart';
import 'package:pixelodon/ui/post/reply_thread.dart';

/// Bridges the app TimelineService to the ThreadController interface used by the new UI.
class StatusThreadController implements ThreadController {
  final WidgetRef ref;
  final String domain;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  @override
  final ValueNotifier<List<ReplyNode>> nodes = ValueNotifier<List<ReplyNode>>([]);

  StatusThreadController({required this.ref, required this.domain});

  List<SocialPost> _flat = [];

  @override
  Future<void> loadInitial(String postId) async {
    final tl = ref.read(timelineServiceProvider);
    isLoading.value = true;
    try {
      final status = await tl.getStatus(domain, postId);
      final ctx = await tl.getStatusContext(domain, postId);
      final descendants = ctx['descendants'] ?? <app.Status>[];

      // Build replies-only tree (exclude the root status)
      final String rootId = status.id;
      final all = descendants.map((s) => _fromStatusModel(s, domain)).toList();
      final repliesOnly = all.where((p) => p.id != rootId).toList();

      _flat = repliesOnly;
      nodes.value = buildReplyTree(repliesOnly);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> loadMoreAfter() async {
    // Pagination via since_id/min_id is not currently used in detail context; noop
  }

  @override
  Future<void> loadMoreBefore() async {
    // Pagination via max_id is not currently used in detail context; noop
  }

  @override
  void onBoost(ReplyNode node) async {
    final tl = ref.read(timelineServiceProvider);
    try {
      await tl.reblogStatus(domain, node.post.id);
      node.post.counts.boosts += 1;
      nodes.notifyListeners();
    } catch (_) {/* ignore for now */}
  }

  @override
  void onFavourite(ReplyNode node) async {
    final tl = ref.read(timelineServiceProvider);
    try {
      await tl.favouriteStatus(domain, node.post.id);
      node.post.counts.favourites += 1;
      nodes.notifyListeners();
    } catch (_) {/* ignore for now */}
  }

  @override
  void onOpenReplies(ReplyNode node) {
    node.isCollapsed = !node.isCollapsed;
    nodes.notifyListeners();
  }

  @override
  void onProfileTap(Author author) {
    // Hook into app navigation if needed; left as a no-op for now
  }

  @override
  void onReply(ReplyNode node) {
    // Host app should present composer; here we just bump count to reflect UI
    node.post.counts.replies += 1;
    nodes.notifyListeners();
  }

  @override
  void onShare(ReplyNode node) {
    // Host app handles sharing; no-op here
  }

  // Map app Status model to unified SocialPost
  SocialPost _fromStatusModel(app.Status s, String domain) {
    final acct = s.account;
    final displayName = (acct?.displayName ?? '').trim().isNotEmpty
        ? (acct?.displayName ?? '')
        : (acct?.username ?? '');
    final handle = acct?.acct ?? (acct?.username ?? '');
    final host = _extractHostFromAcct(handle).isNotEmpty
        ? _extractHostFromAcct(handle)
        : (acct?.domain ?? domain);

    final media = s.mediaAttachments
        .map((m) => MediaThumb(
              previewUrl: m.previewUrl ?? m.url,
              type: m.type.name,
              alt: m.description,
            ))
        .toList();

    return SocialPost(
      id: s.id,
      author: Author(
        displayName: displayName,
        handle: handle,
        host: host,
        avatarUrl: (acct?.avatarStatic ?? acct?.avatar) ?? '',
        isVerified: false,
      ),
      createdAt: s.createdAt ?? DateTime.now(),
      htmlBody: s.content,
      contentWarning: (s.spoilerText?.trim().isEmpty ?? true) ? null : s.spoilerText,
      media: media,
      counts: Counts(
        replies: s.repliesCount,
        boosts: s.reblogsCount,
        favourites: s.favouritesCount,
      ),
      isEdited: s.editedAt != null,
      isSensitive: s.sensitive,
      canonicalUrl: s.url ?? '',
      inReplyToId: s.inReplyToId,
    );
  }

  String _extractHostFromAcct(String acct) {
    if (acct.contains('@')) {
      return acct.split('@').last;
    }
    return '';
  }
}
