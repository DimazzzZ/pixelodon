import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/features/profile/widgets/compact_account_tile.dart';
import 'package:pixelodon/features/profile/widgets/skeleton_account_tile.dart';
import 'package:pixelodon/features/profile/widgets/follow_list_states.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

enum FollowListType { following, followers }

class FollowListScreen extends ConsumerStatefulWidget {
  final String accountId;
  final FollowListType type;
  final String? domainOverride;

  const FollowListScreen({super.key, required this.accountId, required this.type, this.domainOverride});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final List<Account> _accounts = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _maxId;
  bool _hasMore = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _accounts.clear();
      _maxId = null;
      _hasMore = true;
    });
    await _fetch();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _accounts.clear();
      _maxId = null;
      _hasMore = true;
    });
    await _fetch();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    await _fetch();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetch() async {
    final activeDomain = ref.read(activeInstanceProvider)?.domain;
    String? targetDomain = widget.domainOverride ?? activeDomain;
    if (targetDomain == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No active instance';
      });
      return;
    }

    String targetAccountId = widget.accountId;

    try {
      final accountService = ref.read(accountServiceProvider);

      // If we have an override domain different from active domain, resolve remote account id
      if (widget.domainOverride != null && activeDomain != null && widget.domainOverride != activeDomain) {
        try {
          // Fetch local account to get username/acct to build a resolvable query
          final localAccount = await accountService.getAccount(activeDomain, widget.accountId);

          // Prefer acct if it contains domain, else compose username@targetDomain
          String query;
          if ((localAccount.acct).contains('@')) {
            query = localAccount.acct;
          } else {
            query = '${localAccount.username}@$targetDomain';
          }

          final results = await accountService.searchAccounts(
            targetDomain,
            query: query,
            limit: 1,
            resolve: true,
          );
          if (results.isNotEmpty) {
            targetAccountId = results.first.id;
          }
        } catch (_) {
          // If resolution fails, continue with original id and targetDomain; may 404 but we'll show error.
        }
      }

      final result = widget.type == FollowListType.following
          ? await accountService.getFollowing(targetDomain, targetAccountId, limit: 40, maxId: _maxId)
          : await accountService.getFollowers(targetDomain, targetAccountId, limit: 40, maxId: _maxId);

      // Fetch relationship data for each account to determine follow status
      final accountsWithRelationships = <Account>[];
      for (final account in result.items) {
        Account updatedAccount = account.copyWith(domain: targetDomain, isPixelfed: false);
        
        // Only fetch relationships if we're on the same domain as the active instance
        if (targetDomain == activeDomain && activeDomain != null) {
          try {
            final relationshipData = await accountService.getRelationship(activeDomain, account.id);
            final following = relationshipData['following'] as bool? ?? false;
            final requested = relationshipData['requested'] as bool? ?? false;
            
            updatedAccount = updatedAccount.copyWith(
              following: following,
              requested: requested,
            );
          } catch (e) {
            // If relationship fetch fails, keep the account with default relationship values
            // This ensures the list still loads even if some relationship data is unavailable
          }
        }
        
        accountsWithRelationships.add(updatedAccount);
      }

      // Use pagination information from the result
      _maxId = result.nextMaxId;
      setState(() {
        _accounts.addAll(accountsWithRelationships);
        _hasMore = result.hasMore;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load list: $e';
      });
    }
  }

  String _title() => widget.type == FollowListType.following ? 'Following' : 'Followers';

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          title: Text(_title()),
          leading: PlatformIconButton(
            onPressed: () => context.go('/profile/${widget.accountId}'),
            icon: PlatformWidget(
              material: (_, __) => const Icon(Icons.arrow_back),
              cupertino: (_, __) => const Icon(CupertinoIcons.back),
            ),
          ),
          material: (_, __) => MaterialAppBarData(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          cupertino: (_, __) => CupertinoNavigationBarData(
            backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
      usesSlivers: false,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Show skeleton loading state for initial load
    if (_isLoading && _accounts.isEmpty) {
      return const SkeletonAccountList();
    }
    
    // Show error state for initial load failure
    if (_hasError && _accounts.isEmpty) {
      return FollowListErrorState(
        errorMessage: _errorMessage,
        onRetry: _loadInitial,
      );
    }
    
    // Show empty state when no accounts found
    if (!_isLoading && !_hasError && _accounts.isEmpty) {
      return FollowListEmptyState(type: widget.type);
    }

    // Show list with accounts
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Use stable keys to prevent jumpy layout when images load
      itemBuilder: (context, index) {
        if (index < _accounts.length) {
          final acc = _accounts[index];
          return CompactAccountTile(
            key: ValueKey('account_${acc.id}'), // Stable key
            account: acc,
            onTap: () => context.push('/profile/${acc.id}'),
            onFollowChanged: (updated) {
              setState(() {
                _accounts[index] = updated;
              });
            },
          );
        }
        
        // Loading indicator for pagination
        if (_isLoading && _hasMore) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
      // Divider at 1px with 16px inset as per requirements
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        indent: 16, // 16px inset as per requirements
        endIndent: 0,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      itemCount: _accounts.length + (_isLoading && _hasMore ? 1 : 0),
    );
  }
}
