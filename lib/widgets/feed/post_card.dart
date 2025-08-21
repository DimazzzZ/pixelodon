import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart' hide Card;
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/media_gallery.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          // Navigate to status details when tapping the card
          if (_status.id.isNotEmpty) {
            context.push('/status/${_status.id}');
          }
        },
        child: Material(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Reblog header
            if (isReblog) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.status.account?.displayName ?? 'Someone'} boosted",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Post header
            ListTile(
              leading: GestureDetector(
                onTap: () => context.push('/profile/${_status.account?.id ?? ''}'),
                child: CircleAvatar(
                  backgroundImage: _status.account?.avatar != null
                      ? CachedNetworkImageProvider(_status.account!.avatar!)
                      : null,
                  child: _status.account?.avatar == null
                      ? Text((_status.account?.displayName ?? 'User').isNotEmpty 
                          ? (_status.account?.displayName ?? 'User')[0] 
                          : 'U')
                      : null,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/profile/${_status.account?.id ?? ''}'),
                      child: Text(
                        _status.account?.displayName ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    '@${_status.account?.username ?? 'unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              subtitle: Text(
                timeago.format(_status.createdAt ?? DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: Show post options
                },
              ),
            ),
            
            // Content warning
            if (_status.spoilerText != null && _status.spoilerText!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.onErrorContainer,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status.spoilerText!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'Hide' : 'Show more',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
            
            // Post content
            if (_isExpanded || (_status.spoilerText?.isEmpty ?? true)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafeHtmlWidget(
                  htmlContent: _status.content,
                  onLinkTap: (url) {
                    // TODO: Handle link taps safely
                    if (url != null && Uri.tryParse(url) != null) {
                      // Could implement safe link handling here
                    }
                  },
                ),
              ),
            ],
            
            // Media attachments
            if (_status.mediaAttachments.isNotEmpty && (_isExpanded || (_status.spoilerText?.isEmpty ?? true))) ...[
              const SizedBox(height: 8),
              MediaGallery(
                attachments: _status.mediaAttachments,
                sensitive: _status.sensitive,
                onTap: (index) {
                  // TODO: Open media viewer
                },
              ),
            ],
            
            // Post stats
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatButton(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    count: _status.repliesCount,
                    isActive: false,
                    onPressed: () {
                      context.push('/status/${_status.id}');
                    },
                  ),
                  _buildStatButton(
                    icon: Icons.repeat,
                    activeIcon: Icons.repeat,
                    count: _status.reblogsCount,
                    isActive: _isReblogged,
                    activeColor: Colors.green,
                    onPressed: _toggleReblog,
                  ),
                  _buildStatButton(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    count: _status.favouritesCount,
                    isActive: _isLiked,
                    activeColor: Colors.red,
                    onPressed: _toggleLike,
                  ),
                  _buildStatButton(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    count: null,
                    isActive: _isBookmarked,
                    activeColor: Colors.blue,
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      // TODO: Share post
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
  
  /// Build a stat button with count
  Widget _buildStatButton({
    required IconData icon,
    required IconData activeIcon,
    required int? count,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? activeColor : null,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? activeColor : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
