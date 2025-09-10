import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';
import 'dart:io';

/// Widget for displaying a post with focus on images in images-only mode
class ImagePostCard extends ConsumerStatefulWidget {
  final Status status;
  final String domain;
  final Function(bool liked)? onLiked;
  final Function(bool reblogged)? onReblogged;
  final Function(bool bookmarked)? onBookmarked;

  const ImagePostCard({
    super.key,
    required this.status,
    required this.domain,
    this.onLiked,
    this.onReblogged,
    this.onBookmarked,
  });

  @override
  ConsumerState<ImagePostCard> createState() => _ImagePostCardState();
}

class _ImagePostCardState extends ConsumerState<ImagePostCard> {
  late Status _status;
  bool _isLiked = false;
  bool _isReblogged = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _status = widget.status.rebloggedStatus ?? widget.status;
    _isLiked = _status.favourited;
    _isReblogged = _status.reblogged;
    _isBookmarked = _status.bookmarked;
  }

  @override
  void didUpdateWidget(ImagePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _status = widget.status.rebloggedStatus ?? widget.status;
      _isLiked = _status.favourited;
      _isReblogged = _status.reblogged;
      _isBookmarked = _status.bookmarked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;
    final isReblog = widget.status.rebloggedStatus != null;

    // Get the first image from media attachments
    final imageMedia = _status.mediaAttachments.firstWhere(
      (media) => media.type == AttachmentType.image || media.type == AttachmentType.gifv,
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        decoration: BoxDecoration(
          color: isIOS 
              ? CupertinoColors.systemBackground.resolveFrom(context)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isIOS ? 10 : 12),
          border: isIOS 
              ? Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                )
              : null,
          boxShadow: isIOS 
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reblog header (if applicable)
            if (isReblog) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      isIOS ? CupertinoIcons.repeat : Icons.repeat,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.status.account?.displayName ?? 'Someone'} boosted',
                      style: (isIOS 
                          ? CupertinoTheme.of(context).textTheme.textStyle
                          : theme.textTheme.bodySmall)?.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // User info header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      final id = _status.account?.id ?? '';
                      if (id.isNotEmpty) {
                        context.push('/profile/$id');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isIOS
                            ? CupertinoColors.systemGrey5.resolveFrom(context)
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: ClipOval(
                        child: _status.account?.avatar != null
                            ? Image.network(
                                _status.account!.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    isIOS ? CupertinoIcons.person_fill : Icons.person,
                                    color: Colors.grey,
                                    size: 20,
                                  );
                                },
                              )
                            : Icon(
                                isIOS ? CupertinoIcons.person_fill : Icons.person,
                                color: Colors.grey,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status.account?.displayName ?? 'Unknown User',
                          style: (isIOS 
                              ? CupertinoTheme.of(context).textTheme.textStyle
                              : theme.textTheme.titleSmall)?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${_status.account?.username ?? 'unknown'}@${widget.domain}',
                          style: (isIOS 
                              ? CupertinoTheme.of(context).textTheme.textStyle
                              : theme.textTheme.bodySmall)?.copyWith(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Image
            GestureDetector(
              onTap: () {
                context.push('/status/${_status.id}');
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 400,
                  minHeight: 200,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageMedia.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      ),
                      
                      // Multiple images indicator
                      if (_status.mediaAttachments.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_status.mediaAttachments.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // GIF indicator
                      if (imageMedia.type == AttachmentType.gifv)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'GIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context,
                    icon: isIOS ? CupertinoIcons.chat_bubble : Icons.chat_bubble_outline,
                    count: _status.repliesCount,
                    onTap: () {
                      context.push('/status/${_status.id}');
                    },
                    isIOS: isIOS,
                  ),
                  _buildActionButton(
                    context,
                    icon: isIOS ? CupertinoIcons.repeat : Icons.repeat,
                    count: _status.reblogsCount,
                    isActive: _isReblogged,
                    onTap: () {
                      setState(() {
                        _isReblogged = !_isReblogged;
                      });
                      widget.onReblogged?.call(_isReblogged);
                    },
                    isIOS: isIOS,
                  ),
                  _buildActionButton(
                    context,
                    icon: isIOS ? CupertinoIcons.heart : Icons.favorite_border,
                    activeIcon: isIOS ? CupertinoIcons.heart_fill : Icons.favorite,
                    count: _status.favouritesCount,
                    isActive: _isLiked,
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                      });
                      widget.onLiked?.call(_isLiked);
                    },
                    isIOS: isIOS,
                  ),
                  _buildActionButton(
                    context,
                    icon: isIOS ? CupertinoIcons.bookmark : Icons.bookmark_border,
                    activeIcon: isIOS ? CupertinoIcons.bookmark_fill : Icons.bookmark,
                    isActive: _isBookmarked,
                    onTap: () {
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });
                      widget.onBookmarked?.call(_isBookmarked);
                    },
                    isIOS: isIOS,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    IconData? activeIcon,
    int? count,
    bool isActive = false,
    required VoidCallback onTap,
    required bool isIOS,
  }) {
    final theme = Theme.of(context);
    final displayIcon = isActive && activeIcon != null ? activeIcon : icon;
    final color = isActive 
        ? (isIOS ? CupertinoColors.systemRed : theme.colorScheme.primary)
        : (isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : theme.colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              displayIcon,
              size: 20,
              color: color,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: (isIOS 
                    ? CupertinoTheme.of(context).textTheme.textStyle
                    : theme.textTheme.bodySmall)?.copyWith(
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
