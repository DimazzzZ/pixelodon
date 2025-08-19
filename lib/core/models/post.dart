import 'package:freezed_annotation/freezed_annotation.dart';

import 'account.dart';
import 'media.dart';

part 'post.freezed.dart';
part 'post.g.dart';

enum PostKind { text, photo, album }

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String authorId,
    required DateTime createdAt,
    String? text,
    @Default(PostKind.text) PostKind kind,
    @Default(<Media>[]) List<Media> media,
    String? contentWarning,
    @Default(0) int replyCount,
    @Default(0) int reblogCount,
    @Default(0) int likeCount,
    @Default('public') String visibility,
    Map<String, dynamic>? raw,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

