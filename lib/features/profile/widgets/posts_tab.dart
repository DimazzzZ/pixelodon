import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/widgets/feed/feed_list.dart';

class PostsTab extends StatelessWidget {
  final List<model.Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final bool isPixelfed;
  final bool onlyMedia;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Function(bool onlyMedia) onEnsureOnlyMedia;
  final void Function(model.Status status) onStatusUpdated;

  const PostsTab({
    super.key,
    required this.statuses,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.hasMore,
    required this.isPixelfed,
    required this.onlyMedia,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onEnsureOnlyMedia,
    required this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure Pixelfed shows only media grid
    if (isPixelfed && !onlyMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onEnsureOnlyMedia(true);
      });
    }

    if (isPixelfed) {
      // Grid for Pixelfed with pull-to-refresh
      if (statuses.isEmpty) {
        // Provide a scrollable to enable pull-to-refresh even with no items
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('No posts yet'),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: statuses.length + (isLoading && hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == statuses.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final status = statuses[index];
            if (status.mediaAttachments.isEmpty) {
              return const SizedBox.shrink();
            }

            final attachment = status.mediaAttachments.first;

            return GestureDetector(
              onTap: () {
                // Navigate to post detail
                if (status.id.isNotEmpty) {
                  context.push('/status/${status.id}');
                }
              },
              child: CachedNetworkImage(
                imageUrl: attachment.previewUrl ?? attachment.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.error)),
                ),
              ),
            );
          },
        ),
      );
    }

    // List for Mastodon
    return FeedList(
      statuses: statuses,
      isLoading: isLoading,
      hasError: hasError,
      errorMessage: errorMessage,
      hasMore: hasMore,
      onLoadMore: onLoadMore,
      onRefresh: onRefresh,
      onPostLiked: (status, liked) => onStatusUpdated(status),
      onPostReblogged: (status, reblogged) => onStatusUpdated(status),
      onPostBookmarked: (status, bookmarked) => onStatusUpdated(status),
    );
  }
}
