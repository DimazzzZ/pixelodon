import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/account.dart';
import '../../../models/status.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// Enum representing the follow state of a user
enum FollowState { 
  unknown, 
  self, 
  following, 
  notFollowing 
}

/// User profile data model extending the existing Account model
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    String? displayName,
    required String avatarUrl,
    required String coverUrl,
    required String bio,
    @Default([]) List<String> interests,
    @Default(0) int posts,
    @Default(0) int followers,
    @Default(0) int following,
    @Default(FollowState.unknown) FollowState followState,
    @Default(false) bool isCurrentUser,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Create UserProfile from existing Account model
  factory UserProfile.fromAccount(Account account, {
    bool isCurrentUser = false,
    String? currentUserId,
  }) {
    final followState = _getFollowState(account, isCurrentUser, currentUserId);
    
    return UserProfile(
      id: account.id,
      username: account.username,
      displayName: account.displayName.isEmpty ? null : account.displayName,
      avatarUrl: account.avatar ?? '',
      coverUrl: account.header ?? '',
      bio: account.note ?? '',
      interests: _extractInterests(account.fields),
      posts: account.statusesCount,
      followers: account.followersCount,
      following: account.followingCount,
      followState: followState,
      isCurrentUser: isCurrentUser,
    );
  }

  static FollowState _getFollowState(Account account, bool isCurrentUser, String? currentUserId) {
    if (isCurrentUser || account.id == currentUserId) {
      return FollowState.self;
    }
    if (account.following) {
      return FollowState.following;
    }
    return FollowState.notFollowing;
  }

  static List<String> _extractInterests(List<Field>? fields) {
    if (fields == null || fields.isEmpty) return [];
    
    // Look for interests in profile fields
    final interestsField = fields.firstWhere(
      (field) => field.name.toLowerCase().contains('interest') ||
                 field.name.toLowerCase().contains('hobby') ||
                 field.name.toLowerCase().contains('tag'),
      orElse: () => Field(name: '', value: ''),
    );
    
    if (interestsField.value.isEmpty) return [];
    
    // Split by common separators
    return interestsField.value
        .split(RegExp(r'[,•·|/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(5) // Limit to 5 interests
        .toList();
  }
}

/// Media item derived from Status media attachments
@freezed
class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required String previewUrl,
    String? alt,
    String? fullUrl,
    @Default('image') String type,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  /// Create MediaItem from Status with media attachments
  factory MediaItem.fromStatus(Status status) {
    if (status.mediaAttachments.isEmpty) {
      throw ArgumentError('Status has no media attachments');
    }
    
    final media = status.mediaAttachments.first;
    return MediaItem(
      id: status.id,
      previewUrl: media.previewUrl ?? media.url ?? '',
      alt: media.description,
      fullUrl: media.url,
      type: media.type.name,
    );
  }
}

/// Comment/reply item derived from Status replies
@freezed
class CommentItem with _$CommentItem {
  const factory CommentItem({
    required String id,
    required String author,
    required String authorAvatar,
    required String text,
    required DateTime createdAt,
    String? inReplyToId,
  }) = _CommentItem;

  factory CommentItem.fromJson(Map<String, dynamic> json) =>
      _$CommentItemFromJson(json);

  /// Create CommentItem from Status
  factory CommentItem.fromStatus(Status status) {
    return CommentItem(
      id: status.id,
      author: status.account?.username ?? 'unknown',
      authorAvatar: status.account?.avatar ?? '',
      text: status.content.replaceAll(RegExp(r'<[^>]*>'), ''), // Strip HTML
      createdAt: status.createdAt ?? DateTime.now(),
      inReplyToId: status.inReplyToId,
    );
  }
}

/// Boost/reblog item derived from boosted Status
@freezed
class BoostItem with _$BoostItem {
  const factory BoostItem({
    required String id,
    required String originalAuthor,
    required String originalAuthorAvatar,
    required String boosterUsername,
    required String text,
    String? previewUrl,
    required DateTime createdAt,
    required DateTime boostedAt,
  }) = _BoostItem;

  factory BoostItem.fromJson(Map<String, dynamic> json) =>
      _$BoostItemFromJson(json);

  /// Create BoostItem from boosted Status
  factory BoostItem.fromStatus(Status status) {
    final originalStatus = status.rebloggedStatus ?? status;
    final booster = status.account;
    final originalAuthor = originalStatus.account;
    
    return BoostItem(
      id: status.id,
      originalAuthor: originalAuthor?.username ?? 'unknown',
      originalAuthorAvatar: originalAuthor?.avatar ?? '',
      boosterUsername: booster?.username ?? 'unknown',
      text: originalStatus.content.replaceAll(RegExp(r'<[^>]*>'), ''), // Strip HTML
      previewUrl: originalStatus.mediaAttachments.isNotEmpty 
          ? originalStatus.mediaAttachments.first.previewUrl ?? originalStatus.mediaAttachments.first.url
          : null,
      createdAt: originalStatus.createdAt ?? DateTime.now(),
      boostedAt: status.createdAt ?? DateTime.now(),
    );
  }
}

/// Generic pagination wrapper
@freezed
class Page<T> with _$Page<T> {
  const factory Page({
    required List<T> items,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _Page<T>;

  // Note: Generic JSON serialization is handled manually in repository layer
}

/// Profile statistics
@freezed
class ProfileStats with _$ProfileStats {
  const factory ProfileStats({
    @Default(0) int posts,
    @Default(0) int followers,
    @Default(0) int following,
  }) = _ProfileStats;

  factory ProfileStats.fromJson(Map<String, dynamic> json) =>
      _$ProfileStatsFromJson(json);
}
