import 'package:freezed_annotation/freezed_annotation.dart';
import 'account.dart';

part 'status.freezed.dart';
part 'status.g.dart';

/// Represents a post (status) on Mastodon or Pixelfed
@freezed
class Status with _$Status {
  const factory Status({
    /// The ID of the status
    @Default('') String id,
    
    /// The URI of the status
    @Default('') String uri,
    
    /// When the status was created
    @JsonKey(name: 'created_at') DateTime? createdAt,
    
    /// The account that authored the status
    Account? account,
    
    /// The content of the status (HTML)
    @Default('') String content,
    
    /// The visibility of the status (public, unlisted, private, direct)
    @Default(Visibility.public) Visibility visibility,
    
    /// Whether the status is a reply
    @Default(false) bool isReply,
    
    /// Whether the status is a reblog/boost
    @Default(false) bool isReblog,
    
    /// Whether the status is a quote
    @Default(false) bool isQuote,
    
    /// The status being replied to
    Status? inReplyToStatus,
    
    /// The ID of the status being replied to
    @JsonKey(name: 'in_reply_to_id') String? inReplyToId,
    
    /// The ID of the account being replied to
    @JsonKey(name: 'in_reply_to_account_id') String? inReplyToAccountId,
    
    /// The status being reblogged/boosted
    @JsonKey(name: 'reblog') Status? rebloggedStatus,
    
    /// The status being quoted
    Status? quotedStatus,
    
    /// The application used to post the status
    Application? application,
    
    /// The media attachments for the status
    @JsonKey(name: 'media_attachments') @Default([]) List<MediaAttachment> mediaAttachments,
    
    /// The mentions of users in the status
    @Default([]) List<Mention> mentions,
    
    /// The hashtags used in the status
    @JsonKey(fromJson: _tagsFromJson) @Default([]) List<String> tags,
    
    /// The emojis used in the status
    @Default([]) List<Emoji> emojis,
    
    /// The number of reblogs/boosts for the status
    @JsonKey(name: 'reblogs_count') @Default(0) int reblogsCount,
    
    /// The number of favourites/likes for the status
    @JsonKey(name: 'favourites_count') @Default(0) int favouritesCount,
    
    /// The number of replies for the status
    @JsonKey(name: 'replies_count') @Default(0) int repliesCount,
    
    /// URL to the status
    String? url,
    
    /// Whether the authenticated user has reblogged/boosted the status
    @Default(false) bool reblogged,
    
    /// Whether the authenticated user has favourited/liked the status
    @Default(false) bool favourited,
    
    /// Whether the authenticated user has bookmarked the status
    @Default(false) bool bookmarked,
    
    /// Whether the authenticated user has muted the conversation
    @Default(false) bool muted,
    
    /// Whether the authenticated user has pinned the status
    @Default(false) bool pinned,
    
    /// Content warning for the status
    @JsonKey(name: 'spoiler_text') String? spoilerText,
    
    /// Whether the media attachments should be hidden by default
    @Default(false) bool sensitive,
    
    /// The language of the status
    String? language,
    
    /// Text for filtering statuses
    String? text,
    
    /// Whether the status is from a Pixelfed instance
    @Default(false) bool isPixelfed,
    
    /// The poll attached to the status
    Poll? poll,
    
    /// The card for the status (link preview)
    Card? card,
    
    /// When the status was last edited
    DateTime? editedAt,
  }) = _Status;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
}

/// Helper function to parse tags from JSON, filtering out null values
List<String> _tagsFromJson(dynamic json) {
  if (json == null) return [];
  if (json is List) {
    return json
        .where((tag) => tag != null && tag is String)
        .cast<String>()
        .toList();
  }
  return [];
}

/// Visibility of a status
enum Visibility {
  @JsonValue('public')
  public,
  
  @JsonValue('unlisted')
  unlisted,
  
  @JsonValue('private')
  private,
  
  @JsonValue('direct')
  direct
}

