import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'account.dart';

part 'story.freezed.dart';
part 'story.g.dart';

/// Represents a story on Pixelfed
@freezed
class Story with _$Story {
  const factory Story({
    /// The ID of the story
    required String id,
    
    /// The account that posted the story
    required Account account,
    
    /// When the story was created
    required DateTime createdAt,
    
    /// When the story expires
    required DateTime expiresAt,
    
    /// The URL of the story media
    required String url,
    
    /// The preview URL of the story media
    String? previewUrl,
    
    /// The blurhash of the story media
    String? blurhash,
    
    /// The type of the story media
    required StoryMediaType mediaType,
    
    /// The width of the story media
    int? width,
    
    /// The height of the story media
    int? height,
    
    /// The duration of the story in seconds (for videos)
    double? duration,
    
    /// The text overlay on the story
    String? text,
    
    /// The font family of the text overlay
    String? fontFamily,
    
    /// The font size of the text overlay
    int? fontSize,
    
    /// The font color of the text overlay
    String? fontColor,
    
    /// The background color of the text overlay
    String? textBackgroundColor,
    
    /// The text alignment of the text overlay
    TextAlignment? textAlignment,
    
    /// The text position of the text overlay
    TextPosition? textPosition,
    
    /// The mentions in the story
    @Default([]) List<StoryMention> mentions,
    
    /// The hashtags in the story
    @Default([]) List<String> hashtags,
    
    /// The locations in the story
    @Default([]) List<StoryLocation> locations,
    
    /// The reactions to the story
    @Default([]) List<StoryReaction> reactions,
    
    /// Whether the story has been seen by the authenticated user
    @Default(false) bool seen,
    
    /// Whether the story can be replied to
    @Default(false) bool canReply,
    
    /// Whether the story can be reacted to
    @Default(false) bool canReact,
    
    /// The domain of the instance that posted the story
    String? domain,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
}

/// Type of story media
enum StoryMediaType {
  @JsonValue('image')
  image,
  
  @JsonValue('video')
  video,
  
  @JsonValue('unknown')
  unknown
}

/// Text alignment for story text
enum TextAlignment {
  @JsonValue('left')
  left,
  
  @JsonValue('center')
  center,
  
  @JsonValue('right')
  right
}

/// Text position for story text
enum TextPosition {
  @JsonValue('top')
  top,
  
  @JsonValue('middle')
  middle,
  
  @JsonValue('bottom')
  bottom
}

/// Represents a mention in a story
@freezed
class StoryMention with _$StoryMention {
  const factory StoryMention({
    /// The ID of the mentioned account
    required String id,
    
    /// The username of the mentioned account
    required String username,
    
    /// The display name of the mentioned account
    required String displayName,
    
    /// The URL of the mentioned account's avatar
    String? avatarUrl,
    
    /// The x position of the mention (0-100)
    @Default(50) double x,
    
    /// The y position of the mention (0-100)
    @Default(50) double y,
    
    /// The width of the mention (0-100)
    @Default(20) double width,
    
    /// The height of the mention (0-100)
    @Default(20) double height,
  }) = _StoryMention;

  factory StoryMention.fromJson(Map<String, dynamic> json) => _$StoryMentionFromJson(json);
}

/// Represents a location in a story
@freezed
class StoryLocation with _$StoryLocation {
  const factory StoryLocation({
    /// The ID of the location
    required String id,
    
    /// The name of the location
    required String name,
    
    /// The address of the location
    String? address,
    
    /// The latitude of the location
    double? latitude,
    
    /// The longitude of the location
    double? longitude,
    
    /// The x position of the location (0-100)
    @Default(50) double x,
    
    /// The y position of the location (0-100)
    @Default(50) double y,
    
    /// The width of the location (0-100)
    @Default(20) double width,
    
    /// The height of the location (0-100)
    @Default(20) double height,
  }) = _StoryLocation;

  factory StoryLocation.fromJson(Map<String, dynamic> json) => _$StoryLocationFromJson(json);
}

/// Represents a reaction to a story
@freezed
class StoryReaction with _$StoryReaction {
  const factory StoryReaction({
    /// The ID of the reaction
    required String id,
    
    /// The account that reacted
    required Account account,
    
    /// The emoji used for the reaction
    required String emoji,
    
    /// When the reaction was created
    required DateTime createdAt,
  }) = _StoryReaction;

  factory StoryReaction.fromJson(Map<String, dynamic> json) => _$StoryReactionFromJson(json);
}
