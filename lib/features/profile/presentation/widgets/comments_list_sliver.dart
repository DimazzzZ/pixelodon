import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/profile_models.dart';
import 'shimmer_placeholders.dart';

/// Comments list sliver for displaying user's replies and comments
class CommentsListSliver extends StatelessWidget {
  final List<CommentItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(CommentItem item)? onItemTap;
  final String? emptyMessage;

  const CommentsListSliver({
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
            return _CommentListItem(
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
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'No comments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comments and replies will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual comment list item
class _CommentListItem extends StatelessWidget {
  final CommentItem item;
  final VoidCallback? onTap;

  const _CommentListItem({
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(context, theme),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author and timestamp
                    _buildHeader(context, theme),
                    const SizedBox(height: 4),
                    // Comment text
                    _buildCommentText(context, theme),
                    const SizedBox(height: 8),
                    // Actions (reply indicator, etc.)
                    _buildActions(context, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: item.authorAvatar,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Author name
        Text(
          item.author,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        // Timestamp
        Text(
          timeago.format(item.createdAt, locale: 'en_short'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // More options
        Icon(
          Icons.more_horiz,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildCommentText(BuildContext context, ThemeData theme) {
    return Text(
      item.text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      maxLines: null, // Allow multiple lines
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Reply indicator
        if (item.inReplyToId != null) ...[
          Icon(
            Icons.reply,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Reply',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
        const Spacer(),
        // Like/heart (placeholder)
        _ActionButton(
          icon: Icons.favorite_border,
          onTap: () {
            // TODO: Implement like functionality
          },
        ),
        const SizedBox(width: 16),
        // Reply (placeholder)
        _ActionButton(
          icon: Icons.reply,
          onTap: () {
            // TODO: Implement reply functionality
          },
        ),
      ],
    );
  }
}

/// Action button widget for comment actions
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
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
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

/// Enhanced comments list with error handling
class CommentsListSliverEnhanced extends StatelessWidget {
  final List<CommentItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(CommentItem item)? onItemTap;
  final String? emptyMessage;

  const CommentsListSliverEnhanced({
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

    return CommentsListSliver(
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
            'Failed to load comments',
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

/// Configuration for comments list
class CommentsListConfig {
  static const double itemPadding = 16.0;
  static const double avatarSize = 40.0;
  static const double avatarMargin = 12.0;
  static const int loadMoreThreshold = 2; // Load more when 2 items from end

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'en_short');
  }
}

/// Extension methods for CommentsListSliver
extension CommentsListSliverExtensions on CommentsListSliver {
  /// Create a loading version
  CommentsListSliver asLoading() {
    return CommentsListSliver(
      items: const [],
      isLoading: true,
    );
  }

  /// Create an error version
  Widget asError(String error, VoidCallback? onRetry) {
    return CommentsListSliverEnhanced(
      items: items,
      error: error,
      onRetry: onRetry,
    );
  }
}
