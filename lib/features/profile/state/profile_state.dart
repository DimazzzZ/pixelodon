import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pixelodon/features/profile/data/profile_models.dart';

part 'profile_state.freezed.dart';

/// State for the profile screen
@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    // Profile data
    @Default(AsyncValue.loading()) AsyncValue<UserProfile> profile,
    
    // Tab content data
    @Default(AsyncValue.loading()) AsyncValue<List<MediaItem>> media,
    @Default(AsyncValue.loading()) AsyncValue<List<CommentItem>> comments,
    @Default(AsyncValue.loading()) AsyncValue<List<BoostItem>> boosts,
    @Default(AsyncValue.loading()) AsyncValue<List<MediaItem>> likes,
    
    // Pagination state
    @Default(false) bool hasMoreMedia,
    @Default(false) bool hasMoreComments,
    @Default(false) bool hasMoreBoosts,
    @Default(false) bool hasMoreLikes,
    String? mediaCursor,
    String? commentsCursor,
    String? boostsCursor,
    String? likesCursor,
    
    // Loading states for pagination
    @Default(false) bool isLoadingMoreMedia,
    @Default(false) bool isLoadingMoreComments,
    @Default(false) bool isLoadingMoreBoosts,
    @Default(false) bool isLoadingMoreLikes,
    
    // UI state
    @Default(0) int selectedTabIndex, // 0: Media, 1: Comments, 2: Boosts, 3: Likes
    @Default(false) bool isRefreshing,
    
    // Follow state for optimistic updates
    FollowState? optimisticFollowState,
    @Default(false) bool isTogglingFollow,
  }) = _ProfileState;

  const ProfileState._();

  /// Get the current follow state (optimistic or from profile)
  FollowState get currentFollowState {
    return optimisticFollowState ?? 
           profile.maybeWhen(
             data: (profile) => profile.followState,
             orElse: () => FollowState.unknown,
           );
  }

  /// Check if we're currently viewing our own profile
  bool get isOwnProfile {
    return profile.maybeWhen(
      data: (profile) => profile.isCurrentUser,
      orElse: () => false,
    );
  }

  /// Get the current tab's loading state
  bool get isCurrentTabLoading {
    switch (selectedTabIndex) {
      case 0:
        return media.isLoading;
      case 1:
        return comments.isLoading;
      case 2:
        return boosts.isLoading;
      case 3:
        return likes.isLoading;
      default:
        return false;
    }
  }

  /// Get the current tab's error state
  Object? get currentTabError {
    switch (selectedTabIndex) {
      case 0:
        return media.maybeWhen(error: (error, _) => error, orElse: () => null);
      case 1:
        return comments.maybeWhen(error: (error, _) => error, orElse: () => null);
      case 2:
        return boosts.maybeWhen(error: (error, _) => error, orElse: () => null);
      case 3:
        return likes.maybeWhen(error: (error, _) => error, orElse: () => null);
      default:
        return null;
    }
  }

  /// Check if current tab has more items to load
  bool get currentTabHasMore {
    switch (selectedTabIndex) {
      case 0:
        return hasMoreMedia;
      case 1:
        return hasMoreComments;
      case 2:
        return hasMoreBoosts;
      case 3:
        return hasMoreLikes;
      default:
        return false;
    }
  }

  /// Check if current tab is loading more items
  bool get isCurrentTabLoadingMore {
    switch (selectedTabIndex) {
      case 0:
        return isLoadingMoreMedia;
      case 1:
        return isLoadingMoreComments;
      case 2:
        return isLoadingMoreBoosts;
      case 3:
        return isLoadingMoreLikes;
      default:
        return false;
    }
  }
}

/// Tab indices for the profile tabs
class ProfileTabs {
  static const int media = 0;
  static const int comments = 1;
  static const int boosts = 2;
  static const int likes = 3;
  
  static const List<String> labels = ['Media', 'Comments', 'Boosts', 'Likes'];
}
