import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';


import 'package:dio/dio.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';

part 'guest_screen.g.dart';

/// Default instance for guest mode
const String _defaultGuestInstance = 'mastodon.social';

/// Simple guest API service that doesn't require authentication
@Riverpod(keepAlive: true)
Dio guestApiService(GuestApiServiceRef ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.headers = {
    'User-Agent': 'Pixelodon/1.0.0',
    'Accept': 'application/json',
  };
  return dio;
}

/// Provider for guest mode public timeline with dynamic instance
@Riverpod(keepAlive: true)
class GuestPublicTimeline extends _$GuestPublicTimeline {
  @override
  GuestTimelineState build(String domain) {
    Future.microtask(() => loadTimeline());
    return const GuestTimelineState();
  }

  Future<void> loadTimeline() async {
    final dio = ref.read(guestApiServiceProvider);
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      final response = await dio.get(
        'https://$domain/api/v1/timelines/public',
        queryParameters: {
          'limit': 20,
          'local': false,
        },
      );

      final statuses = (response.data as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load timeline: $e',
      );
    }
  }

  Future<void> loadMore() async {
    final dio = ref.read(guestApiServiceProvider);
    if (state.isLoading || !state.hasMore || state.maxId == null) return;

    try {
      final response = await dio.get(
        'https://$domain/api/v1/timelines/public',
        queryParameters: {
          'limit': 20,
          'max_id': state.maxId,
          'local': false,
        },
      );

      final newStatuses = (response.data as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      String? maxId = state.maxId;
      if (newStatuses.isNotEmpty) {
        maxId = newStatuses.last.id;
      }

      state = state.copyWith(
        statuses: [...state.statuses, ...newStatuses],
        hasMore: newStatuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      // Silently fail for load more
    }
  }

  Future<void> refresh() async {
    state = const GuestTimelineState();
    await loadTimeline();
  }
}

/// Provider for guest mode local timeline with dynamic instance
@Riverpod(keepAlive: true)
class GuestLocalTimeline extends _$GuestLocalTimeline {
  @override
  GuestTimelineState build(String domain) {
    Future.microtask(() => loadTimeline());
    return const GuestTimelineState();
  }

  Future<void> loadTimeline() async {
    final dio = ref.read(guestApiServiceProvider);
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      final response = await dio.get(
        'https://$domain/api/v1/timelines/public',
        queryParameters: {
          'limit': 20,
          'local': true,
        },
      );

      final statuses = (response.data as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load timeline: $e',
      );
    }
  }

  Future<void> loadMore() async {
    final dio = ref.read(guestApiServiceProvider);
    if (state.isLoading || !state.hasMore || state.maxId == null) return;

    try {
      final response = await dio.get(
        'https://$domain/api/v1/timelines/public',
        queryParameters: {
          'limit': 20,
          'max_id': state.maxId,
          'local': true,
        },
      );

      final newStatuses = (response.data as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      String? maxId = state.maxId;
      if (newStatuses.isNotEmpty) {
        maxId = newStatuses.last.id;
      }

      state = state.copyWith(
        statuses: [...state.statuses, ...newStatuses],
        hasMore: newStatuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      // Silently fail for load more
    }
  }

  Future<void> refresh() async {
    state = const GuestTimelineState();
    await loadTimeline();
  }
}

/// State for guest timeline
class GuestTimelineState {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;

  const GuestTimelineState({
    this.statuses = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
  });

  GuestTimelineState copyWith({
    List<Status>? statuses,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
  }) {
    return GuestTimelineState(
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
    );
  }
}

/// Guest mode screen that allows browsing public timelines without authentication
class GuestScreen extends ConsumerStatefulWidget {
  final String? instance;

  const GuestScreen({super.key, this.instance});

  @override
  ConsumerState<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends ConsumerState<GuestScreen> {
  int _selectedIndex = 0;
  late String _instanceDomain;

  @override
  void initState() {
    super.initState();
    _instanceDomain = widget.instance ?? _defaultGuestInstance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppPageScaffold.sliver(
      largeTitle: 'Guest Mode',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/onboarding'),
      ),
      sliverBodyBuilder: () => CustomScrollView(
        slivers: [
          _buildInfoBannerSliver(context, theme),
          _buildSegmentedControlSliver(context, theme),
          _buildContentSliver(),
        ],
      ),
      bottomAction: ElevatedButton.icon(
        onPressed: () => _showLoginOptions(context),
        icon: const Icon(Icons.account_circle),
        label: const Text('Sign In'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
  
  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.onPrimary 
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGuestPostCard(Status status) {
    return _GuestPostCard(
      key: Key('guest_status_card_${status.id}'),
      status: status,
      domain: _instanceDomain,
      onInteractionTap: _showInteractionPrompt,
    );
  }

  void _showInteractionPrompt(String action) {
    String message;
    String actionName;

    switch (action) {
      case 'like':
        message = 'Likes help authors know their content is appreciated. Sign in to like posts.';
        actionName = 'Like Posts';
        break;
      case 'repost':
        message = 'Reposts share content with your followers. Sign in to repost.';
        actionName = 'Repost Content';
        break;
      case 'bookmark':
        message = 'Bookmarks save posts for later reading. Sign in to bookmark posts.';
        actionName = 'Bookmark Posts';
        break;
      case 'share':
        message = 'Share posts with others. Sign in for more sharing options.';
        actionName = 'Share Posts';
        break;
      case 'comment':
        message = 'Join the conversation by replying to posts. Sign in to comment.';
        actionName = 'Comment on Posts';
        break;
      default:
        message = 'This feature is only available for signed in users.';
        actionName = 'Feature';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(actionName),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/auth/login');
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }


  
  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in to existing account'),
              subtitle: const Text('Login to your Mastodon or Pixelfed account'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/auth/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to onboarding'),
              subtitle: const Text('Choose a server or create a new account'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/onboarding');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControlSliver(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Platform.isIOS
            ? CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Global'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Local'),
                  ),
                },
                onValueChanged: (value) {
                  setState(() => _selectedIndex = value);
                },
                groupValue: _selectedIndex,
              )
            : Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        context: context,
                        title: 'Global',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        context: context,
                        title: 'Local',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBannerSliver(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Browsing $_instanceDomain as guest • Sign in to interact',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_selectedIndex == 0) {
      return _buildGlobalTimelineSliver();
    } else {
      return _buildLocalTimelineSliver();
    }
  }

  Widget _buildGlobalTimelineSliver() {
    final timelineState = ref.watch(guestPublicTimelineProvider(_instanceDomain));
    final timelineNotifier = ref.read(guestPublicTimelineProvider(_instanceDomain).notifier);

    return _buildGuestFeedSliver(
      timelineState: timelineState,
      onLoadMore: timelineNotifier.loadMore,
      onRefresh: timelineNotifier.refresh,
    );
  }

  Widget _buildLocalTimelineSliver() {
    final timelineState = ref.watch(guestLocalTimelineProvider(_instanceDomain));
    final timelineNotifier = ref.read(guestLocalTimelineProvider(_instanceDomain).notifier);

    return _buildGuestFeedSliver(
      timelineState: timelineState,
      onLoadMore: timelineNotifier.loadMore,
      onRefresh: timelineNotifier.refresh,
    );
  }

  Widget _buildGuestFeedSliver({
    required GuestTimelineState timelineState,
    required VoidCallback onLoadMore,
    required Future<void> Function() onRefresh,
  }) {
    if (timelineState.hasError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                timelineState.errorMessage ?? 'Failed to load timeline',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (timelineState.statuses.isEmpty) {
      if (timelineState.isLoading) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No posts to display',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pull to refresh or check back later',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == timelineState.statuses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading more...'),
                  ],
                ),
              ),
            );
          }

          final status = timelineState.statuses[index];

          // Load more when approaching the end
          if (index == timelineState.statuses.length - 3 &&
              timelineState.hasMore &&
              !timelineState.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore();
            });
          }

          return _buildGuestPostCard(status);
        },
        childCount: timelineState.statuses.length +
                   (timelineState.isLoading && timelineState.hasMore ? 1 : 0),
      ),
    );
  }
}

