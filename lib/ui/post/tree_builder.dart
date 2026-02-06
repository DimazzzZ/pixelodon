import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';

class ReplyNode {
  SocialPost post;
  List<ReplyNode> children;
  int depth;
  bool isCollapsed;
  ReplyNode({required this.post, this.children = const [], this.depth = 0, this.isCollapsed = false});

  ReplyNode copyWith({List<ReplyNode>? children, int? depth, bool? isCollapsed}) {
    return ReplyNode(
      post: post,
      children: children ?? this.children,
      depth: depth ?? this.depth,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}

List<ReplyNode> buildReplyTree(List<SocialPost> flat) {
  final byId = {for (final p in flat) p.id: ReplyNode(post: p, children: [], depth: 0)};
  final roots = <ReplyNode>[];
  for (final p in flat) {
    final node = byId[p.id]!;
    final parentId = p.inReplyToId;
    if (parentId != null && byId.containsKey(parentId)) {
      final parent = byId[parentId]!;
      node.depth = parent.depth + 1;
      parent.children.add(node);
    } else {
      roots.add(node);
    }
  }
  return roots;
}

/// Utilities for collapsing and expanding subtrees
int countDescendants(ReplyNode n) {
  int c = n.children.length;
  for (final ch in n.children) {
    c += countDescendants(ch);
  }
  return c;
}

void setCollapsedRecursive(ReplyNode node, bool collapsed) {
  node.isCollapsed = collapsed;
}

/// Expand ancestors of target id and return list of nodes along the path
List<ReplyNode> expandAncestors(List<ReplyNode> roots, String targetId) {
  List<ReplyNode> path = [];
  bool dfs(ReplyNode n) {
    if (n.post.id == targetId) {
      path.add(n);
      return true;
    }
    for (final ch in n.children) {
      if (dfs(ch)) {
        n.isCollapsed = false;
        path.add(n);
        return true;
      }
    }
    return false;
  }

  for (final r in roots) {
    if (dfs(r)) break;
  }
  return path.reversed.toList();
}
