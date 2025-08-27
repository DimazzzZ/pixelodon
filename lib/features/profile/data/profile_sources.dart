import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/account.dart';
import '../../../models/status.dart';
import '../../../services/account_service.dart';
import '../../../services/timeline_service.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/auth_provider.dart';
import 'profile_models.dart';

/// Remote data source for profile-related data
abstract class ProfileRemoteDataSource {
  Future<UserProfile> getProfile(String userId);
  Future<Page<MediaItem>> getMediaItems(String userId, {String? cursor});
  Future<Page<CommentItem>> getComments(String userId, {String? cursor});
  Future<Page<BoostItem>> getBoosts(String userId, {String? cursor});
  Future<FollowState> toggleFollow(String userId);
}

/// Local data source for caching profile data
abstract class ProfileLocalDataSource {
  Future<UserProfile?> getCachedProfile(String userId);
  Future<void> cacheProfile(UserProfile profile);
  Future<void> clearCache(String userId);
}

/// Implementation of remote data source using real API services
class RealProfileRemoteDataSource implements ProfileRemoteDataSource {
  final AccountService _accountService;
  final TimelineService _timelineService;
  final String _domain;
  final String? _currentUserId;

  RealProfileRemoteDataSource({
    required AccountService accountService,
    required TimelineService timelineService,
    required String domain,
    String? currentUserId,
  })  : _accountService = accountService,
        _timelineService = timelineService,
        _domain = domain,
        _currentUserId = currentUserId;

  @override
  Future<UserProfile> getProfile(String userId) async {
    try {
      final account = await _accountService.getAccount(_domain, userId);
      final isCurrentUser = _currentUserId != null && _currentUserId == userId;
      
      return UserProfile.fromAccount(
        account,
        isCurrentUser: isCurrentUser,
        currentUserId: _currentUserId,
      );
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  @override
  Future<Page<MediaItem>> getMediaItems(String userId, {String? cursor}) async {
    try {
      final statuses = await _timelineService.getAccountStatuses(
        _domain,
        userId,
        maxId: cursor,
        limit: 20,
        onlyMedia: true,
        excludeReplies: true,
        excludeReblogs: true,
      );

      final mediaItems = statuses
          .where((status) => status.mediaAttachments.isNotEmpty)
          .map((status) => MediaItem.fromStatus(status))
          .toList();

      final nextCursor = statuses.isNotEmpty ? statuses.last.id : null;
      final hasMore = statuses.length == 20; // If we got a full page, there might be more

      return Page(
        items: mediaItems,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to fetch media items: $e');
    }
  }

  @override
  Future<Page<CommentItem>> getComments(String userId, {String? cursor}) async {
    try {
      // Fetch replies (statuses that are replies to other posts)
      final statuses = await _timelineService.getAccountStatuses(
        _domain,
        userId,
        maxId: cursor,
        limit: 20,
        excludeReblogs: true,
        // Don't exclude replies for comments tab
      );

      // Filter only replies
      final replies = statuses.where((status) => status.inReplyToId != null);
      final commentItems = replies.map((status) => CommentItem.fromStatus(status)).toList();

      final nextCursor = statuses.isNotEmpty ? statuses.last.id : null;
      final hasMore = statuses.length == 20;

      return Page(
        items: commentItems,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Future<Page<BoostItem>> getBoosts(String userId, {String? cursor}) async {
    try {
      // Fetch boosts/reblogs
      final statuses = await _timelineService.getAccountStatuses(
        _domain,
        userId,
        maxId: cursor,
        limit: 20,
        excludeReplies: true,
        // Don't exclude reblogs for boosts tab
      );

      // Filter only boosts/reblogs
      final boosts = statuses.where((status) => status.rebloggedStatus != null || status.isReblog);
      final boostItems = boosts.map((status) => BoostItem.fromStatus(status)).toList();

      final nextCursor = statuses.isNotEmpty ? statuses.last.id : null;
      final hasMore = statuses.length == 20;

      return Page(
        items: boostItems,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to fetch boosts: $e');
    }
  }

  @override
  Future<FollowState> toggleFollow(String userId) async {
    try {
      final account = await _accountService.getAccount(_domain, userId);
      
      if (account.following) {
        await _accountService.unfollowAccount(_domain, userId);
        return FollowState.notFollowing;
      } else {
        await _accountService.followAccount(_domain, userId);
        return FollowState.following;
      }
    } catch (e) {
      throw Exception('Failed to toggle follow: $e');
    }
  }
}

/// Implementation of local data source using simple in-memory cache
class InMemoryProfileLocalDataSource implements ProfileLocalDataSource {
  final Map<String, UserProfile> _cache = {};

  @override
  Future<UserProfile?> getCachedProfile(String userId) async {
    return _cache[userId];
  }

  @override
  Future<void> cacheProfile(UserProfile profile) async {
    _cache[profile.id] = profile;
  }

  @override
  Future<void> clearCache(String userId) async {
    _cache.remove(userId);
  }
}

/// Providers for data sources
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final accountService = ref.watch(accountServiceProvider);
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  final activeAccount = ref.watch(activeAccountProvider);
  
  return RealProfileRemoteDataSource(
    accountService: accountService,
    timelineService: timelineService,
    domain: activeInstance?.domain ?? 'mastodon.social',
    currentUserId: activeAccount?.id,
  );
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return InMemoryProfileLocalDataSource();
});
