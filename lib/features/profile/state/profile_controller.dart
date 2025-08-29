import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_models.dart';
import '../domain/profile_usecases.dart';
import 'profile_state.dart';

/// Controller for managing profile state
class ProfileController extends StateNotifier<ProfileState> {
  final ProfileUseCases _useCases;
  final String _userId;

  ProfileController({
    required ProfileUseCases useCases,
    required String userId,
  })  : _useCases = useCases,
        _userId = userId,
        super(const ProfileState());

  /// Load initial profile data
  Future<void> loadInitial() async {
    try {
      // Load profile
      final profile = await _useCases.loadProfile(_userId);
      state = state.copyWith(
        profile: AsyncValue.data(profile),
      );

      // Load initial tab content (Media by default)
      await _loadTabContent(ProfileTabs.media);
    } catch (error, stackTrace) {
      state = state.copyWith(
        profile: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    
    try {
      // Refresh profile
      final profile = await _useCases.refreshProfile(_userId);
      
      // Reset tab data and reload current tab
      state = state.copyWith(
        profile: AsyncValue.data(profile),
        media: const AsyncValue.loading(),
        comments: const AsyncValue.loading(),
        boosts: const AsyncValue.loading(),
        likes: const AsyncValue.loading(),
        hasMoreMedia: false,
        hasMoreComments: false,
        hasMoreBoosts: false,
        hasMoreLikes: false,
        mediaCursor: null,
        commentsCursor: null,
        boostsCursor: null,
        likesCursor: null,
        isRefreshing: false,
      );

      await _loadTabContent(state.selectedTabIndex);
    } catch (error, stackTrace) {
      state = state.copyWith(
        profile: AsyncValue.error(error, stackTrace),
        isRefreshing: false,
      );
    }
  }

  /// Switch to a different tab
  Future<void> switchTab(int tabIndex) async {
    if (tabIndex == state.selectedTabIndex) return;
    
    state = state.copyWith(selectedTabIndex: tabIndex);
    
    // Load content if not already loaded
    await _loadTabContent(tabIndex);
  }

  /// Load content for a specific tab
  Future<void> _loadTabContent(int tabIndex) async {
    switch (tabIndex) {
      case ProfileTabs.media:
        if (state.media.isLoading) await _loadMedia();
        break;
      case ProfileTabs.comments:
        if (state.comments.isLoading) await _loadComments();
        break;
      case ProfileTabs.boosts:
        if (state.boosts.isLoading) await _loadBoosts();
        break;
      case ProfileTabs.likes:
        if (state.likes.isLoading) await _loadLikes();
        break;
    }
  }

  /// Load media items
  Future<void> _loadMedia() async {
    try {
      final page = await _useCases.loadMediaPage(_userId);
      state = state.copyWith(
        media: AsyncValue.data(page.items),
        hasMoreMedia: page.hasMore,
        mediaCursor: page.nextCursor,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        media: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load comments
  Future<void> _loadComments() async {
    try {
      final page = await _useCases.loadCommentsPage(_userId);
      state = state.copyWith(
        comments: AsyncValue.data(page.items),
        hasMoreComments: page.hasMore,
        commentsCursor: page.nextCursor,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        comments: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load boosts
  Future<void> _loadBoosts() async {
    try {
      final page = await _useCases.loadBoostsPage(_userId);
      state = state.copyWith(
        boosts: AsyncValue.data(page.items),
        hasMoreBoosts: page.hasMore,
        boostsCursor: page.nextCursor,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        boosts: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load likes
  Future<void> _loadLikes() async {
    try {
      final page = await _useCases.loadLikesPage(_userId);
      state = state.copyWith(
        likes: AsyncValue.data(page.items),
        hasMoreLikes: page.hasMore,
        likesCursor: page.nextCursor,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        likes: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Load next page of media items
  Future<void> loadNextMediaPage() async {
    if (!state.hasMoreMedia || state.isLoadingMoreMedia) return;

    state = state.copyWith(isLoadingMoreMedia: true);

    try {
      final page = await _useCases.loadMediaPage(
        _userId,
        cursor: state.mediaCursor,
      );

      final currentMedia = state.media.maybeWhen(
        data: (items) => items,
        orElse: () => <MediaItem>[],
      );

      state = state.copyWith(
        media: AsyncValue.data([...currentMedia, ...page.items]),
        hasMoreMedia: page.hasMore,
        mediaCursor: page.nextCursor,
        isLoadingMoreMedia: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMoreMedia: false);
      // Don't update the media state on pagination errors
    }
  }

  /// Load next page of comments
  Future<void> loadNextCommentsPage() async {
    if (!state.hasMoreComments || state.isLoadingMoreComments) return;

    state = state.copyWith(isLoadingMoreComments: true);

    try {
      final page = await _useCases.loadCommentsPage(
        _userId,
        cursor: state.commentsCursor,
      );

      final currentComments = state.comments.maybeWhen(
        data: (items) => items,
        orElse: () => <CommentItem>[],
      );

      state = state.copyWith(
        comments: AsyncValue.data([...currentComments, ...page.items]),
        hasMoreComments: page.hasMore,
        commentsCursor: page.nextCursor,
        isLoadingMoreComments: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMoreComments: false);
    }
  }

  /// Load next page of boosts
  Future<void> loadNextBoostsPage() async {
    if (!state.hasMoreBoosts || state.isLoadingMoreBoosts) return;

    state = state.copyWith(isLoadingMoreBoosts: true);

    try {
      final page = await _useCases.loadBoostsPage(
        _userId,
        cursor: state.boostsCursor,
      );

      final currentBoosts = state.boosts.maybeWhen(
        data: (items) => items,
        orElse: () => <BoostItem>[],
      );

      state = state.copyWith(
        boosts: AsyncValue.data([...currentBoosts, ...page.items]),
        hasMoreBoosts: page.hasMore,
        boostsCursor: page.nextCursor,
        isLoadingMoreBoosts: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMoreBoosts: false);
    }
  }

  /// Load next page of likes
  Future<void> loadNextLikesPage() async {
    if (!state.hasMoreLikes || state.isLoadingMoreLikes) return;

    state = state.copyWith(isLoadingMoreLikes: true);

    try {
      final page = await _useCases.loadLikesPage(
        _userId,
        cursor: state.likesCursor,
      );

      final currentLikes = state.likes.maybeWhen(
        data: (items) => items,
        orElse: () => <MediaItem>[],
      );

      state = state.copyWith(
        likes: AsyncValue.data([...currentLikes, ...page.items]),
        hasMoreLikes: page.hasMore,
        likesCursor: page.nextCursor,
        isLoadingMoreLikes: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMoreLikes: false);
    }
  }

  /// Toggle follow state with optimistic updates
  Future<void> toggleFollow() async {
    final currentState = state.currentFollowState;
    if (currentState == FollowState.self || state.isTogglingFollow) return;

    // Optimistic update
    final optimisticState = currentState == FollowState.following
        ? FollowState.notFollowing
        : FollowState.following;

    state = state.copyWith(
      optimisticFollowState: optimisticState,
      isTogglingFollow: true,
    );

    try {
      final newFollowState = await _useCases.toggleFollow(_userId);
      
      // Update profile with actual state
      final currentProfile = state.profile.maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      );

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          followState: newFollowState,
        );
        state = state.copyWith(
          profile: AsyncValue.data(updatedProfile),
          optimisticFollowState: null,
          isTogglingFollow: false,
        );
      }
    } catch (error) {
      // Rollback optimistic update
      state = state.copyWith(
        optimisticFollowState: null,
        isTogglingFollow: false,
      );
      
      // Show error to user (this could be handled by the UI)
      debugPrint('Failed to toggle follow: $error');
    }
  }
}

/// Provider for profile controller
final profileControllerProvider = StateNotifierProvider.family<ProfileController, ProfileState, String>((ref, userId) {
  final controller = ProfileController(
    useCases: ref.watch(profileUseCasesProvider),
    userId: userId,
  );
  
  // Auto-load initial data after the provider is fully established
  Future.microtask(() => controller.loadInitial());
  
  return controller;
});
