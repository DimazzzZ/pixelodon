import 'package:flutter/material.dart';

import 'platform_adaptive.dart';
import 'reply_node_tile.dart';
import 'tree_builder.dart';
import 'adapters_masto_pixelfed.dart';

abstract class ThreadController {
  Future<void> loadInitial(String postId);
  Future<void> loadMoreBefore();
  Future<void> loadMoreAfter();

  void onReply(ReplyNode node);
  void onBoost(ReplyNode node);
  void onFavourite(ReplyNode node);
  void onShare(ReplyNode node);
  void onOpenReplies(ReplyNode node);
  void onProfileTap(Author author);

  ValueNotifier<bool> get isLoading;
  ValueNotifier<List<ReplyNode>> get nodes; // Roots
}

class ReplyThread extends StatefulWidget {
  final ThreadController controller;
  final String postId;

  const ReplyThread({super.key, required this.controller, required this.postId});

  @override
  State<ReplyThread> createState() => _ReplyThreadState();
}

class _ReplyThreadState extends State<ReplyThread> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadInitial(widget.postId);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 100) {
      widget.controller.loadMoreBefore();
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      widget.controller.loadMoreAfter();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ReplyNode>>(
      valueListenable: widget.controller.nodes,
      builder: (context, roots, _) {
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final node = _flattenVisible(roots)[index];
                  return ReplyNodeTile(
                    node: node,
                    onReply: (n) => widget.controller.onReply(n),
                    onBoost: (n) => widget.controller.onBoost(n),
                    onFavourite: (n) => widget.controller.onFavourite(n),
                    onShare: (n) => widget.controller.onShare(n),
                    onOpenReplies: (n) => widget.controller.onOpenReplies(n),
                    onProfileTap: (a) => widget.controller.onProfileTap(a),
                  );
                },
                childCount: _flattenVisible(roots).length,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: widget.controller.isLoading,
              builder: (context, loading, _) => SliverToBoxAdapter(
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: AdaptiveActivityIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
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
}
