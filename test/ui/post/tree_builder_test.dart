import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/tree_builder.dart';

void main() {
  group('buildReplyTree', () {
    SocialPost post(String id, {String? parent}) => SocialPost(
          id: id,
          author: Author(displayName: 'A $id', handle: 'a$id', host: 'ex.com', avatarUrl: '', isVerified: false),
          createdAt: DateTime.now(),
          htmlBody: '<p>Hi</p>',
          contentWarning: null,
          media: const [],
          counts: Counts(replies: 0, boosts: 0, favourites: 0),
          isEdited: false,
          isSensitive: false,
          canonicalUrl: 'https://ex.com/$id',
          inReplyToId: parent,
        );

    test('creates roots and children with proper depth', () {
      final flat = [
        post('1'),
        post('2', parent: '1'),
        post('3', parent: '1'),
        post('4', parent: '2'),
      ];
      final roots = buildReplyTree(flat);
      expect(roots.length, 1);
      expect(roots.first.post.id, '1');
      expect(roots.first.children.length, 2);
      expect(roots.first.children.first.depth, 1);
      expect(roots.first.children.first.children.first.depth, 2);
    });

    test('collapse/expand utilities', () {
      final flat = [post('1'), post('2', parent: '1'), post('3', parent: '2')];
      final roots = buildReplyTree(flat);
      final n1 = roots.first;
      expect(countDescendants(n1), 2);
      setCollapsedRecursive(n1, true);
      expect(n1.isCollapsed, true);
    });

    test('expandAncestors finds path', () {
      final flat = [post('1'), post('2', parent: '1'), post('3', parent: '2')];
      final roots = buildReplyTree(flat);
      roots.first.isCollapsed = true;
      final path = expandAncestors(roots, '3');
      expect(path.first.post.id, '1');
      expect(path.last.post.id, '3');
      expect(roots.first.isCollapsed, false);
    });
  });
}
