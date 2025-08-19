import 'package:freezed_annotation/freezed_annotation.dart';
import 'media.dart';

part 'story.freezed.dart';
part 'story.g.dart';

@freezed
class Story with _$Story {
  const factory Story({
    required String id,
    required String authorId,
    required Media media,
    required DateTime expiresAt,
    Map<String, dynamic>? raw,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
}

