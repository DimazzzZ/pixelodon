import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pixelodon/features/profile/data/profile_models.dart';
import 'package:pixelodon/features/profile/data/profile_sources.dart';

part 'profile_repository.g.dart';

/// Repository for profile-related operations
/// Coordinates between remote and local data sources
class ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepository({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Get user profile - tries cache first, then remote
  Future<UserProfile> getProfile(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedProfile = await _localDataSource.getCachedProfile(userId);
      if (cachedProfile != null) {
        return cachedProfile;
      }
    }

    try {
      final profile = await _remoteDataSource.getProfile(userId);
      await _localDataSource.cacheProfile(profile);
      return profile;
    } catch (e) {
      // If remote fails and we have cache, return cache
      final cachedProfile = await _localDataSource.getCachedProfile(userId);
      if (cachedProfile != null) {
        return cachedProfile;
      }
      rethrow;
    }
  }

  /// Get media items for a user with pagination
  Future<Page<MediaItem>> getMediaItems(
    String userId, {
    String? cursor,
  }) async {
    return await _remoteDataSource.getMediaItems(userId, cursor: cursor);
  }

  /// Get comments/replies for a user with pagination
  Future<Page<CommentItem>> getComments(
    String userId, {
    String? cursor,
  }) async {
    return await _remoteDataSource.getComments(userId, cursor: cursor);
  }

  /// Get boosts for a user with pagination
  Future<Page<BoostItem>> getBoosts(
    String userId, {
    String? cursor,
  }) async {
    return await _remoteDataSource.getBoosts(userId, cursor: cursor);
  }

  /// Get likes for a user with pagination
  Future<Page<MediaItem>> getLikes(
    String userId, {
    String? cursor,
  }) async {
    return await _remoteDataSource.getLikes(userId, cursor: cursor);
  }

  /// Toggle follow state for a user
  Future<FollowState> toggleFollow(String userId) async {
    try {
      final newFollowState = await _remoteDataSource.toggleFollow(userId);
      
      // Update cached profile with new follow state
      final cachedProfile = await _localDataSource.getCachedProfile(userId);
      if (cachedProfile != null) {
        final updatedProfile = cachedProfile.copyWith(followState: newFollowState);
        await _localDataSource.cacheProfile(updatedProfile);
      }
      
      return newFollowState;
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cache for a specific user
  Future<void> clearUserCache(String userId) async {
    await _localDataSource.clearCache(userId);
  }

  /// Refresh profile data from remote
  Future<UserProfile> refreshProfile(String userId) async {
    return await getProfile(userId, forceRefresh: true);
  }
}

/// Provider for profile repository
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
  );
}
