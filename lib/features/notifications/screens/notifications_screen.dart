import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/notification.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pixelodon/widgets/common/safe_html_widget.dart';

/// Provider for notifications
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  
  return NotificationsNotifier(
    notificationService: notificationService,
    domain: activeInstance?.domain,
  );
});

/// State for notifications
class NotificationsState {
  final List<model.Notification> notifications;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;
  final List<model.NotificationType> excludeTypes;
  
  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
    this.excludeTypes = const [],
  });
  
  NotificationsState copyWith({
    List<model.Notification>? notifications,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
    List<model.NotificationType>? excludeTypes,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
      excludeTypes: excludeTypes ?? this.excludeTypes,
    );
  }
}

/// Notifier for notifications
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _notificationService;
  final String? domain;
  
  NotificationsNotifier({
    required NotificationService notificationService,
    this.domain,
  }) : _notificationService = notificationService,
       super(NotificationsState()) {
    if (domain != null) {
      loadNotifications();
    }
  }
  
  /// Set notification filters
  void setFilters({
    List<model.NotificationType>? excludeTypes,
  }) {
    state = state.copyWith(
      excludeTypes: excludeTypes,
    );
    
    loadNotifications();
  }
  
  /// Load notifications
  Future<void> loadNotifications() async {
    if (domain == null) return;
    
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );
    
    try {
      final notifications = await _notificationService.getNotifications(
        domain!,
        limit: 20,
        excludeTypes: state.excludeTypes,
      );
      
      String? maxId;
      if (notifications.isNotEmpty) {
        maxId = notifications.last.id;
      }
      
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        hasMore: notifications.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }
  
  /// Refresh notifications
  Future<void> refreshNotifications() async {
    if (domain == null) return;
    
    try {
      final notifications = await _notificationService.getNotifications(
        domain!,
        limit: 20,
        excludeTypes: state.excludeTypes,
      );
      
      String? maxId;
      if (notifications.isNotEmpty) {
        maxId = notifications.last.id;
      }
      
      state = state.copyWith(
        notifications: notifications,
        hasMore: notifications.length >= 20,
        maxId: maxId,
        hasError: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to refresh notifications: $e',
      );
    }
  }
  
  /// Load more notifications
  Future<void> loadMoreNotifications() async {
    if (domain == null || state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(
      isLoading: true,
    );
    
    try {
      final notifications = await _notificationService.getNotifications(
        domain!,
        limit: 20,
        maxId: state.maxId,
        excludeTypes: state.excludeTypes,
      );
      
      String? maxId;
      if (notifications.isNotEmpty) {
        maxId = notifications.last.id;
      }
      
      state = state.copyWith(
        notifications: [...state.notifications, ...notifications],
        isLoading: false,
        hasMore: notifications.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load more notifications: $e',
      );
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (domain == null) return;
    
    try {
      await _notificationService.markNotificationsAsRead(domain!);
      
      // Update local state to reflect the change
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(read: true);
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to mark notifications as read: $e',
      );
    }
  }
  
}

