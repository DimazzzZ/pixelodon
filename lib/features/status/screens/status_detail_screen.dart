import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/core/network/api_service.dart' show NotFoundException;
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/ui/post/post_card.dart' as adaptive_post;
import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/reply_node_tile.dart';
import 'package:pixelodon/ui/post/tree_builder.dart';
import 'package:pixelodon/ui/post/platform_adaptive.dart';
import 'package:pixelodon/features/status/controllers/status_thread_controller.dart';

/// Screen that shows details for a single status (post) and its conversation
class StatusDetailScreen extends ConsumerStatefulWidget {
  final String statusId;

  const StatusDetailScreen({super.key, required this.statusId});

  @override
  ConsumerState<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends ConsumerState<StatusDetailScreen> {
  late Future<_LoadedStatus> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<_LoadedStatus> _load() async {
    final instance = ref.read(activeInstanceProvider);
    if (instance == null) {
      throw Exception('No active instance');
    }
    final tl = ref.read(timelineServiceProvider);

    Future<_LoadedStatus> fetchForDomain(String domain) async {
      final ctx = await tl.getStatusContext(domain, widget.statusId);
      final status = await tl.getStatus(domain, widget.statusId);
      final ancestors = ctx['ancestors'] ?? <Status>[];
      final descendants = ctx['descendants'] ?? <Status>[];
      return _LoadedStatus(
        domain: domain,
        status: status,
        ancestors: ancestors,
        descendants: descendants,
      );
    }

    // Try with the active instance first
    try {
      return await fetchForDomain(instance.domain);
    } on NotFoundException catch (_) {
      // If active instance is Pixelfed, try fallback to a Mastodon instance
      if (instance.isPixelfed) {
        final instances = ref.read(instancesProvider);
        String? mastodonDomain;
        for (final inst in instances) {
          if (!inst.isPixelfed) {
            mastodonDomain = inst.domain;
            break;
          }
        }
        if (mastodonDomain != null) {
          return await fetchForDomain(mastodonDomain);
        }
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      navBarTitle: const Text('Post'),
      body: FutureBuilder<_LoadedStatus>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AdaptiveActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load post',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loader = _load();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return _AdaptivePostWithReplies(data: data, statusId: widget.statusId);
        },
      ),
    );
  }
}

class _AdaptivePostWithReplies extends ConsumerStatefulWidget {
  final _LoadedStatus data;
  final String statusId;
  const _AdaptivePostWithReplies({required this.data, required this.statusId});

  @override
  ConsumerState<_AdaptivePostWithReplies> createState() => _AdaptivePostWithRepliesState();
}

class _AdaptivePostWithRepliesState extends ConsumerState<_AdaptivePostWithReplies> {
  late final StatusThreadController _ctrl;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = StatusThreadController(ref: ref, domain: widget.data.domain);
    _ctrl.loadInitial(widget.statusId);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 100) {
      _ctrl.loadMoreBefore();
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _ctrl.loadMoreAfter();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  SocialPost _map(Status s, String domain) {
    final acct = s.account;
    final displayName = (acct?.displayName ?? '').trim().isNotEmpty ? (acct?.displayName ?? '') : (acct?.username ?? '');
    final handle = acct?.acct ?? (acct?.username ?? '');
    final host = handle.contains('@') ? handle.split('@').last : (acct?.domain ?? domain);
    final media = s.mediaAttachments
        .map((m) => MediaThumb(previewUrl: m.previewUrl ?? m.url, type: m.type.name, alt: m.description))
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
      counts: Counts(replies: s.repliesCount, boosts: s.reblogsCount, favourites: s.favouritesCount),
      isEdited: s.editedAt != null,
      isSensitive: s.sensitive,
      canonicalUrl: s.url ?? '',
      inReplyToId: s.inReplyToId,
    );
  }

  List<ReplyNode> _flattenVisible(List<ReplyNode> roots) {
    final out = <ReplyNode>[];
    void dfs(ReplyNode n) {
      out.add(n);
      if (!n.isCollapsed) {
        for (final ch in n.children) {
          dfs(ch);
        }
      }
    }

    for (final r in roots) {
      dfs(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final post = _map(widget.data.status, widget.data.domain);

    return ValueListenableBuilder<List<ReplyNode>>(
      valueListenable: _ctrl.nodes,
      builder: (context, roots, _) {
        final flat = _flattenVisible(roots);
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: adaptive_post.PostCard(post: post),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final node = flat[index];
                  return ReplyNodeTile(
                    node: node,
                    onReply: (n) => _ctrl.onReply(n),
                    onBoost: (n) => _ctrl.onBoost(n),
                    onFavourite: (n) => _ctrl.onFavourite(n),
                    onShare: (n) => _ctrl.onShare(n),
                    onOpenReplies: (n) => _ctrl.onOpenReplies(n),
                    onProfileTap: (a) => _ctrl.onProfileTap(a),
                  );
                },
                childCount: flat.length,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _ctrl.isLoading,
              builder: (context, loading, __) => SliverToBoxAdapter(
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: AdaptiveActivityIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Safe bottom inset to prevent home indicator overlap
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.viewPaddingOf(context).bottom + 8,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadedStatus {
  final String domain;
  final Status status;
  final List<Status> ancestors;
  final List<Status> descendants;

  _LoadedStatus({
    required this.domain,
    required this.status,
    required this.ancestors,
    required this.descendants,
  });
}