/// Represents a media attachment on a status
@freezed
class MediaAttachment with _$MediaAttachment {
  const factory MediaAttachment({
    /// The ID of the attachment
    required String id,
    
    /// The type of the attachment
    @JsonKey(unknownEnumValue: AttachmentType.unknown) required AttachmentType type,
    
    /// The URL of the attachment
    required String url,
    
    /// The preview URL of the attachment
    String? previewUrl,
    
    /// The remote URL of the attachment
    String? remoteUrl,
    
    /// The text description of the attachment
    String? description,
    
    /// The blurhash of the attachment
    String? blurhash,
    
    /// The width of the attachment
    int? width,
    
    /// The height of the attachment
    int? height,
    
    /// The size of the attachment in bytes
    int? size,
    
    /// The duration of the attachment in seconds (for videos/audio)
    double? duration,
    
    /// The focal point of the attachment (for images)
    List<double>? focalPoint,
    
    /// EXIF metadata for the attachment (Pixelfed-specific)
    Map<String, dynamic>? meta,
  }) = _MediaAttachment;

  factory MediaAttachment.fromJson(Map<String, dynamic> json) => _$MediaAttachmentFromJson(json);
}

/// Type of media attachment
enum AttachmentType {
  @JsonValue('image')
  image,
  
  @JsonValue('video')
  video,
  
  @JsonValue('gifv')
  gifv,
  
  @JsonValue('audio')
  audio,
  
  @JsonValue('unknown')
  unknown
}

/// Represents a mention of a user in a status
@freezed
class Mention with _$Mention {
  const factory Mention({
    /// The ID of the mentioned user
    required String id,
    
    /// The username of the mentioned user
    required String username,
    
    /// The account name of the mentioned user
    required String acct,
    
    /// The URL of the mentioned user's profile
    required String url,
  }) = _Mention;

  factory Mention.fromJson(Map<String, dynamic> json) => _$MentionFromJson(json);
}

/// Represents a custom emoji
@freezed
class Emoji with _$Emoji {
  const factory Emoji({
    /// The shortcode of the emoji
    required String shortcode,
    
    /// The URL of the emoji
    required String url,
    
    /// The URL of the emoji for static rendering
    String? staticUrl,
    
    /// Whether the emoji is visible in picker
    @Default(true) bool visibleInPicker,
    
    /// The category of the emoji
    String? category,
  }) = _Emoji;

  factory Emoji.fromJson(Map<String, dynamic> json) => _$EmojiFromJson(json);
}

/// Represents the application that posted a status
@freezed
class Application with _$Application {
  const factory Application({
    /// The name of the application
    required String name,
    
    /// The website of the application
    String? website,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);
}

/// Represents a poll attached to a status
@freezed
class Poll with _$Poll {
  const factory Poll({
    /// The ID of the poll
    required String id,
    
    /// When the poll expires
    DateTime? expiresAt,
    
    /// Whether the poll has expired
    @Default(false) bool expired,
    
    /// Whether multiple choices are allowed
    @Default(false) bool multiple,
    
    /// The number of votes in the poll
    @Default(0) int votesCount,
    
    /// The number of voters in the poll
    @Default(0) int votersCount,
    
    /// Whether the authenticated user has voted
    @Default(false) bool voted,
    
    /// The authenticated user's vote choices
    List<int>? ownVotes,
    
    /// The options for the poll
    required List<PollOption> options,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}

/// Represents an option in a poll
@freezed
class PollOption with _$PollOption {
  const factory PollOption({
    /// The title of the option
    required String title,
    
    /// The number of votes for the option
    @Default(0) int votesCount,
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);
}

/// Represents a card (link preview) for a status
@freezed
class Card with _$Card {
  const factory Card({
    /// The URL of the card
    required String url,
    
    /// The title of the card
    required String title,
    
    /// The description of the card
    required String description,
    
    /// The type of the card
    required CardType type,
    
    /// The author name of the card
    String? authorName,
    
    /// The author URL of the card
    String? authorUrl,
    
    /// The provider name of the card
    String? providerName,
    
    /// The provider URL of the card
    String? providerUrl,
    
    /// The HTML for the card
    String? html,
    
    /// The width of the card
    int? width,
    
    /// The height of the card
    int? height,
    
    /// The image URL of the card
    String? image,
    
    /// The embed URL of the card
    String? embedUrl,
    
    /// The blurhash of the card image
    String? blurhash,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
}

/// Type of card
enum CardType {
  @JsonValue('link')
  link,
  
  @JsonValue('photo')
  photo,
  
  @JsonValue('video')
  video,
  
  @JsonValue('rich')
  rich
}
