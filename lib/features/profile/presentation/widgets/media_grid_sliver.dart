import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/profile_models.dart';
import 'shimmer_placeholders.dart';

/// Media grid sliver for displaying user's media posts in 3-column grid
class MediaGridSliver extends StatelessWidget {
  final List<MediaItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(MediaItem item, int index)? onItemTap;
  final String? emptyMessage;

  const MediaGridSliver({
    super.key,
    required this.items,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const MediaGridShimmer();
    }

    if (items.isEmpty && !isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(context),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Check if we need to load more items
          if (index >= items.length - 3 && hasMore && !isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore?.call();
            });
          }

          if (index < items.length) {
            return _MediaGridItem(
              item: items[index],
              onTap: () => onItemTap?.call(items[index], index),
            );
          }

          // Loading indicator at the end
          if (index == items.length && isLoadingMore) {
            return _LoadingGridItem();
          }

          return null;
        },
        childCount: items.length + (isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'No media posts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Media posts will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual media grid item
class _MediaGridItem extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;

  const _MediaGridItem({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'media_${item.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media image
                CachedNetworkImage(
                  imageUrl: item.previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 32,
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                // Media type indicator (for videos, etc.)
                if (item.type != 'image')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _getTypeIcon(item.type),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Hover/tap overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_arrow;
      case 'gif':
        return Icons.gif;
      case 'album':
        return Icons.photo_library;
      default:
        return Icons.image;
    }
  }
}

/// Loading grid item placeholder
class _LoadingGridItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced media grid with pull-to-refresh and error states
class MediaGridSliverEnhanced extends StatelessWidget {
  final List<MediaItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(MediaItem item, int index)? onItemTap;
  final String? emptyMessage;

  const MediaGridSliverEnhanced({
    super.key,
    required this.items,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.error,
    this.onLoadMore,
    this.onRetry,
    this.onItemTap,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null && items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(context),
      );
    }

    return MediaGridSliver(
      items: items,
      isLoading: isLoading,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      onLoadMore: onLoadMore,
      onItemTap: onItemTap,
      emptyMessage: emptyMessage,
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
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
            'Failed to load media',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Please try again',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Configuration for media grid
class MediaGridConfig {
  static const int crossAxisCount = 3;
  static const double mainAxisSpacing = 4.0;
  static const double crossAxisSpacing = 4.0;
  static const double childAspectRatio = 1.0;
  static const double borderRadius = 8.0;
  static const int loadMoreThreshold = 3; // Load more when 3 items from end

  /// Calculate grid item size based on screen width
  static double getItemSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (crossAxisSpacing * (crossAxisCount - 1));
    return availableWidth / crossAxisCount;
  }
}

/// Extension methods for MediaGridSliver
extension MediaGridSliverExtensions on MediaGridSliver {
  /// Create a loading version
  MediaGridSliver asLoading() {
    return MediaGridSliver(
      items: const [],
      isLoading: true,
    );
  }

  /// Create an error version
  Widget asError(String error, VoidCallback? onRetry) {
    return MediaGridSliverEnhanced(
      items: items,
      error: error,
      onRetry: onRetry,
    );
  }
}