/// Custom PostCard for guest mode that intercepts interactions
class _GuestPostCard extends ConsumerWidget {
  final Status status;
  final String domain;
  final Function(String action) onInteractionTap;

  const _GuestPostCard({
    super.key,
    required this.status,
    required this.domain,
    required this.onInteractionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a PostCard with a custom interaction overlay
    return Stack(
      children: [
        // The actual PostCard with disabled interactions
        IgnorePointer(
          // Disable all pointer events on the PostCard to prevent conflicts
          child: PostCard(
            status: status,
            domain: domain,
            showFullContent: false,
            // Don't provide callbacks - we'll handle all interactions
          ),
        ),

        // Main post area tap (everything except the bottom interaction bar)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 56, // Leave space for interaction buttons
          child: GestureDetector(
            onTap: () {
              print('Guest mode: Main post area tapped for status ${status.id}');
              // Navigate to guest status detail
              if (status.id.isNotEmpty) {
                GoRouter.of(context).push('/guest/status/${status.id}');
              }
            },
            child: Container(
              color: Colors.transparent,
              // Uncomment for debugging click areas:
              // color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ),

        // Interaction buttons overlay (only the bottom area)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 56, // Height of the interaction button area
          child: _InteractionOverlay(
            status: status,
            onInteractionTap: onInteractionTap,
          ),
        ),
      ],
    );
  }
}

/// Overlay that intercepts interaction button taps
class _InteractionOverlay extends StatelessWidget {
  final Status status;
  final Function(String action) onInteractionTap;

  const _InteractionOverlay({
    required this.status,
    required this.onInteractionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Comment button area
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('Guest mode: Comment button tapped for status ${status.id}');
                // Navigate to guest status detail for comments
                if (status.id.isNotEmpty) {
                  GoRouter.of(context).push('/guest/status/${status.id}');
                }
              },
              child: Container(
                color: Colors.transparent,
                height: 40,
                // Uncomment for debugging click areas:
                // color: Colors.green.withOpacity(0.2),
              ),
            ),
          ),
          // Repost button area
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('Guest mode: Repost button tapped');
                onInteractionTap('repost');
              },
              child: Container(
                color: Colors.transparent,
                height: 40,
                // Uncomment for debugging click areas:
                // color: Colors.orange.withOpacity(0.2),
              ),
            ),
          ),
          // Like button area
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('Guest mode: Like button tapped');
                onInteractionTap('like');
              },
              child: Container(
                color: Colors.transparent,
                height: 40,
                // Uncomment for debugging click areas:
                // color: Colors.red.withOpacity(0.2),
              ),
            ),
          ),
          // Bookmark button area
          Expanded(
            child: GestureDetector(
              onTap: () => onInteractionTap('bookmark'),
              child: Container(
                color: Colors.transparent,
                height: 40,
              ),
            ),
          ),
          // Share button area
          Expanded(
            child: GestureDetector(
              onTap: () => onInteractionTap('share'),
              child: Container(
                color: Colors.transparent,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
