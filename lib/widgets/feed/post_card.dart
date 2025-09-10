import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart' hide Card;
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/media_gallery.dart';
import 'package:pixelodon/features/media/screens/image_viewer_screen.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/utils/link_tap_handler.dart';
import 'package:pixelodon/utils/account_utils.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget for displaying a post in a feed
class PostCard extends ConsumerStatefulWidget {
  /// The status to display
  final Status status;
  
  /// The domain of the instance
  final String domain;
  
  /// Whether to show the full content
  final bool showFullContent;
  
  /// Callback when the post is liked
  final Function(bool liked)? onLiked;
  
  /// Callback when the post is reblogged
  final Function(bool reblogged)? onReblogged;
  
  /// Callback when the post is bookmarked
  final Function(bool bookmarked)? onBookmarked;
  
  /// Constructor
  const PostCard({
    super.key,
    required this.status,
    required this.domain,
    this.showFullContent = false,
    this.onLiked,
    this.onReblogged,
    this.onBookmarked,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late Status _status;
  bool _isLiked = false;
  bool _isReblogged = false;
  bool _isBookmarked = false;
  bool _isExpanded = false;

  
  @override
  void initState() {
    super.initState();
    _status = widget.status.rebloggedStatus ?? widget.status;
    _isLiked = _status.favourited;
    _isReblogged = _status.reblogged;
    _isBookmarked = _status.bookmarked;
    _isExpanded = widget.showFullContent;
  }
  
  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _status = widget.status.rebloggedStatus ?? widget.status;
      _isLiked = _status.favourited;
      _isReblogged = _status.reblogged;
      _isBookmarked = _status.bookmarked;
    }
  }
  
