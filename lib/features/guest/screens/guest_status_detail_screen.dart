import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';

part 'guest_status_detail_screen.g.dart';

/// Default instance for guest mode
const String _defaultGuestInstance = 'mastodon.social';

/// Simple guest API service for status details
@Riverpod(keepAlive: true)
Dio guestStatusApi(GuestStatusApiRef ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.headers = {
    'User-Agent': 'Pixelodon/1.0.0',
    'Accept': 'application/json',
  };
  return dio;
}

/// State for guest status detail
class GuestStatusDetailState {
  final Status? status;
  final List<Status> ancestors;
  final List<Status> descendants;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const GuestStatusDetailState({
    this.status,
    this.ancestors = const [],
    this.descendants = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  GuestStatusDetailState copyWith({
    Status? status,
    List<Status>? ancestors,
    List<Status>? descendants,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return GuestStatusDetailState(
      status: status ?? this.status,
      ancestors: ancestors ?? this.ancestors,
      descendants: descendants ?? this.descendants,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for guest status detail
@Riverpod(keepAlive: true)
GuestStatusDetailNotifier guestStatusDetail(GuestStatusDetailRef ref, String statusId) {
  final dio = ref.watch(guestStatusApiProvider);
  return GuestStatusDetailNotifier(dio, statusId);
}

/// Notifier for guest status detail
class GuestStatusDetailNotifier extends StateNotifier<GuestStatusDetailState> {
  final Dio _dio;
  final String _statusId;

  GuestStatusDetailNotifier(this._dio, this._statusId) : super(const GuestStatusDetailState()) {
    loadStatus();
  }

  Future<void> loadStatus() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      print('Guest mode: Loading status $_statusId from $_defaultGuestInstance');

      // Load the main status
      final statusResponse = await _dio.get(
        'https://$_defaultGuestInstance/api/v1/statuses/$_statusId',
      );

      final status = Status.fromJson(statusResponse.data as Map<String, dynamic>);

      // Load the context (ancestors and descendants)
      final contextResponse = await _dio.get(
        'https://$_defaultGuestInstance/api/v1/statuses/$_statusId/context',
      );

      final ancestors = (contextResponse.data['ancestors'] as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      final descendants = (contextResponse.data['descendants'] as List)
          .map((json) => Status.fromJson(json as Map<String, dynamic>))
          .toList();

      print('Guest mode: Loaded status with ${ancestors.length} ancestors and ${descendants.length} descendants');

      state = state.copyWith(
        status: status,
        ancestors: ancestors,
        descendants: descendants,
        isLoading: false,
      );
    } catch (e) {
      print('Guest mode: Error loading status: $e');
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load post: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = const GuestStatusDetailState();
    await loadStatus();
  }
}

/// Guest-friendly status detail screen
class GuestStatusDetailScreen extends ConsumerWidget {
  final String statusId;

  const GuestStatusDetailScreen({super.key, required this.statusId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GuestStatusDetailNotifier notifier = ref.watch(guestStatusDetailProvider(statusId));
    final GuestStatusDetailState state = notifier.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildContent(context, state, notifier),
    );
  }

  Widget _buildContent(BuildContext context, GuestStatusDetailState state, GuestStatusDetailNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load post',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == null) {
      return const Center(
        child: Text('Post not found'),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Guest mode banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Viewing as guest • Sign in to interact',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ancestors (conversation thread)
          if (state.ancestors.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Conversation', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final ancestor in state.ancestors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildGuestPostCard(ancestor, context),
              ),
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
          ],

          // Main status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildGuestPostCard(state.status!, context),
          ),

          // Replies section
          if (state.descendants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Text(
                'No replies yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Replies', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final reply in state.descendants)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildGuestPostCard(reply, context),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestPostCard(Status status, BuildContext context) {
    return _GuestDetailPostCard(
      status: status,
      domain: _defaultGuestInstance,
      onInteractionTap: (action) => _showInteractionPrompt(context, action),
    );
  }

  void _showInteractionPrompt(BuildContext context, String action) {
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


}

/// Custom PostCard for guest status detail that intercepts interactions
class _GuestDetailPostCard extends StatelessWidget {
  final Status status;
  final String domain;
  final Function(String action) onInteractionTap;

  const _GuestDetailPostCard({
    required this.status,
    required this.domain,
    required this.onInteractionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Create a PostCard with a custom interaction overlay
    return Stack(
      children: [
        // The actual PostCard with disabled interactions
        IgnorePointer(
          // Disable all pointer events on the PostCard to prevent conflicts
          child: PostCard(
            status: status,
            domain: domain,
            showFullContent: true, // Show full content in detail view
            // Don't provide callbacks - we'll handle all interactions
          ),
        ),

        // Interaction buttons overlay (only the bottom area)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 56, // Height of the interaction button area
          child: _DetailInteractionOverlay(
            status: status,
            onInteractionTap: onInteractionTap,
          ),
        ),
      ],
    );
  }
}

/// Overlay that intercepts interaction button taps in detail view
class _DetailInteractionOverlay extends StatelessWidget {
  final Status status;
  final Function(String action) onInteractionTap;

  const _DetailInteractionOverlay({
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
          // Comment button area (disabled in detail view since we're already viewing comments)
          Expanded(
            child: Container(
              color: Colors.transparent,
              height: 40,
            ),
          ),
          // Repost button area
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('Guest mode detail: Repost button tapped');
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
                print('Guest mode detail: Like button tapped');
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
              onTap: () {
                print('Guest mode detail: Bookmark button tapped');
                onInteractionTap('bookmark');
              },
              child: Container(
                color: Colors.transparent,
                height: 40,
                // Uncomment for debugging click areas:
                // color: Colors.purple.withOpacity(0.2),
              ),
            ),
          ),
          // Share button area
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('Guest mode detail: Share button tapped');
                onInteractionTap('share');
              },
              child: Container(
                color: Colors.transparent,
                height: 40,
                // Uncomment for debugging click areas:
                // color: Colors.teal.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
