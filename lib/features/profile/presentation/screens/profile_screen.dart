import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/features/profile/domain/profile_usecases.dart';
import 'package:pixelodon/features/profile/state/profile_controller.dart';
import 'package:pixelodon/features/profile/state/profile_state.dart';
import 'package:pixelodon/features/profile/data/profile_models.dart';
import 'package:pixelodon/features/profile/presentation/widgets/profile_header.dart';
import 'package:pixelodon/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:pixelodon/features/profile/presentation/widgets/profile_tabbar.dart';
import 'package:pixelodon/features/profile/presentation/widgets/media_grid_sliver.dart';
import 'package:pixelodon/features/profile/presentation/widgets/comments_list_sliver.dart';
import 'package:pixelodon/features/profile/presentation/widgets/boosts_list_sliver.dart';
import 'package:pixelodon/features/profile/presentation/widgets/likes_grid_sliver.dart';
import 'package:pixelodon/features/profile/presentation/widgets/shimmer_placeholders.dart';
import 'package:pixelodon/utils/account_utils.dart';

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

class _ProfileScreenState extends ConsumerState<ProfileScreen> 
    with AutomaticKeepAliveClientMixin {
  late final String userId;
  late final ScrollController _scrollController;
  static const double _expandedHeight = 180.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    userId = widget.args.userId;
    
    // Initialize scroll controller
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeaderImage(BuildContext context, ProfileState state) {
    final profile = state.profile.valueOrNull;
    
    // Check if we have a profile and it's a Mastodon account with a header image
    if (profile != null && 
        profile.coverUrl.isNotEmpty && 
        _isMastodonAccount(profile)) {
      return Image.network(
        profile.coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default background if header image fails to load
          return Image.asset(
            'assets/images/bg_default.png',
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          // Show default background while loading
          return Image.asset(
            'assets/images/bg_default.png',
            fit: BoxFit.cover,
          );
        },
      );
    }
    
    // Default fallback
    return Image.asset(
      'assets/images/bg_default.png',
      fit: BoxFit.cover,
    );
  }

  bool _isMastodonAccount(UserProfile profile) {
    // For now, we assume all accounts are Mastodon unless explicitly marked as Pixelfed
    // This is based on the Account model having an isPixelfed field
    // Since UserProfile doesn't have this field directly, we'll assume it's Mastodon
    // if it has a header image (Mastodon supports header images, Pixelfed might not always have them)
    return profile.coverUrl.isNotEmpty;
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final controller = ref.watch(profileControllerProvider(userId));
    final state = controller.state;
    final profile = state.profile.valueOrNull;

    final activeInstance = ref.watch(activeInstanceProvider);
    final formattedHandle = profile != null ? AccountUtils.formatHandle(
      acct: profile.acct,
      username: profile.username,
      fallbackDomain: activeInstance?.domain,
    ) : 'Profile';

    // Use platform-specific scaffold similar to Home and Notifications screens
    if (Platform.isIOS) {
      return _buildIOSScaffold(context, controller, profile, formattedHandle);
    } else {
      return _buildMaterialScaffold(context, controller, profile, formattedHandle);
    }
  }

  /// Build iOS-style scaffold with CupertinoSliverNavigationBar
  Widget _buildIOSScaffold(BuildContext context, ProfileController controller, UserProfile? profile, String formattedHandle) {
    final state = controller.state;
    return CupertinoPageScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _scrollController,
          key: PageStorageKey('profile_scroll_$userId'),
          clipBehavior: Clip.none,
          slivers: [
            // iOS navigation bar with large title
            CupertinoSliverNavigationBar(
              largeTitle: Text(profile?.displayName ?? formattedHandle),
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
              trailing: _buildIOSActions(context, state),
              stretch: false,
            ),

            // Custom header with background image
            SliverToBoxAdapter(
              child: SizedBox(
                height: _expandedHeight - kToolbarHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildHeaderImage(context, state),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black26],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Content (avatar, username, bio)
            SliverProfileContent(
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

            // iOS-style tab bar
            _buildIOSTabBar(context, state, controller),

            // Tab Content
            ..._buildTabContent(state, controller),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar
  Widget _buildMaterialScaffold(BuildContext context, ProfileController controller, UserProfile? profile, String formattedHandle) {
    final state = controller.state;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar.large(
                title: Text(profile?.displayName ?? formattedHandle),
                pinned: true,
                actions: _buildMaterialActions(context, state),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: ProfileTabBar(
                    selectedIndex: state.selectedTabIndex,
                    onTabChanged: (index) => controller.switchTab(index),
                    isLoading: state.isCurrentTabLoading,
                    isOwnProfile: state.isOwnProfile,
                  ),
                ),
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            return CustomScrollView(
              controller: _scrollController,
              key: PageStorageKey('profile_scroll_$userId'),
              clipBehavior: Clip.none,
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),

                // Custom header with background image
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _expandedHeight - kToolbarHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildHeaderImage(context, state),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black26],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Content (avatar, username, bio)
                SliverProfileContent(
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

                // Tab Content
                ..._buildTabContent(state, controller),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build iOS-style action buttons
  Widget? _buildIOSActions(BuildContext context, ProfileState state) {
    if (!state.isOwnProfile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(0),
            minSize: 0,
            onPressed: () => _handleShare(context),
            child: Icon(
              CupertinoIcons.share,
              color: CupertinoColors.activeBlue.resolveFrom(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(0),
            minSize: 0,
            onPressed: () => _handleMoreOptions(context),
            child: Icon(
              CupertinoIcons.ellipsis,
              color: CupertinoColors.activeBlue.resolveFrom(context),
              size: 22,
            ),
          ),
        ],
      );
    } else {
      return CupertinoButton(
        padding: const EdgeInsets.all(0),
        minSize: 0,
        onPressed: () => context.push('/settings'),
        child: Icon(
          CupertinoIcons.settings,
          color: CupertinoColors.activeBlue.resolveFrom(context),
          size: 22,
        ),
      );
    }
  }

  /// Build Material-style action buttons
  List<Widget> _buildMaterialActions(BuildContext context, ProfileState state) {
    if (!state.isOwnProfile) {
      return [
        IconButton(
          onPressed: () => _handleShare(context),
          icon: const Icon(Icons.share),
          tooltip: 'Share Profile',
        ),
        IconButton(
          onPressed: () => _handleMoreOptions(context),
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
      ];
    }
  }

  /// Build iOS-style tab bar
  Widget _buildIOSTabBar(BuildContext context, ProfileState state, ProfileController controller) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _IOSTabBarDelegate(
        selectedIndex: state.selectedTabIndex,
        onTabChanged: (index) => controller.switchTab(index),
        isLoading: state.isCurrentTabLoading,
        isOwnProfile: state.isOwnProfile,
      ),
    );
  }

  /// Handle share action
  void _handleShare(BuildContext context) async {
    try {
      final controller = ref.read(profileControllerProvider(userId));
      final profile = controller.state.profile.valueOrNull;

      if (profile == null) {
        _showErrorMessage(context, 'Profile not loaded');
        return;
      }

      final activeInstance = ref.read(activeInstanceProvider);
      final domain = activeInstance?.domain ?? 'unknown';

      // Build share content
      final displayName = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : profile.username;
      final username = profile.username;

      String shareText = 'Check out $displayName\'s profile on $domain';

      // Add bio if available and not too long
      if (profile.bio.isNotEmpty) {
        final plainBio = profile.bio
            .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '') // Remove HTML entities
            .trim();

        if (plainBio.isNotEmpty && plainBio.length <= 150) {
          shareText += '\n\n"$plainBio"';
        }
      }

      // Add profile URL
      shareText += '\n\nhttps://$domain/@$username';

      // Share using the native OS share dialog
      await Share.share(shareText);
    } catch (e) {
      _showErrorMessage(context, 'Failed to share profile: ${e.toString()}');
    }
  }

  /// Show error message with platform-specific styling
  void _showErrorMessage(BuildContext context, String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Handle more options action
  void _handleMoreOptions(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Profile Options'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _handleBlock(context);
              },
              isDestructiveAction: true,
              child: const Text('Block User'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _handleReport(context);
              },
              child: const Text('Report User'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () {
                Navigator.of(context).pop();
                _handleBlock(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report User'),
              onTap: () {
                Navigator.of(context).pop();
                _handleReport(context);
              },
            ),
          ],
        ),
      );
    }
  }

  /// Handle block user action
  void _handleBlock(BuildContext context) {
    // TODO: Implement user blocking
    final message = Platform.isIOS ? 'User blocking will be available soon.' : 'User blocking will be available soon.';
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Block User'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Handle report user action
  void _handleReport(BuildContext context) {
    // TODO: Implement user reporting
    final message = Platform.isIOS ? 'User reporting will be available soon.' : 'User reporting will be available soon.';
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Report User'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
    context.push('/status/${item.id}');
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
    final controller = ref.watch(profileControllerProvider(args.userId));
    final username = controller.state.profile.valueOrNull?.username ?? 
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
            onPressed: () => _handleShare(context, args, ref),
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

  void _handleShare(BuildContext context, ProfileRouteArgs args, WidgetRef ref) async {
    try {
      final controller = ref.read(profileControllerProvider(args.userId));
      final profile = controller.state.profile.valueOrNull;

      if (profile == null) {
        _showErrorMessage(context, 'Profile not loaded');
        return;
      }

      final activeInstance = ref.read(activeInstanceProvider);
      final domain = activeInstance?.domain ?? 'unknown';

      // Build share content
      final displayName = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : profile.username;
      final username = profile.username;

      String shareText = 'Check out $displayName\'s profile on $domain';

      // Add bio if available and not too long
      if (profile.bio.isNotEmpty) {
        final plainBio = profile.bio
            .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), '') // Remove HTML entities
            .trim();

        if (plainBio.isNotEmpty && plainBio.length <= 150) {
          shareText += '\n\n"$plainBio"';
        }
      }

      // Add profile URL
      shareText += '\n\nhttps://$domain/@$username';

      // Share using the native OS share dialog
      await Share.share(shareText);
    } catch (e) {
      _showErrorMessage(context, 'Failed to share profile: ${e.toString()}');
    }
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
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

/// iOS-style tab bar delegate for profile tabs
class _IOSTabBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final bool isLoading;
  final bool isOwnProfile;

  _IOSTabBarDelegate({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.isLoading,
    required this.isOwnProfile,
  });

  @override
  double get minExtent => 56.0;

  @override
  double get maxExtent => 56.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: selectedIndex,
            onValueChanged: (int? value) {
              if (value != null) {
                onTabChanged(value);
              }
            },
            children: {
              ProfileTabs.media: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Media'),
              ),
              ProfileTabs.comments: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Comments'),
              ),
              ProfileTabs.boosts: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Boosts'),
              ),
              if (isOwnProfile)
                ProfileTabs.likes: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Likes'),
                ),
            },
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}
