import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/features/profile/widgets/compact_account_tile.dart';

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

      final list = widget.type == FollowListType.following
          ? await accountService.getFollowing(targetDomain, targetAccountId, limit: 40, maxId: _maxId)
          : await accountService.getFollowers(targetDomain, targetAccountId, limit: 40, maxId: _maxId);

      if (list.isNotEmpty) {
        _maxId = list.last.id;
      }
      setState(() {
        _accounts.addAll(list.map((a) => a.copyWith(domain: targetDomain, isPixelfed: false)).toList());
        _hasMore = list.length >= 40;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title()),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError && _accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Failed to load'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadInitial,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index < _accounts.length) {
          final acc = _accounts[index];
          return CompactAccountTile(
            account: acc,
            onTap: () => context.push('/profile/${acc.id}'),
            onFollowChanged: (updated) {
              setState(() {
                _accounts[index] = updated;
              });
            },
          );
        }
        // Loader at end
        if (_isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SizedBox.shrink();
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _accounts.length + (_isLoading ? 1 : 0),
    );
  }
}
