import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:pixelodon/models/notification.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/core/theme/app_theme.dart';

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
      return _buildNoInstanceScaffold(context);
    }

    // Use platform-specific scaffold similar to Home screen
    if (Platform.isIOS) {
      return _buildIOSScaffold(context, notificationsState, notificationsNotifier);
    } else {
      return _buildMaterialScaffold(context, notificationsState, notificationsNotifier);
    }
  }

  /// Build scaffold when no instance is selected
  Widget _buildNoInstanceScaffold(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Notifications'),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: AppTheme.pageBg(context),
            child: const Center(
              child: Text('No active instance selected'),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: Container(
          color: AppTheme.pageBg(context),
          child: const Center(
            child: Text('No active instance selected'),
          ),
        ),
      );
    }
  }

  /// Build iOS-style scaffold with CupertinoNavigationBar
  Widget _buildIOSScaffold(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier) {
    return CupertinoPageScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Navigation bar with title and actions
            CupertinoNavigationBar(
              middle: const Text('Notifications'),
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
              trailing: _buildIOSActions(context, notificationsState, notificationsNotifier),
            ),
            // Content
            Expanded(
              child: _buildNotificationsList(context, notificationsState, notificationsNotifier, isIOS: true),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar
  Widget _buildMaterialScaffold(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar.medium(
                title: const Text('Notifications'),
                pinned: true,
                actions: _buildMaterialActions(context, notificationsState, notificationsNotifier),
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            // Try to get the overlap handle, but handle the case where NestedScrollView isn't available yet
            SliverOverlapAbsorberHandle? overlapHandle;
            try {
              overlapHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
            } catch (e) {
              // NestedScrollView not available in this context, use null
              overlapHandle = null;
            }

            return _buildNotificationsList(context, notificationsState, notificationsNotifier, isIOS: false, useSliver: true, overlapHandle: overlapHandle);
          },
        ),
      ),
    );
  }

  /// Build iOS-style action buttons
  Widget _buildIOSActions(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(0),
          minSize: 0,
          onPressed: () => _showFilterSelector(context, notificationsState, notificationsNotifier, isIOS: true),
          child: Icon(
            CupertinoIcons.line_horizontal_3_decrease,
            color: CupertinoColors.activeBlue.resolveFrom(context),
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.all(0),
          minSize: 0,
          onPressed: () => _showMarkAsReadConfirmation(context, notificationsNotifier, isIOS: true),
          child: Icon(
            CupertinoIcons.checkmark_alt,
            color: CupertinoColors.activeBlue.resolveFrom(context),
            size: 22,
          ),
        ),
      ],
    );
  }

  /// Build Material-style action buttons
  List<Widget> _buildMaterialActions(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier) {
    return [
      IconButton(
        onPressed: () => _showFilterSelector(context, notificationsState, notificationsNotifier, isIOS: false),
        icon: const Icon(Icons.filter_list),
        tooltip: 'Filter notifications',
      ),
      IconButton(
        onPressed: () => _showMarkAsReadConfirmation(context, notificationsNotifier, isIOS: false),
        icon: const Icon(Icons.done_all),
        tooltip: 'Mark all as read',
      ),
    ];
  }

  /// Build notifications list content
  Widget _buildNotificationsList(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier, {required bool isIOS, bool useSliver = false, SliverOverlapAbsorberHandle? overlapHandle}) {
    if (notificationsState.hasError) {
      return _buildErrorState(context, notificationsState, notificationsNotifier, isIOS: isIOS);
    }

    if (notificationsState.notifications.isEmpty) {
      if (notificationsState.isLoading) {
        return _buildLoadingState(context, isIOS: isIOS);
      } else {
        return _buildEmptyState(context, isIOS: isIOS);
      }
    }

    if (isIOS) {
      return CupertinoScrollbar(
        child: RefreshIndicator(
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
                    child: CupertinoActivityIndicator(),
                  ),
                );
              }

              final notification = notificationsState.notifications[index];
              return _buildNotificationItem(context, notification);
            },
          ),
        ),
      );
    } else {
      if (useSliver) {
        // Return CustomScrollView with slivers for proper nested scroll view integration
        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (overlapHandle != null)
              SliverOverlapInjector(handle: overlapHandle),
            CupertinoSliverRefreshControl(
              onRefresh: notificationsNotifier.refreshNotifications,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: notificationsState.notifications.length + (notificationsState.isLoading && notificationsState.hasMore ? 1 : 0),
              ),
            ),
          ],
        );
      } else {
        return RefreshIndicator(
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
        );
      }
    }
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, NotificationsState notificationsState, NotificationsNotifier notificationsNotifier, {required bool isIOS}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
            size: 48,
            color: isIOS ? CupertinoColors.systemRed : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            notificationsState.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isIOS)
            CupertinoButton.filled(
              onPressed: notificationsNotifier.loadNotifications,
              child: const Text('Retry'),
            )
          else
            ElevatedButton(
              onPressed: notificationsNotifier.loadNotifications,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context, {required bool isIOS}) {
    return Center(
      child: isIOS ? const CupertinoActivityIndicator() : const CircularProgressIndicator(),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context, {required bool isIOS}) {
    return const Center(
      child: Text('No notifications'),
    );
  }

  /// Build a notification item
  Widget _buildNotificationItem(BuildContext context, model.Notification notification) {
    final theme = Theme.of(context);

    if (Platform.isIOS) {
      return _buildIOSNotificationItem(context, notification, theme);
    } else {
      return _buildMaterialNotificationItem(context, notification, theme);
    }
  }

  /// Build iOS-style notification item
  Widget _buildIOSNotificationItem(BuildContext context, model.Notification notification, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (notification.status != null) {
            // TODO: Navigate to status detail
          } else if (notification.type == model.NotificationType.follow) {
            context.push('/profile/${notification.account.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

  /// Build Material-style notification item
  Widget _buildMaterialNotificationItem(BuildContext context, model.Notification notification, ThemeData theme) {
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
  
  /// Show mark as read confirmation
  void _showMarkAsReadConfirmation(BuildContext context, NotificationsNotifier notifier, {required bool isIOS}) {
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Mark All as Read'),
          content: const Text('Are you sure you want to mark all notifications as read?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: false,
              onPressed: () {
                Navigator.of(context).pop();
                notifier.markAllAsRead();
              },
              child: const Text('Mark as Read'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark All as Read'),
          content: const Text('Are you sure you want to mark all notifications as read?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.markAllAsRead();
              },
              child: const Text('Mark as Read'),
            ),
          ],
        ),
      );
    }
  }

  /// Show filter selector
  void _showFilterSelector(BuildContext context, NotificationsState state, NotificationsNotifier notifier, {required bool isIOS}) {
    final excludeTypes = List<model.NotificationType>.from(state.excludeTypes);

    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => _buildIOSFilterSheet(context, excludeTypes, notifier),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _buildMaterialFilterSheet(context, excludeTypes, notifier),
      );
    }
  }

  /// Build iOS-style filter sheet
  Widget _buildIOSFilterSheet(BuildContext context, List<model.NotificationType> excludeTypes, NotificationsNotifier notifier) {
    return StatefulBuilder(
      builder: (context, setState) {
        return CupertinoActionSheet(
          title: const Text('Filter Notifications'),
          message: const Text('Hide notification types'),
          actions: [
            _buildIOSFilterOption(
              context,
              'Follows',
              model.NotificationType.follow,
              excludeTypes,
              (value) {
                setState(() {
                  if (value) {
                    excludeTypes.add(model.NotificationType.follow);
                  } else {
                    excludeTypes.remove(model.NotificationType.follow);
                  }
                });
              },
            ),
            _buildIOSFilterOption(
              context,
              'Mentions',
              model.NotificationType.mention,
              excludeTypes,
              (value) {
                setState(() {
                  if (value) {
                    excludeTypes.add(model.NotificationType.mention);
                  } else {
                    excludeTypes.remove(model.NotificationType.mention);
                  }
                });
              },
            ),
            _buildIOSFilterOption(
              context,
              'Boosts',
              model.NotificationType.reblog,
              excludeTypes,
              (value) {
                setState(() {
                  if (value) {
                    excludeTypes.add(model.NotificationType.reblog);
                  } else {
                    excludeTypes.remove(model.NotificationType.reblog);
                  }
                });
              },
            ),
            _buildIOSFilterOption(
              context,
              'Favorites',
              model.NotificationType.favourite,
              excludeTypes,
              (value) {
                setState(() {
                  if (value) {
                    excludeTypes.add(model.NotificationType.favourite);
                  } else {
                    excludeTypes.remove(model.NotificationType.favourite);
                  }
                });
              },
            ),
            _buildIOSFilterOption(
              context,
              'Polls',
              model.NotificationType.poll,
              excludeTypes,
              (value) {
                setState(() {
                  if (value) {
                    excludeTypes.add(model.NotificationType.poll);
                  } else {
                    excludeTypes.remove(model.NotificationType.poll);
                  }
                });
              },
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.setFilters(excludeTypes: excludeTypes);
              },
              child: const Text('Apply Filters'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  /// Build Material-style filter sheet
  Widget _buildMaterialFilterSheet(BuildContext context, List<model.NotificationType> excludeTypes, NotificationsNotifier notifier) {
    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Notifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            notifier.setFilters(excludeTypes: excludeTypes);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Filter options
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildMaterialFilterOption(
                          context,
                          'Follows',
                          model.NotificationType.follow,
                          excludeTypes,
                          (value) {
                            setState(() {
                              if (value) {
                                excludeTypes.add(model.NotificationType.follow);
                              } else {
                                excludeTypes.remove(model.NotificationType.follow);
                              }
                            });
                          },
                        ),
                        _buildMaterialFilterOption(
                          context,
                          'Mentions',
                          model.NotificationType.mention,
                          excludeTypes,
                          (value) {
                            setState(() {
                              if (value) {
                                excludeTypes.add(model.NotificationType.mention);
                              } else {
                                excludeTypes.remove(model.NotificationType.mention);
                              }
                            });
                          },
                        ),
                        _buildMaterialFilterOption(
                          context,
                          'Boosts',
                          model.NotificationType.reblog,
                          excludeTypes,
                          (value) {
                            setState(() {
                              if (value) {
                                excludeTypes.add(model.NotificationType.reblog);
                              } else {
                                excludeTypes.remove(model.NotificationType.reblog);
                              }
                            });
                          },
                        ),
                        _buildMaterialFilterOption(
                          context,
                          'Favorites',
                          model.NotificationType.favourite,
                          excludeTypes,
                          (value) {
                            setState(() {
                              if (value) {
                                excludeTypes.add(model.NotificationType.favourite);
                              } else {
                                excludeTypes.remove(model.NotificationType.favourite);
                              }
                            });
                          },
                        ),
                        _buildMaterialFilterOption(
                          context,
                          'Polls',
                          model.NotificationType.poll,
                          excludeTypes,
                          (value) {
                            setState(() {
                              if (value) {
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build iOS filter option
  Widget _buildIOSFilterOption(
    BuildContext context,
    String label,
    model.NotificationType type,
    List<model.NotificationType> excludeTypes,
    Function(bool) onChanged,
  ) {
    final isExcluded = excludeTypes.contains(type);
    return CupertinoActionSheetAction(
      onPressed: () => onChanged(!isExcluded),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (isExcluded)
            const Icon(CupertinoIcons.checkmark, size: 16),
        ],
      ),
    );
  }

  /// Build Material filter option
  Widget _buildMaterialFilterOption(
    BuildContext context,
    String label,
    model.NotificationType type,
    List<model.NotificationType> excludeTypes,
    Function(bool) onChanged,
  ) {
    final isExcluded = excludeTypes.contains(type);
    return CheckboxListTile(
      title: Text(label),
      subtitle: Text('Hide $label notifications'),
      value: isExcluded,
      onChanged: (value) => onChanged(value ?? false),
      dense: true,
    );
  }
}