/// Screen for displaying notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  /// Constructor
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
  
  /// Handle scroll events to load more notifications
  void _onScroll() {
    final notificationsState = ref.read(notificationsProvider);
    final notificationsNotifier = ref.read(notificationsProvider.notifier);
    
    if (notificationsState.hasMore && !notificationsState.isLoading) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Load more when user scrolls to 80% of the list
      if (currentScroll >= maxScroll * 0.8) {
        notificationsNotifier.loadMoreNotifications();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final notificationsNotifier = ref.read(notificationsProvider.notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    
    if (activeInstance == null) {
      return const Center(
        child: Text('No active instance selected'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, notificationsState, notificationsNotifier);
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              notificationsNotifier.markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsState.hasError
          ? Center(
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
                    notificationsState.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: notificationsNotifier.loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : notificationsState.notifications.isEmpty
              ? notificationsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : const Center(
                      child: Text('No notifications'),
                    )
              : RefreshIndicator(
                  onRefresh: notificationsNotifier.refreshNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notificationsState.notifications.length + (notificationsState.isLoading && notificationsState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == notificationsState.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final notification = notificationsState.notifications[index];
                      
                      return _buildNotificationItem(context, notification);
                    },
                  ),
                ),
    );
  }
  
  /// Build a notification item
  Widget _buildNotificationItem(BuildContext context, model.Notification notification) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          if (notification.status != null) {
            // TODO: Navigate to status detail
          } else if (notification.type == model.NotificationType.follow) {
            context.push('/profile/${notification.account.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification header
              Row(
                children: [
                  // Notification icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Notification text
                  Expanded(
                    child: Text(
                      _getNotificationText(notification),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Notification time
                  Text(
                    timeago.format(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Account info
              const SizedBox(height: 8),
              Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => context.push('/profile/${notification.account.id}'),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: notification.account.avatar != null
                          ? CachedNetworkImageProvider(notification.account.avatar!)
                          : null,
                      child: notification.account.avatar == null
                          ? Text(notification.account.displayName[0])
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Account name
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/profile/${notification.account.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.account.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${notification.account.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Status content
              if (notification.status != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text/content on the left
                    Expanded(
                      child: SafeHtmlWidget(
                        htmlContent: notification.status!.content,
                      ),
                    ),
                    // Thumbnail preview on the right (first media only)
                    if (notification.status!.mediaAttachments.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: CachedNetworkImage(
                            imageUrl: notification.status!.mediaAttachments.first.previewUrl
                                    ?? notification.status!.mediaAttachments.first.url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get the notification icon
  IconData _getNotificationIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.follow:
        return Icons.person_add;
      case model.NotificationType.followRequest:
        return Icons.person_add_alt;
      case model.NotificationType.mention:
        return Icons.alternate_email;
      case model.NotificationType.reblog:
        return Icons.repeat;
      case model.NotificationType.favourite:
        return Icons.favorite;
      case model.NotificationType.poll:
        return Icons.poll;
      case model.NotificationType.status:
        return Icons.post_add;
      case model.NotificationType.update:
        return Icons.update;
      case model.NotificationType.adminSignUp:
        return Icons.admin_panel_settings;
      case model.NotificationType.adminReport:
        return Icons.report;
      case model.NotificationType.comment:
        return Icons.comment;
      case model.NotificationType.like:
        return Icons.thumb_up;
      case model.NotificationType.share:
        return Icons.share;
      case model.NotificationType.storyReaction:
        return Icons.emoji_emotions;
      case model.NotificationType.storyMention:
        return Icons.photo_camera;
      case model.NotificationType.direct:
        return Icons.mail;
      default:
        return Icons.notifications;
    }
  }
  
  /// Get the notification color
  Color _getNotificationColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.follow:
      case model.NotificationType.followRequest:
        return Colors.blue;
      case model.NotificationType.mention:
      case model.NotificationType.comment:
        return Colors.purple;
      case model.NotificationType.reblog:
      case model.NotificationType.share:
        return Colors.green;
      case model.NotificationType.favourite:
      case model.NotificationType.like:
        return Colors.red;
      case model.NotificationType.poll:
        return Colors.orange;
      case model.NotificationType.storyReaction:
      case model.NotificationType.storyMention:
        return Colors.pink;
      case model.NotificationType.direct:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
  
  /// Get the notification text
  String _getNotificationText(model.Notification notification) {
    switch (notification.type) {
      case model.NotificationType.follow:
        return 'followed you';
      case model.NotificationType.followRequest:
        return 'requested to follow you';
      case model.NotificationType.mention:
        return 'mentioned you';
      case model.NotificationType.reblog:
        return 'boosted your post';
      case model.NotificationType.favourite:
        return 'favorited your post';
      case model.NotificationType.poll:
        return 'poll has ended';
      case model.NotificationType.status:
        return 'posted a status';
      case model.NotificationType.update:
        return 'updated their post';
      case model.NotificationType.comment:
        return 'commented on your post';
      case model.NotificationType.like:
        return 'liked your post';
      case model.NotificationType.share:
        return 'shared your post';
      case model.NotificationType.storyReaction:
        return 'reacted to your story';
      case model.NotificationType.storyMention:
        return 'mentioned you in a story';
      case model.NotificationType.direct:
        return 'sent you a direct message';
      default:
        return 'sent you a notification';
    }
  }
  
  /// Show filter dialog
  void _showFilterDialog(
    BuildContext context,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    final excludeTypes = List<model.NotificationType>.from(state.excludeTypes);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Notifications'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterCheckbox(
                      context,
                      'Follows',
                      model.NotificationType.follow,
                      excludeTypes,
                      (value) {
                        setState(() {
                          if (value!) {
                            excludeTypes.add(model.NotificationType.follow);
                          } else {
                            excludeTypes.remove(model.NotificationType.follow);
                          }
                        });
                      },
                    ),
                    _buildFilterCheckbox(
                      context,
                      'Mentions',
                      model.NotificationType.mention,
                      excludeTypes,
                      (value) {
                        setState(() {
                          if (value!) {
                            excludeTypes.add(model.NotificationType.mention);
                          } else {
                            excludeTypes.remove(model.NotificationType.mention);
                          }
                        });
                      },
                    ),
                    _buildFilterCheckbox(
                      context,
                      'Boosts',
                      model.NotificationType.reblog,
                      excludeTypes,
                      (value) {
                        setState(() {
                          if (value!) {
                            excludeTypes.add(model.NotificationType.reblog);
                          } else {
                            excludeTypes.remove(model.NotificationType.reblog);
                          }
                        });
                      },
                    ),
                    _buildFilterCheckbox(
                      context,
                      'Favorites',
                      model.NotificationType.favourite,
                      excludeTypes,
                      (value) {
                        setState(() {
                          if (value!) {
                            excludeTypes.add(model.NotificationType.favourite);
                          } else {
                            excludeTypes.remove(model.NotificationType.favourite);
                          }
                        });
                      },
                    ),
                    _buildFilterCheckbox(
                      context,
                      'Polls',
                      model.NotificationType.poll,
                      excludeTypes,
                      (value) {
                        setState(() {
                          if (value!) {
                            excludeTypes.add(model.NotificationType.poll);
                          } else {
                            excludeTypes.remove(model.NotificationType.poll);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    notifier.setFilters(excludeTypes: excludeTypes);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  /// Build a filter checkbox
  Widget _buildFilterCheckbox(
    BuildContext context,
    String label,
    model.NotificationType type,
    List<model.NotificationType> excludeTypes,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: excludeTypes.contains(type),
      onChanged: onChanged,
      dense: true,
    );
  }
}