  /// Toggle like status
  Future<void> _toggleLike() async {
    final timelineService = ref.read(timelineServiceProvider);
    
    setState(() {
      _isLiked = !_isLiked;
    });
    
    try {
      if (_isLiked) {
        await timelineService.favouriteStatus(widget.domain, _status.id);
      } else {
        await timelineService.unfavouriteStatus(widget.domain, _status.id);
      }
      
      if (widget.onLiked != null) {
        widget.onLiked!(_isLiked);
      }
    } catch (e) {
      // Revert state if the API call fails
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isLiked ? 'like' : 'unlike'} post'),
            ),
          );
        }
      }
    }
  }
  
  /// Toggle reblog status
  Future<void> _toggleReblog() async {
    final timelineService = ref.read(timelineServiceProvider);
    
    setState(() {
      _isReblogged = !_isReblogged;
    });
    
    try {
      if (_isReblogged) {
        await timelineService.reblogStatus(widget.domain, _status.id);
      } else {
        await timelineService.unreblogStatus(widget.domain, _status.id);
      }
      
      if (widget.onReblogged != null) {
        widget.onReblogged!(_isReblogged);
      }
    } catch (e) {
      // Revert state if the API call fails
      if (mounted) {
        setState(() {
          _isReblogged = !_isReblogged;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isReblogged ? 'reblog' : 'unreblog'} post'),
            ),
          );
        }
      }
    }
  }
  
  /// Toggle bookmark status
  Future<void> _toggleBookmark() async {
    final timelineService = ref.read(timelineServiceProvider);
    
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    try {
      if (_isBookmarked) {
        await timelineService.bookmarkStatus(widget.domain, _status.id);
      } else {
        await timelineService.unbookmarkStatus(widget.domain, _status.id);
      }
      
      if (widget.onBookmarked != null) {
        widget.onBookmarked!(_isBookmarked);
      }
    } catch (e) {
      // Revert state if the API call fails
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isBookmarked ? 'bookmark' : 'unbookmark'} post'),
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReblog = widget.status.rebloggedStatus != null;
    final isIOS = Platform.isIOS;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isIOS ? 0 : 8,
        vertical: isIOS ? 0 : 4,
      ),
      decoration: BoxDecoration(
        color: isIOS
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : theme.colorScheme.surface,
        borderRadius: isIOS ? null : BorderRadius.circular(8),
        border: isIOS
            ? Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: isIOS ? null : BorderRadius.circular(8),
          onTap: widget.showFullContent ? null : () {
            if (_status.id.isNotEmpty) {
              context.push('/status/${_status.id}');
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isIOS ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reblog header
                if (isReblog) ...[
                  _buildReblogHeader(context, theme, isIOS, widget.status),
                  SizedBox(height: isIOS ? 8 : 12),
                ],

                // Post header
                _buildPostHeader(context, theme, isIOS, _status, widget.domain),

                // Content
                SizedBox(height: isIOS ? 8 : 12),

                // Content warning
                if (_status.spoilerText != null && _status.spoilerText!.isNotEmpty) ...[
                  _buildContentWarning(context, theme, isIOS, _status, _isExpanded, () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }),
                  SizedBox(height: isIOS ? 8 : 12),
                ],

                // Post content
                if (_isExpanded || (_status.spoilerText?.isEmpty ?? true)) ...[
                  _buildPostContent(context, theme, isIOS, _status),
                ],

                // Media attachments
                if (_status.mediaAttachments.isNotEmpty && (_isExpanded || (_status.spoilerText?.isEmpty ?? true))) ...[
                  SizedBox(height: isIOS ? 8 : 12),
                  _buildMediaGallery(context, theme, isIOS, _status),
                ],

                // Action buttons
                SizedBox(height: isIOS ? 12 : 16),
                _buildActionButtons(context, theme, isIOS, _status, _isLiked, _isReblogged, _isBookmarked, _toggleLike, _toggleReblog, _toggleBookmark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build reblog header with platform-specific styling
  Widget _buildReblogHeader(BuildContext context, ThemeData theme, bool isIOS, Status status) {
    final reblogAccount = status.account;
    final reblogIcon = isIOS ? CupertinoIcons.repeat : Icons.repeat;
    final textColor = isIOS
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          reblogIcon,
          size: isIOS ? 14 : 16,
          color: textColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "${reblogAccount?.displayName ?? 'Someone'} boosted",
            style: isIOS
                ? TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build post header with user info and timestamp
  Widget _buildPostHeader(BuildContext context, ThemeData theme, bool isIOS, Status status, String domain) {
    final account = status.account;
    final avatarSize = isIOS ? 48.0 : 52.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            final id = status.account?.id ?? '';
            if (id.isNotEmpty) {
              context.push('/profile/$id');
            }
          },
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isIOS
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipOval(
              child: account?.avatar != null
                  ? CachedNetworkImage(
                      imageUrl: account!.avatar!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isIOS
                            ? CupertinoColors.systemGrey5.resolveFrom(context)
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            (account.displayName.isNotEmpty ? account.displayName : 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: isIOS ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: isIOS
                                  ? CupertinoColors.label.resolveFrom(context)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isIOS
                            ? CupertinoColors.systemGrey5.resolveFrom(context)
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            (account.displayName.isNotEmpty ? account.displayName : 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: isIOS ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: isIOS
                                  ? CupertinoColors.label.resolveFrom(context)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        () {
                          final displayName = account?.displayName;
                          if (displayName != null && displayName.isNotEmpty) {
                            return displayName.substring(0, 1).toUpperCase();
                          }
                          return 'U';
                        }(),
                        style: TextStyle(
                          fontSize: isIOS ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: isIOS
                              ? CupertinoColors.label.resolveFrom(context)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // User info and content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display name
              GestureDetector(
                onTap: () {
                  final id = status.account?.id ?? '';
                  if (id.isNotEmpty) {
                    context.push('/profile/$id');
                  }
                },
                child: Text(
                  account?.displayName ?? 'Unknown User',
                  style: isIOS
                      ? TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        )
                      : theme.textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 2),

              // Handle row
              GestureDetector(
                onTap: () {
                  final id = status.account?.id ?? '';
                  if (id.isNotEmpty) {
                    context.push('/profile/$id');
                  }
                },
                child: Text(
                  AccountUtils.formatHandle(
                    acct: account?.acct ?? '',
                    username: account?.username,
                    accountDomain: account?.domain,
                    fallbackDomain: domain,
                  ),
                  style: isIOS
                      ? TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Timestamp
        Text(
          timeago.format(status.createdAt ?? DateTime.now()),
          style: isIOS
              ? TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),

        const SizedBox(width: 8),

        // More button
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // TODO: Show post options
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isIOS ? CupertinoIcons.ellipsis : Icons.more_vert,
                size: isIOS ? 16 : 20,
                color: isIOS
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build content warning section
  Widget _buildContentWarning(BuildContext context, ThemeData theme, bool isIOS, Status status, bool isExpanded, VoidCallback onToggle) {
    return Container(
      padding: EdgeInsets.all(isIOS ? 10 : 12),
      decoration: BoxDecoration(
        color: isIOS
            ? CupertinoColors.systemYellow.resolveFrom(context).withOpacity(0.1)
            : theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
        border: isIOS
            ? Border.all(
                color: CupertinoColors.systemYellow.resolveFrom(context).withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.warning_amber_rounded,
                color: isIOS
                    ? CupertinoColors.systemYellow.resolveFrom(context)
                    : theme.colorScheme.error,
                size: isIOS ? 16 : 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.spoilerText!,
                  style: isIOS
                      ? TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        )
                      : theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(isIOS ? 6 : 8),
              onTap: onToggle,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isIOS ? 12 : 16,
                  vertical: isIOS ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: isIOS
                      ? CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isIOS ? 6 : 8),
                ),
                child: Text(
                  isExpanded ? 'Hide' : 'Show more',
                  style: isIOS
                      ? TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        )
                      : theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build post content
  Widget _buildPostContent(BuildContext context, ThemeData theme, bool isIOS, Status status) {
    return SafeHtmlWidget(
      htmlContent: status.content,
      onLinkTap: (url) => LinkTapHandler.handleLinkTap(context, url, mentions: status.mentions),
    );
  }

  /// Build media gallery
  Widget _buildMediaGallery(BuildContext context, ThemeData theme, bool isIOS, Status status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
      child: MediaGallery(
        attachments: status.mediaAttachments,
        sensitive: status.sensitive,
        onTap: (index) {
          final images = status.mediaAttachments
              .where((a) => a.type == AttachmentType.image || a.type == AttachmentType.gifv)
              .map((a) => a.url)
              .toList();
          if (images.isNotEmpty) {
            final initial = index.clamp(0, images.length - 1);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImageViewerScreen(
                  imageUrls: images,
                  initialIndex: initial,
                  heroTagPrefix: 'post_${status.id}',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Build action buttons with platform-specific styling
  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isIOS, Status status, bool isLiked, bool isReblogged, bool isBookmarked, VoidCallback toggleLike, VoidCallback toggleReblog, VoidCallback toggleBookmark) {
    final buttonSpacing = isIOS ? 24.0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reply button
        _buildActionButton(
          context: context,
          theme: theme,
          isIOS: isIOS,
          icon: isIOS ? CupertinoIcons.chat_bubble : Icons.chat_bubble_outline,
          activeIcon: isIOS ? CupertinoIcons.chat_bubble_fill : Icons.chat_bubble,
          count: status.repliesCount,
          isActive: false,
          onPressed: () => context.push('/status/${status.id}'),
        ),

        SizedBox(width: buttonSpacing),

        // Reblog button
        _buildActionButton(
          context: context,
          theme: theme,
          isIOS: isIOS,
          icon: isIOS ? CupertinoIcons.repeat : Icons.repeat,
          activeIcon: isIOS ? CupertinoIcons.repeat : Icons.repeat,
          count: status.reblogsCount,
          isActive: isReblogged,
          activeColor: isIOS ? CupertinoColors.systemGreen : Colors.green,
          onPressed: toggleReblog,
          key: Key('reblog_button_${status.id}'),
        ),

        SizedBox(width: buttonSpacing),

        // Like button
        _buildActionButton(
          context: context,
          theme: theme,
          isIOS: isIOS,
          icon: isIOS ? CupertinoIcons.heart : Icons.favorite_border,
          activeIcon: isIOS ? CupertinoIcons.heart_fill : Icons.favorite,
          count: status.favouritesCount,
          isActive: isLiked,
          activeColor: isIOS ? CupertinoColors.systemRed : Colors.red,
          onPressed: toggleLike,
          key: Key('like_button_${status.id}'),
        ),

        const Spacer(),

        // Bookmark button
        _buildActionButton(
          context: context,
          theme: theme,
          isIOS: isIOS,
          icon: isIOS ? CupertinoIcons.bookmark : Icons.bookmark_border,
          activeIcon: isIOS ? CupertinoIcons.bookmark_fill : Icons.bookmark,
          count: null,
          isActive: isBookmarked,
          activeColor: isIOS ? CupertinoColors.systemBlue : Colors.blue,
          onPressed: toggleBookmark,
          key: Key('bookmark_button_${status.id}'),
        ),

        const SizedBox(width: 8),

        // Share button
        _buildActionButton(
          context: context,
          theme: theme,
          isIOS: isIOS,
          icon: isIOS ? CupertinoIcons.share : Icons.share_outlined,
          activeIcon: isIOS ? CupertinoIcons.share : Icons.share,
          count: null,
          isActive: false,
          onPressed: () {
            // TODO: Share post
          },
        ),
      ],
    );
  }

  /// Build an action button with platform-specific styling
  Widget _buildActionButton({
    required BuildContext context,
    required ThemeData theme,
    required bool isIOS,
    required IconData icon,
    required IconData activeIcon,
    required int? count,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onPressed,
    Key? key,
  }) {
    final buttonColor = isActive
        ? activeColor
        : (isIOS
            ? CupertinoColors.secondaryLabel.resolveFrom(context)
            : theme.colorScheme.onSurfaceVariant);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: key,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isIOS ? 16 : 20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isIOS ? 6 : 8,
            vertical: isIOS ? 6 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: isIOS ? 18 : 20,
                color: buttonColor,
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  _formatCount(count),
                  style: isIOS
                      ? TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: buttonColor,
                        )
                      : theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: buttonColor,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Format count numbers (e.g., 1.2K, 3.4M)
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final k = count / 1000;
      return k == k.roundToDouble() ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = count / 1000000;
    return m == m.roundToDouble() ? '${m.round()}M' : '${m.toStringAsFixed(1)}M';
  }
}
