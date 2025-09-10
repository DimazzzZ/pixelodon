import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'dart:io';

/// Screen that displays a list of users (for boosts, likes, etc.)
class UserListScreen extends ConsumerStatefulWidget {
  final String statusId;
  final UserListType type;
  final String title;

  const UserListScreen({
    super.key,
    required this.statusId,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final List<Account> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _maxId;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _users.clear();
        _maxId = null;
        _hasMore = true;
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final activeInstance = ref.read(activeInstanceProvider);
      if (activeInstance == null) {
        throw Exception('No active instance');
      }

      final timelineService = ref.read(timelineServiceProvider);
      List<Account> newUsers;

      switch (widget.type) {
        case UserListType.boosts:
          newUsers = await timelineService.getStatusRebloggedBy(
            activeInstance.domain,
            widget.statusId,
            limit: 40,
            maxId: _maxId,
          );
          break;
        case UserListType.likes:
          newUsers = await timelineService.getStatusFavouritedBy(
            activeInstance.domain,
            widget.statusId,
            limit: 40,
            maxId: _maxId,
          );
          break;
      }

      setState(() {
        if (isRefresh) {
          _users.clear();
        }
        _users.addAll(newUsers);
        _hasMore = newUsers.length >= 40;
        _maxId = newUsers.isNotEmpty ? newUsers.last.id : null;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSScaffold();
    } else {
      return _buildMaterialScaffold();
    }
  }

  Widget _buildIOSScaffold() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildMaterialScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && _users.isEmpty) {
      return _buildErrorState();
    }

    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(isRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more trigger
          if (index >= _users.length - 3 && _hasMore && !_isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMore();
            });
          }

          if (index < _users.length) {
            return _UserListItem(
              user: _users[index],
              onTap: () => _navigateToProfile(_users[index]),
            );
          }

          // Loading indicator
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
            size: 64,
            color: Platform.isIOS 
                ? CupertinoColors.systemRed.resolveFrom(context)
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load users',
            style: Platform.isIOS
                ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Platform.isIOS
                  ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    )
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Platform.isIOS
              ? CupertinoButton.filled(
                  onPressed: () => _loadUsers(isRefresh: true),
                  child: const Text('Retry'),
                )
              : ElevatedButton(
                  onPressed: () => _loadUsers(isRefresh: true),
                  child: const Text('Retry'),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = widget.type == UserListType.boosts 
        ? 'No boosts yet'
        : 'No likes yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.type == UserListType.boosts 
                ? (Platform.isIOS ? CupertinoIcons.repeat : Icons.repeat)
                : (Platform.isIOS ? CupertinoIcons.heart : Icons.favorite),
            size: 64,
            color: Platform.isIOS 
                ? CupertinoColors.secondaryLabel.resolveFrom(context)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Platform.isIOS
                ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(Account user) {
    context.push('/profile/${user.id}', extra: {
      'username': user.username,
      'domain': user.acct.contains('@') ? user.acct.split('@').last : null,
    });
  }
}

/// Individual user list item
class _UserListItem extends StatelessWidget {
  final Account user;
  final VoidCallback? onTap;

  const _UserListItem({
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: user.avatar ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 40,
                    color: isIOS 
                        ? CupertinoColors.systemGrey5.resolveFrom(context)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      isIOS ? CupertinoIcons.person : Icons.person,
                      color: isIOS 
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 40,
                    color: isIOS 
                        ? CupertinoColors.systemGrey5.resolveFrom(context)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      isIOS ? CupertinoIcons.person : Icons.person,
                      color: isIOS 
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                      user.displayName.isNotEmpty ? user.displayName : user.username,
                      style: isIOS
                          ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.acct}',
                      style: isIOS
                          ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            )
                          : Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              Icon(
                isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
                color: isIOS 
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type of user list to display
enum UserListType {
  boosts,
  likes,
}
