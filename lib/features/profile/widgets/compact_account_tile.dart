import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
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
    setState(() {
      _isBusy = true;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final updated = await accountService.followAccount(domain, _account.id);
      setState(() {
        _account = _account.copyWith(
          following: updated.following,
          requested: updated.requested,
          followersCount: updated.followersCount,
          followingCount: updated.followingCount,
        );
      });
      widget.onFollowChanged?.call(_account);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow: $e')),
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
    setState(() {
      _isBusy = true;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final updated = await accountService.unfollowAccount(domain, _account.id);
      setState(() {
        _account = _account.copyWith(
          following: updated.following,
          requested: updated.requested,
          followersCount: updated.followersCount,
          followingCount: updated.followingCount,
        );
      });
      widget.onFollowChanged?.call(_account);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfollow: $e')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: _account.avatar != null && _account.avatar!.isNotEmpty
                      ? CachedNetworkImageProvider(_account.avatar!)
                      : null,
                  child: (_account.avatar == null || _account.avatar!.isEmpty)
                      ? Text(_account.displayName.isNotEmpty ? _account.displayName[0] : _account.username[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account.displayName.isNotEmpty ? _account.displayName : _account.username,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AccountUtils.formatHandle(
                          acct: _account.acct,
                          username: _account.username,
                          accountDomain: _account.domain,
                          fallbackDomain: ref.read(activeInstanceProvider)?.domain,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildFollowButton(theme),
              ],
            ),
            if ((_account.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _stripHtml(_account.note),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(ThemeData theme) {
    if (_isBusy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(6.0),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return FollowButton(
      isCurrentUser: false,
      isFollowing: _account.following,
      isFollowRequestPending: _account.requested,
      onFollow: _follow,
      onUnfollow: _unfollow,
      onEditProfile: () {},
    );
  }
}
