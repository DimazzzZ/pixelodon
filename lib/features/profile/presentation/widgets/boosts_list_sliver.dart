import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pixelodon/features/profile/data/profile_models.dart';
import 'package:pixelodon/features/profile/presentation/widgets/shimmer_placeholders.dart';

/// Boosts list sliver for displaying user's boosted/reblogged posts
class BoostsListSliver extends StatelessWidget {
  final List<BoostItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(BoostItem item)? onItemTap;
  final String? emptyMessage;

  const BoostsListSliver({
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
      return const ListShimmer();
    }

    if (items.isEmpty && !isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(context),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Check if we need to load more items
          if (index >= items.length - 2 && hasMore && !isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore?.call();
            });
          }

          if (index < items.length) {
            return _BoostListItem(
              item: items[index],
              onTap: () => onItemTap?.call(items[index]),
            );
          }

          // Loading indicator at the end
          if (index == items.length && isLoadingMore) {
            return const _LoadingListItem();
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
            Icons.repeat,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'No boosts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Boosted posts will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual boost list item
class _BoostListItem extends StatelessWidget {
  final BoostItem item;
  final VoidCallback? onTap;

  const _BoostListItem({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boost header (who boosted)
              _buildBoostHeader(context, theme),
              const SizedBox(height: 12),
              // Original post content
              _buildOriginalPost(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoostHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Boost icon
        Icon(
          Icons.repeat,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        // Boost text
        Expanded(
          child: Text(
            '${item.boosterUsername} boosted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Boost timestamp
        Text(
          timeago.format(item.boostedAt, locale: 'en_short'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPost(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original author header
            _buildOriginalAuthor(context, theme),
            const SizedBox(height: 12),
            // Post content
            _buildPostContent(context, theme),
            // Media preview (if available)
            if (item.previewUrl != null) ...[
              const SizedBox(height: 12),
              _buildMediaPreview(context, theme),
            ],
            const SizedBox(height: 12),
            // Post actions
            _buildPostActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalAuthor(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: item.originalAuthorAvatar,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Author name
        Expanded(
          child: Text(
            item.originalAuthor,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // Original post timestamp
        Text(
          timeago.format(item.createdAt, locale: 'en_short'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context, ThemeData theme) {
    return Text(
      item.text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      maxLines: 4, // Limit to 4 lines for compact display
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMediaPreview(BuildContext context, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: item.previewUrl!,
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
      ),
    );
  }

  Widget _buildPostActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Like action
        _ActionButton(
          icon: Icons.favorite_border,
          onTap: () {
            // TODO: Implement like functionality
          },
        ),
        const SizedBox(width: 24),
        // Comment action
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          onTap: () {
            // TODO: Implement comment functionality
          },
        ),
        const SizedBox(width: 24),
        // Boost action
        _ActionButton(
          icon: Icons.repeat,
          onTap: () {
            // TODO: Implement boost functionality
          },
        ),
        const Spacer(),
        // More options
        _ActionButton(
          icon: Icons.more_horiz,
          onTap: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }
}

/// Action button widget for boost item actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }
}

/// Loading list item placeholder
class _LoadingListItem extends StatelessWidget {
  const _LoadingListItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced boosts list with error handling
class BoostsListSliverEnhanced extends StatelessWidget {
  final List<BoostItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(BoostItem item)? onItemTap;
  final String? emptyMessage;

  const BoostsListSliverEnhanced({
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

    return BoostsListSliver(
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
            'Failed to load boosts',
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

/// Configuration for boosts list
class BoostsListConfig {
  static const double itemPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double avatarSize = 32.0;
  static const int maxTextLines = 4;
  static const int loadMoreThreshold = 2; // Load more when 2 items from end

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'en_short');
  }
}

/// Extension methods for BoostsListSliver
extension BoostsListSliverExtensions on BoostsListSliver {
  /// Create a loading version
  BoostsListSliver asLoading() {
    return const BoostsListSliver(
      items: [],
      isLoading: true,
    );
  }

  /// Create an error version
  Widget asError(String error, VoidCallback? onRetry) {
    return BoostsListSliverEnhanced(
      items: items,
      error: error,
      onRetry: onRetry,
    );
  }
}
