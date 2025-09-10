import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';

import 'package:pixelodon/widgets/feed/post_card.dart';

/// Widget for displaying only posts with images in a list format
class ImagesListView extends ConsumerWidget {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;
  final Function(Status, bool)? onPostLiked;
  final Function(Status, bool)? onPostReblogged;
  final Function(Status, bool)? onPostBookmarked;

  const ImagesListView({
    super.key,
    required this.statuses,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.onLoadMore,
    this.onRefresh,
    this.onPostLiked,
    this.onPostReblogged,
    this.onPostBookmarked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter statuses to only include those with images
    final imageStatuses = statuses.where((status) {
      return status.mediaAttachments.any((media) =>
        media.type == AttachmentType.image || media.type == AttachmentType.gifv);
    }).toList();

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Failed to load images',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (imageStatuses.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No images found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Posts with images will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              hasMore && !isLoading) {
            onLoadMore?.call();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: imageStatuses.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= imageStatuses.length) {
              // Loading indicator
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final status = imageStatuses[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: PostCard(
                key: Key('image_post_card_${status.id}'),
                status: status,
                domain: '', // Will be filled by the parent
                onLiked: onPostLiked != null 
                    ? (liked) => onPostLiked!(status, liked)
                    : null,
                onReblogged: onPostReblogged != null
                    ? (reblogged) => onPostReblogged!(status, reblogged)
                    : null,
                onBookmarked: onPostBookmarked != null
                    ? (bookmarked) => onPostBookmarked!(status, bookmarked)
                    : null,

              ),
            );
          },
        ),
      ),
    );
  }
}
