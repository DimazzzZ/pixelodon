import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/profile_usecases.dart';
import '../../state/profile_controller.dart';
import '../../state/profile_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_tabbar.dart';
import '../widgets/media_grid_sliver.dart';
import '../widgets/comments_list_sliver.dart';
import '../widgets/boosts_list_sliver.dart';
import '../widgets/likes_grid_sliver.dart';
import '../widgets/shimmer_placeholders.dart';

/// Main profile screen with image-first design
class ProfileScreen extends ConsumerStatefulWidget {
  final ProfileRouteArgs args;

  const ProfileScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = widget.args.userId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider(userId));
    final controller = ref.read(profileControllerProvider(userId).notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Profile Header with cover image and avatar
            SliverProfileHeader(
              profile: state.profile.valueOrNull,
              isLoading: state.profile.isLoading,
              onFollowToggle: () => controller.toggleFollow(),
              onEditProfile: () => _handleEditProfile(),
            ),

            // Profile Stats Row
            SliverProfileStatsRow(
              profile: state.profile.valueOrNull,
              isLoading: state.profile.isLoading,
              onPostsTap: () => _handleStatsTap('posts'),
              onFollowersTap: () => _handleStatsTap('followers'),
              onFollowingTap: () => _handleStatsTap('following'),
            ),

            // Pinned Tab Bar
            SliverProfileTabBar(
              selectedIndex: state.selectedTabIndex,
              onTabChanged: (index) => controller.switchTab(index),
              isLoading: state.isCurrentTabLoading,
              isOwnProfile: state.isOwnProfile,
            ),

            // Tab Content
            ..._buildTabContent(state, controller),
          ],
        ),
      ),
    );
  }

  /// Build the content for the selected tab
  List<Widget> _buildTabContent(ProfileState state, ProfileController controller) {
    switch (state.selectedTabIndex) {
      case ProfileTabs.media:
        return [
          state.media.when(
            data: (items) => MediaGridSliver(
              items: items,
              hasMore: state.hasMoreMedia,
              isLoadingMore: state.isLoadingMoreMedia,
              onLoadMore: () => controller.loadNextMediaPage(),
              onItemTap: (item, index) => _handleMediaTap(item, index),
            ),
            loading: () => const MediaGridShimmer(),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(
                context,
                'Failed to load media',
                error.toString(),
                () => controller.switchTab(ProfileTabs.media),
              ),
            ),
          ),
        ];

      case ProfileTabs.comments:
        return [
          state.comments.when(
            data: (items) => CommentsListSliver(
              items: items,
              hasMore: state.hasMoreComments,
              isLoadingMore: state.isLoadingMoreComments,
              onLoadMore: () => controller.loadNextCommentsPage(),
              onItemTap: (item) => _handleCommentTap(item),
            ),
            loading: () => const ListShimmer(),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(
                context,
                'Failed to load comments',
                error.toString(),
                () => controller.switchTab(ProfileTabs.comments),
              ),
            ),
          ),
        ];

      case ProfileTabs.boosts:
        return [
          state.boosts.when(
            data: (items) => BoostsListSliver(
              items: items,
              hasMore: state.hasMoreBoosts,
              isLoadingMore: state.isLoadingMoreBoosts,
              onLoadMore: () => controller.loadNextBoostsPage(),
              onItemTap: (item) => _handleBoostTap(item),
            ),
            loading: () => const ListShimmer(),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(
                context,
                'Failed to load boosts',
                error.toString(),
                () => controller.switchTab(ProfileTabs.boosts),
              ),
            ),
          ),
        ];

      case ProfileTabs.likes:
        return [
          state.likes.when(
            data: (items) => LikesGridSliver(
              items: items,
              hasMore: state.hasMoreLikes,
              isLoadingMore: state.isLoadingMoreLikes,
              onLoadMore: () => controller.loadNextLikesPage(),
              onItemTap: (item, index) => _handleMediaTap(item, index),
            ),
            loading: () => const MediaGridShimmer(),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(
                context,
                'Failed to load likes',
                error.toString(),
                () => controller.switchTab(ProfileTabs.likes),
              ),
            ),
          ),
        ];

      default:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Invalid tab'),
            ),
          ),
        ];
    }
  }

  /// Build error state widget
  Widget _buildErrorState(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle edit profile action
  void _handleEditProfile() {
    // TODO: Navigate to edit profile screen
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Edit Profile - TODO: Implement navigation'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle stats tap (posts, followers, following)
  void _handleStatsTap(String type) {
    switch (type) {
      case 'followers':
        context.go('/profile/$userId/followers');
        break;
      case 'following':
        context.go('/profile/$userId/following');
        break;
      case 'posts':
        // For posts, we could scroll to the top or show a filter
        // For now, just show a message
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Already viewing posts'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        break;
    }
  }

  /// Handle media item tap
  void _handleMediaTap(item, int index) {
    // Navigate to status detail screen using the MediaItem's status ID
    context.go('/status/${item.id}');
  }

  /// Handle comment tap
  void _handleCommentTap(item) {
    // TODO: Navigate to comment thread
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Comment ${item.id} - TODO: Implement comment view'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle boost tap
  void _handleBoostTap(item) {
    // TODO: Navigate to original post
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Boost ${item.id} - TODO: Implement post view'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Profile screen with app bar variant (for navigation contexts)
class ProfileScreenWithAppBar extends ConsumerWidget {
  final ProfileRouteArgs args;
  final String? title;

  const ProfileScreenWithAppBar({
    super.key,
    required this.args,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider(args.userId));
    final username = state.profile.valueOrNull?.username ?? 
                    args.username ?? 
                    'Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? '@$username'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Share button
          IconButton(
            onPressed: () => _handleShare(context, args),
            icon: const Icon(Icons.share),
            tooltip: 'Share Profile',
          ),
          // More options
          IconButton(
            onPressed: () => _handleMoreOptions(context, args),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
          ),
        ],
      ),
      body: ProfileScreen(args: args),
    );
  }

  void _handleShare(BuildContext context, ProfileRouteArgs args) {
    // TODO: Implement profile sharing
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Share Profile - TODO: Implement sharing'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleMoreOptions(BuildContext context, ProfileRouteArgs args) {
    // TODO: Show bottom sheet with more options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report user
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Profile Link'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy link
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Error handler for profile screens
class ProfileErrorHandler {
  static void handleError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // Log error for debugging
    debugPrint('Profile Error: $error');
    debugPrint('Stack Trace: $stackTrace');

    // Show user-friendly error message
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              messenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  static String _getErrorMessage(Object error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('not found')) {
      return 'Profile not found.';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied. Profile may be private.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}

/// Profile screen configuration
class ProfileScreenConfig {
  static const double maxRefreshDistance = 100.0;
  static const Duration refreshIndicatorDuration = Duration(milliseconds: 300);
  
  /// Check if profile should auto-refresh based on last update
  static bool shouldAutoRefresh(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;
    
    const refreshInterval = Duration(minutes: 5);
    return DateTime.now().difference(lastUpdate) > refreshInterval;
  }
}
