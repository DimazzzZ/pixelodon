import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/thread_controller_stub.dart';

void main() {
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

  test('Stub controller toggles collapse and updates counts', () async {
    final seed = [post('1'), post('2', parent: '1'), post('3', parent: '2')];
    final ctrl = InMemoryThreadController(seed: seed);
    await ctrl.loadInitial('1');
    final node = ctrl.nodes.value.first;
    expect(node.isCollapsed, isFalse);
    ctrl.onOpenReplies(node);
    expect(node.isCollapsed, isTrue);
    ctrl.onReply(node);
    expect(node.post.counts.replies, 1);
    ctrl.onBoost(node);
    expect(node.post.counts.boosts, 1);
  });
}
