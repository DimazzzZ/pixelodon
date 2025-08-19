import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/new_auth_provider.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';

/// Widget for displaying a feed of posts
class FeedList extends ConsumerStatefulWidget {
  /// The list of statuses to display
  final List<Status> statuses;
  
  /// Whether the feed is loading
  final bool isLoading;
  
  /// Whether there is an error
  final bool hasError;
  
  /// The error message
  final String? errorMessage;
  
  /// Whether there are more posts to load
  final bool hasMore;
  
  /// Callback when the user scrolls to the bottom of the feed
  final VoidCallback? onLoadMore;
  
  /// Callback when the user pulls to refresh
  final Future<void> Function()? onRefresh;
  
  /// Callback when a post is liked
  final Function(Status status, bool liked)? onPostLiked;
  
  /// Callback when a post is reblogged
  final Function(Status status, bool reblogged)? onPostReblogged;
  
  /// Callback when a post is bookmarked
  final Function(Status status, bool bookmarked)? onPostBookmarked;
  
  /// Constructor
  const FeedList({
    super.key,
    required this.statuses,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.onPostLiked,
    this.onPostReblogged,
    this.onPostBookmarked,
  });

  @override
  ConsumerState<FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<FeedList> {
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Handle scroll events to load more posts
  void _onScroll() {
    if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Load more when user scrolls to 80% of the list
      if (currentScroll >= maxScroll * 0.8) {
        widget.onLoadMore!();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final activeInstance = ref.watch(newActiveInstanceProvider);
    
    if (activeInstance == null) {
      return const Center(
        child: Text('No active instance selected'),
      );
    }
    
    if (widget.hasError) {
      return Center(
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
              widget.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (widget.statuses.isEmpty) {
      if (widget.isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No posts to display',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull to refresh or check back later',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.statuses.length + (widget.isLoading && widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.statuses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final status = widget.statuses[index];
          
          return PostCard(
            status: status,
            domain: activeInstance.domain,
            onLiked: (liked) {
              if (widget.onPostLiked != null) {
                widget.onPostLiked!(status, liked);
              }
            },
            onReblogged: (reblogged) {
              if (widget.onPostReblogged != null) {
                widget.onPostReblogged!(status, reblogged);
              }
            },
            onBookmarked: (bookmarked) {
              if (widget.onPostBookmarked != null) {
                widget.onPostBookmarked!(status, bookmarked);
              }
            },
          );
        },
      ),
    );
  }
}
