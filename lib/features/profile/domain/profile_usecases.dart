import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Use cases for profile-related operations
/// Contains business logic and orchestrates repository calls
abstract class ProfileUseCases {
  Future<UserProfile> loadProfile(String userId);
  Future<Page<MediaItem>> loadMediaPage(String userId, {String? cursor});
  Future<Page<CommentItem>> loadCommentsPage(String userId, {String? cursor});
  Future<Page<BoostItem>> loadBoostsPage(String userId, {String? cursor});
  Future<Page<MediaItem>> loadLikesPage(String userId, {String? cursor});
  Future<FollowState> toggleFollow(String userId);
  Future<UserProfile> refreshProfile(String userId);
}

/// Implementation of profile use cases
class ProfileUseCasesImpl implements ProfileUseCases {
  final ProfileRepository _repository;

  ProfileUseCasesImpl({required ProfileRepository repository})
      : _repository = repository;

  @override
  Future<UserProfile> loadProfile(String userId) async {
    try {
      return await _repository.getProfile(userId);
    } catch (e) {
      // Log error and rethrow
      // In a real app, you might want to transform exceptions here
      throw ProfileException('Failed to load profile: $e');
    }
  }

  @override
  Future<Page<MediaItem>> loadMediaPage(String userId, {String? cursor}) async {
    try {
      return await _repository.getMediaItems(userId, cursor: cursor);
    } catch (e) {
      throw ProfileException('Failed to load media: $e');
    }
  }

  @override
  Future<Page<CommentItem>> loadCommentsPage(String userId, {String? cursor}) async {
    try {
      return await _repository.getComments(userId, cursor: cursor);
    } catch (e) {
      throw ProfileException('Failed to load comments: $e');
    }
  }

  @override
  Future<Page<BoostItem>> loadBoostsPage(String userId, {String? cursor}) async {
    try {
      return await _repository.getBoosts(userId, cursor: cursor);
    } catch (e) {
      throw ProfileException('Failed to load boosts: $e');
    }
  }

  @override
  Future<Page<MediaItem>> loadLikesPage(String userId, {String? cursor}) async {
    try {
      return await _repository.getLikes(userId, cursor: cursor);
    } catch (e) {
      throw ProfileException('Failed to load likes: $e');
    }
  }

  @override
  Future<FollowState> toggleFollow(String userId) async {
    try {
      final newState = await _repository.toggleFollow(userId);
      return newState;
    } catch (e) {
      throw ProfileException('Failed to toggle follow: $e');
    }
  }

  @override
  Future<UserProfile> refreshProfile(String userId) async {
    try {
      return await _repository.refreshProfile(userId);
    } catch (e) {
      throw ProfileException('Failed to refresh profile: $e');
    }
  }
}

/// Custom exception for profile-related operations
class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';
}

/// Provider for profile use cases
final profileUseCasesProvider = Provider<ProfileUseCases>((ref) {
  return ProfileUseCasesImpl(
    repository: ref.watch(profileRepositoryProvider),
  );
});

/// Route arguments for profile screen
class ProfileRouteArgs {
  final String userId;
  final String? username;

  const ProfileRouteArgs({
    required this.userId,
    this.username,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileRouteArgs &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username;

  @override
  int get hashCode => userId.hashCode ^ username.hashCode;
}
