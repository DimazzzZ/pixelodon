import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/utils/account_utils.dart';
import 'package:pixelodon/features/profile/widgets/follow_button.dart';

class CompactAccountTile extends ConsumerStatefulWidget {
  final Account account;
  final VoidCallback? onTap;
  final ValueChanged<Account>? onFollowChanged;

  const CompactAccountTile({super.key, required this.account, this.onTap, this.onFollowChanged});

  @override
  ConsumerState<CompactAccountTile> createState() => _CompactAccountTileState();
}

class _CompactAccountTileState extends ConsumerState<CompactAccountTile> {
  late Account _account;
  late Account _originalAccount; // For rollback on error
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _originalAccount = widget.account;
  }

  @override
  void didUpdateWidget(CompactAccountTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account != widget.account) {
      _account = widget.account;
      _originalAccount = widget.account;
    }
  }

  String _stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), '');
    return withoutTags.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
  }

  Future<void> _follow() async {
    final domain = ref.read(activeInstanceProvider)?.domain;
    if (domain == null) return;
    if (_isBusy) return;

    // Store current state for rollback
    _originalAccount = _account;
    
    // Optimistic update
    setState(() {
      _isBusy = true;
      _account = _account.copyWith(
        following: true,
        requested: false, // Assume follow succeeds immediately
      );
    });
    
    // Announce to screen readers
    _announceFollowStateChange('Following ${_account.username}');
    
    try {
      final accountService = ref.read(accountServiceProvider);
      final updated = await accountService.followAccount(domain, _account.id);
      
      if (mounted) {
        setState(() {
          _account = _account.copyWith(
            following: updated.following,
            requested: updated.requested,
            followersCount: updated.followersCount,
            followingCount: updated.followingCount,
          );
        });
        widget.onFollowChanged?.call(_account);
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _account = _originalAccount;
        });
        _announceFollowStateChange('Failed to follow ${_account.username}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow ${_account.username}: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _follow,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _unfollow() async {
    final domain = ref.read(activeInstanceProvider)?.domain;
    if (domain == null) return;
    if (_isBusy) return;

    // Store current state for rollback
    _originalAccount = _account;
    
    // Optimistic update
    setState(() {
      _isBusy = true;
      _account = _account.copyWith(
        following: false,
        requested: false,
      );
    });
    
    // Announce to screen readers
    _announceFollowStateChange('Unfollowed ${_account.username}');
    
    try {
      final accountService = ref.read(accountServiceProvider);
      final updated = await accountService.unfollowAccount(domain, _account.id);
      
      if (mounted) {
        setState(() {
          _account = _account.copyWith(
            following: updated.following,
            requested: updated.requested,
            followersCount: updated.followersCount,
            followingCount: updated.followingCount,
          );
        });
        widget.onFollowChanged?.call(_account);
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _account = _originalAccount;
        });
        _announceFollowStateChange('Failed to unfollow ${_account.username}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unfollow ${_account.username}: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _unfollow,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _announceFollowStateChange(String message) {
    // Announce state changes for accessibility
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Use SemanticsService to announce the change
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get formatted handle for accessibility
    final formattedHandle = AccountUtils.formatHandle(
      acct: _account.acct,
      username: _account.username,
      accountDomain: _account.domain,
      fallbackDomain: ref.read(activeInstanceProvider)?.domain,
    );
    
    return Semantics(
      label: 'User ${_account.displayName.isNotEmpty ? _account.displayName : _account.username}, $formattedHandle',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          // Cell padding 16px as per requirements
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar 44px (radius 22) as per requirements
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: _account.avatar != null && _account.avatar!.isNotEmpty
                        ? CachedNetworkImageProvider(_account.avatar!)
                        : null,
                    child: (_account.avatar == null || _account.avatar!.isEmpty)
                        ? Text(
                            _account.displayName.isNotEmpty 
                                ? _account.displayName[0].toUpperCase() 
                                : _account.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                  // Vertical spacing 8px as per requirements  
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary name (semibold) as per requirements
                        Text(
                          _account.displayName.isNotEmpty ? _account.displayName : _account.username,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600, // Semibold
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        // Handle (secondary) as per requirements
                        Text(
                          formattedHandle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant, // Secondary color
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Follow button - right aligned
                  FollowButton(
                    isCurrentUser: false,
                    isFollowing: _account.following,
                    isFollowRequestPending: _account.requested,
                    isLoading: _isBusy,
                    onFollow: _follow,
                    onUnfollow: _unfollow,
                    username: _account.username,
                  ),
                ],
              ),
              // 1-line bio snippet (secondary) as per requirements
              if ((_account.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8), // Vertical spacing 8px
                Text(
                  _stripHtml(_account.note),
                  maxLines: 1, // 1-line as per requirements
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant, // Secondary color
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}
