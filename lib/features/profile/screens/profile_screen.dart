import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/services/account_statuses_cache.dart';
import 'package:pixelodon/services/account_follow_counts_cache.dart';
import 'package:pixelodon/services/account_posts_count_cache.dart';
import 'package:pixelodon/features/profile/widgets/profile_header.dart';
import 'package:pixelodon/features/profile/widgets/posts_tab.dart';
import 'package:pixelodon/features/profile/widgets/profile_field_item.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';

/// Provider for a user profile
/// Optional per-profile overrides for domain and platform
final profileOverridesProvider = StateProvider.family<({String? domain, bool? isPixelfed}), String>(
    (ref, accountId) => (domain: null, isPixelfed: null));

final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, accountId) {
  final accountService = ref.watch(accountServiceProvider);
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  final cache = ref.watch(accountStatusesCacheProvider);
  final overrides = ref.watch(profileOverridesProvider(accountId));

  final activeAccount = ref.watch(activeAccountProvider);
  final followCountsCache = ref.watch(accountFollowCountsCacheProvider);
  final postsCountCache = ref.watch(accountPostsCountCacheProvider);
  return ProfileNotifier(
    accountService: accountService,
    timelineService: timelineService,
    cache: cache,
    followCountsCache: followCountsCache,
    postsCountCache: postsCountCache,
    domain: overrides.domain ?? activeInstance?.domain,
    isPixelfed: overrides.isPixelfed ?? (activeInstance?.isPixelfed ?? false),
    accountId: accountId,
    isSelf: activeAccount?.id == accountId,
  );
});

/// State for a profile
class ProfileState {
  final Account? account;
  final List<model.Status> statuses;
  final bool isLoading;
  final bool isLoadingStatuses;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;
  final bool onlyMedia;
  final bool excludeReplies;
  final bool excludeReblogs;
  final bool pinned;
  final bool isFollowing;
  final bool isFollowRequestPending;
  // Computed follow counts (iterated API), cached up to 1 hour
  final int? computedFollowersCount;
  final int? computedFollowingCount;
  final DateTime? countsFetchedAt;
  // Cached posts count (statuses_count)
  final int? cachedPostsCount;
  final DateTime? postsCountFetchedAt;

  ProfileState({
    this.account,
    this.statuses = const [],
    this.isLoading = false,
    this.isLoadingStatuses = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
    this.onlyMedia = false,
    this.excludeReplies = true,
    this.excludeReblogs = true,
    this.pinned = false,
    this.isFollowing = false,
    this.isFollowRequestPending = false,
    this.computedFollowersCount,
    this.computedFollowingCount,
    this.countsFetchedAt,
    this.cachedPostsCount,
    this.postsCountFetchedAt,
  });

  ProfileState copyWith({
    Account? account,
    List<model.Status>? statuses,
    bool? isLoading,
    bool? isLoadingStatuses,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
    bool? isFollowing,
    bool? isFollowRequestPending,
    int? computedFollowersCount,
    int? computedFollowingCount,
    DateTime? countsFetchedAt,
    int? cachedPostsCount,
    DateTime? postsCountFetchedAt,
  }) {
    return ProfileState(
      account: account ?? this.account,
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      isLoadingStatuses: isLoadingStatuses ?? this.isLoadingStatuses,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
      onlyMedia: onlyMedia ?? this.onlyMedia,
      excludeReplies: excludeReplies ?? this.excludeReplies,
      excludeReblogs: excludeReblogs ?? this.excludeReblogs,
      pinned: pinned ?? this.pinned,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowRequestPending: isFollowRequestPending ?? this.isFollowRequestPending,
      computedFollowersCount: computedFollowersCount ?? this.computedFollowersCount,
      computedFollowingCount: computedFollowingCount ?? this.computedFollowingCount,
      countsFetchedAt: countsFetchedAt ?? this.countsFetchedAt,
      cachedPostsCount: cachedPostsCount ?? this.cachedPostsCount,
      postsCountFetchedAt: postsCountFetchedAt ?? this.postsCountFetchedAt,
    );
  }
}

/// Notifier for a profile
class ProfileNotifier extends StateNotifier<ProfileState> {
  final AccountService accountService;
  final TimelineService timelineService;
  final AccountStatusesCache cache;
  final AccountFollowCountsCache followCountsCache;
  final AccountPostsCountCache postsCountCache;
  final String? domain;
  final bool isPixelfed;
  final String accountId;
  final bool isSelf;
  CancelToken? _cancelToken;

  // When viewing a remote (Mastodon) profile from a Pixelfed session,
  // we may need to fetch statuses from the remote host using a technical token.
  // These fields allow us to override the domain and accountId specifically
  // for statuses fetching without changing the initial profile fetch domain.
  String? _statusesDomain;
  String? _statusesAccountId;

  ProfileNotifier({
    required this.accountService,
    required this.timelineService,
    required this.cache,
    required this.followCountsCache,
    required this.postsCountCache,
    this.domain,
    required this.isPixelfed,
    required this.accountId,
    required this.isSelf,
  }) : super(ProfileState()) {
    if (domain != null) {
      // Set loading state synchronously (show loader for Mastodon, show content for Pixelfed)
      state = state.copyWith(isLoading: !isPixelfed, hasError: false, errorMessage: null);
      // Only auto-load for non-self profiles to avoid unnecessary timers in tests/self-profile
      if (!isSelf) {
        // Defer the actual async load to after the next frame to avoid creating timers during the first test frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Schedule for the next frame, so single-frame tests won't trigger async timers
          WidgetsBinding.instance.scheduleFrameCallback((_) {
            if (!mounted) return;
            loadProfile();
          });
        });
      } else {
        // For self-profile, load immediately - this fixes an issue where your own profile is blank
        loadProfile();
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Profile navigation cancelled');
    super.dispose();
  }

  /// Set timeline filters
  void setFilters({
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
  }) {
    final newOnlyMedia = onlyMedia ?? state.onlyMedia;
    final newExcludeReplies = excludeReplies ?? state.excludeReplies;
    final newExcludeReblogs = excludeReblogs ?? state.excludeReblogs;
    final newPinned = pinned ?? state.pinned;

    // Avoid redundant reloads if nothing changed
    final unchanged = newOnlyMedia == state.onlyMedia &&
        newExcludeReplies == state.excludeReplies &&
        newExcludeReblogs == state.excludeReblogs &&
        newPinned == state.pinned;
    if (unchanged) return;

    state = state.copyWith(
      onlyMedia: newOnlyMedia,
      excludeReplies: newExcludeReplies,
      excludeReblogs: newExcludeReblogs,
      pinned: newPinned,
    );

    loadStatuses();
  }

  /// Prepare statuses fetch target based on the account URL host if different
  Future<void> _prepareStatusesTarget(Account account) async {
    try {
      final currentDomain = domain;
      if (currentDomain == null) return;
      // Extract host from the account's canonical URL, if present; otherwise from acct
      String? host = Uri.tryParse(account.url ?? '')?.host;
      if ((host == null || host.isEmpty) && account.acct.contains('@')) {
        final parts = account.acct.split('@');
        if (parts.length == 2) {
          host = parts[1];
        } else if (parts.length > 2) {
          host = parts.last;
        }
      }
      if (host != null && host.isNotEmpty && host != currentDomain) {
        _statusesDomain = host;
        // Resolve the account id on the remote host so we can call /accounts/{id}/statuses there
        final query = account.acct.contains('@') ? account.acct : '${account.username}@$host';
        final results = await accountService.searchAccounts(
          host,
          query: query,
          limit: 1,
          resolve: true,
        );
        if (results.isNotEmpty) {
          _statusesAccountId = results.first.id;
        } else {
          // If lookup failed, fall back to using the original id/domain
          _statusesDomain = null;
          _statusesAccountId = null;
        }
      } else {
        _statusesDomain = null;
        _statusesAccountId = null;
      }
    } catch (_) {
      // On any error, do not change the defaults
      _statusesDomain = null;
      _statusesAccountId = null;
    }
  }

  Future<void> _ensureFollowCounts({bool force = false}) async {
    final d = domain;
    if (d == null) return;
    // Use cached
    final hasRemoteTarget = _statusesDomain != null || _statusesAccountId != null;
    if (!force && !hasRemoteTarget) {
      final cached = followCountsCache.getFresh(d, accountId);
      if (cached != null) {
        state = state.copyWith(
          computedFollowersCount: cached.followers,
          computedFollowingCount: cached.following,
          countsFetchedAt: cached.fetchedAt,
        );
        return;
      }
    }
    // Compute by iterating API
    int followers = 0;
    int following = 0;
    try {
      // Decide which domain/id to iterate: remote target if available
      final targetDomain = _statusesDomain ?? d;
      final targetAccountId = _statusesAccountId ?? accountId;

      // Followers
      String? cursor;
      const int pageSize = 80;
      int safety = 0;
      while (safety < 1000) { // safety cap ~80k max entries
        final batch = await accountService.getFollowers(targetDomain, targetAccountId, limit: pageSize, maxId: cursor);
        if (batch.isEmpty) break;
        followers += batch.length;
        cursor = batch.last.id;
        safety++;
        if (batch.length < pageSize) break;
      }
      // Following
      cursor = null;
      safety = 0;
      while (safety < 1000) {
        final batch = await accountService.getFollowing(targetDomain, targetAccountId, limit: pageSize, maxId: cursor);
        if (batch.isEmpty) break;
        following += batch.length;
        cursor = batch.last.id;
        safety++;
        if (batch.length < pageSize) break;
      }

      // Cache under the primary key (original domain/accountId) to keep refresh logic consistent
      followCountsCache.set(d, accountId, followers: followers, following: following);
      state = state.copyWith(
        computedFollowersCount: followers,
        computedFollowingCount: following,
        countsFetchedAt: DateTime.now(),
      );
    } catch (_) {
      // Leave as is on error; no cache set
    }
  }

  /// Load the profile
  Future<void> loadProfile() async {
    if (domain == null) return;

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

    try {
      final account = await accountService.getAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isLoading: false,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );

      // Cache/restore posts count (statuses_count)
      try {
        final d = domain!;
        final cached = postsCountCache.getFresh(d, accountId);
        if (cached != null) {
          state = state.copyWith(
            cachedPostsCount: cached.posts,
            postsCountFetchedAt: cached.fetchedAt,
          );
        } else {
          postsCountCache.set(d, accountId, posts: account.statusesCount);
          state = state.copyWith(
            cachedPostsCount: account.statusesCount,
            postsCountFetchedAt: DateTime.now(),
          );
        }
      } catch (_) {}

      // Prepare remote statuses target if applicable
      await _prepareStatusesTarget(account);

      // Start ensuring follow counts (non-blocking)
      // Do not block profile load; counts will appear once computed or from cache
      unawaited(_ensureFollowCounts());

      // If viewing a remote Mastodon profile, enrich with remote account data and relationship via tech token
      if (_statusesDomain != null && _statusesAccountId != null) {
        try {
          final remoteAcc = await accountService.getAccount(_statusesDomain!, _statusesAccountId!);
          // Try to fetch relationship to set Follow/Requested flags correctly
          bool following = state.isFollowing;
          bool requested = state.isFollowRequestPending;
          try {
            final rel = await accountService.getRelationship(_statusesDomain!, _statusesAccountId!);
            following = (rel['following'] == true);
            requested = (rel['requested'] == true);
          } catch (_) {}

          state = state.copyWith(
            account: remoteAcc.copyWith(domain: _statusesDomain, isPixelfed: false),
            isFollowing: following,
            isFollowRequestPending: requested,
          );
          // Ensure posts count reflects the remote profile's posts
          try {
            postsCountCache.set(domain!, accountId, posts: remoteAcc.statusesCount);
            state = state.copyWith(
              cachedPostsCount: remoteAcc.statusesCount,
              postsCountFetchedAt: DateTime.now(),
            );
          } catch (_) {}
        } catch (_) {
          // ignore remote enrichment errors, keep initial account
        }
      }

      loadStatuses();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load profile: $e',
      );
    }
  }

  /// Load the account's statuses
  Future<void> loadStatuses({int retryCount = 0, bool isRetry = false}) async {
    if (domain == null) return;

    // Only cancel if this is NOT a retry attempt - let retries use existing token
    if (!isRetry) {
      if (_cancelToken != null && !_cancelToken!.isCancelled) {
        _cancelToken!.cancel('New status request');
      }
      _cancelToken = CancelToken();
    }

    state = state.copyWith(
      isLoadingStatuses: true,
    );

    try {
      final targetDomain = _statusesDomain ?? domain!;
      final targetAccountId = _statusesAccountId ?? accountId;

      final statuses = await timelineService.getAccountStatuses(
        targetDomain,
        targetAccountId,
        limit: 20,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
        cancelToken: _cancelToken,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        isLoadingStatuses: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      // Automatic retry for cancellation errors with longer delays to allow network requests to complete
      if (e is CancellationException && retryCount < 3) {
        final delay = Duration(milliseconds: 1000 * (retryCount + 1)); // 1s, 2s, 3s - more reasonable for network requests
        await Future.delayed(delay);
        return loadStatuses(retryCount: retryCount + 1, isRetry: true);
      }

      state = state.copyWith(
        isLoadingStatuses: false,
        hasError: true,
        errorMessage: 'Failed to load statuses: $e',
      );
    }
  }

  /// Refresh the profile and statuses
  Future<void> refreshProfile() async {
    if (domain == null) return;

    try {
      final account = await accountService.getAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
        hasError: false,
        errorMessage: null,
      );

      // Recompute remote target if account changed
      await _prepareStatusesTarget(account);

      // If remote target detected, refresh account details and relationship from remote host
      if (_statusesDomain != null && _statusesAccountId != null) {
        try {
          final remoteAcc = await accountService.getAccount(_statusesDomain!, _statusesAccountId!);
          bool following = state.isFollowing;
          bool requested = state.isFollowRequestPending;
          try {
            final rel = await accountService.getRelationship(_statusesDomain!, _statusesAccountId!);
            following = (rel['following'] == true);
            requested = (rel['requested'] == true);
          } catch (_) {}
          state = state.copyWith(
            account: remoteAcc.copyWith(domain: _statusesDomain, isPixelfed: false),
            isFollowing: following,
            isFollowRequestPending: requested,
          );
          // Ensure posts count reflects the remote profile's posts
          try {
            postsCountCache.set(domain!, accountId, posts: remoteAcc.statusesCount);
            state = state.copyWith(
              cachedPostsCount: remoteAcc.statusesCount,
              postsCountFetchedAt: DateTime.now(),
            );
          } catch (_) {}
        } catch (_) {}
      }

      // Force refresh counts by clearing cache and recomputing
      try { followCountsCache.clear(domain!, accountId); } catch (_) {}
      unawaited(_ensureFollowCounts(force: true));

      // Refresh posts count cache from latest account data
      try {
        postsCountCache.clear(domain!, accountId);
        postsCountCache.set(domain!, accountId, posts: account.statusesCount);
        state = state.copyWith(
          cachedPostsCount: account.statusesCount,
          postsCountFetchedAt: DateTime.now(),
        );
      } catch (_) {}

      await refreshStatuses();
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to refresh profile: $e',
      );
    }
  }

  /// Refresh the account's statuses
  Future<void> refreshStatuses() async {
    if (domain == null) return;

    try {
      final targetDomain = _statusesDomain ?? domain!;
      final targetAccountId = _statusesAccountId ?? accountId;

      final statuses = await timelineService.getAccountStatuses(
        targetDomain,
        targetAccountId,
        limit: 20,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        hasMore: statuses.length >= 20,
        maxId: maxId,
        hasError: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to refresh statuses: $e',
      );
    }
  }

  /// Load more statuses
  Future<void> loadMoreStatuses() async {
    if (domain == null || state.isLoadingStatuses || !state.hasMore) return;

    state = state.copyWith(
      isLoadingStatuses: true,
    );

    try {
      final targetDomain = _statusesDomain ?? domain!;
      final targetAccountId = _statusesAccountId ?? accountId;

      final statuses = await timelineService.getAccountStatuses(
        targetDomain,
        targetAccountId,
        limit: 20,
        maxId: state.maxId,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: [...state.statuses, ...statuses],
        isLoadingStatuses: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStatuses: false,
        hasError: true,
        errorMessage: 'Failed to load more statuses: $e',
      );
    }
  }

  /// Follow the account
  Future<void> followAccount() async {
    if (domain == null || state.account == null) return;

    state = state.copyWith(
      isFollowRequestPending: state.account!.locked,
      isFollowing: !state.account!.locked,
    );

    try {
      final account = await accountService.followAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );
    } catch (e) {
      // Revert state if the API call fails
      state = state.copyWith(
        isFollowRequestPending: false,
        isFollowing: false,
        hasError: true,
        errorMessage: 'Failed to follow account: $e',
      );
    }
  }

  /// Unfollow the account
  Future<void> unfollowAccount() async {
    if (domain == null || state.account == null) return;

    state = state.copyWith(
      isFollowing: false,
      isFollowRequestPending: false,
    );

    try {
      final account = await accountService.unfollowAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );
    } catch (e) {
      // Revert state if the API call fails
      state = state.copyWith(
        isFollowing: true,
        hasError: true,
        errorMessage: 'Failed to unfollow account: $e',
      );
    }
  }

  /// Update a status in the timeline
  void updateStatus(model.Status status) {
    final index = state.statuses.indexWhere((s) => s.id == status.id);

    if (index != -1) {
      final updatedStatuses = List<model.Status>.from(state.statuses);
      updatedStatuses[index] = status;

      state = state.copyWith(
        statuses: updatedStatuses,
      );
    }
  }
}

/// Screen for displaying a user profile
class ProfileScreen extends ConsumerStatefulWidget {
  /// The ID of the account to display
  final String accountId;

  /// Optional override: view this profile using a specific remote domain/platform
  final String? domainOverride;
  final bool? isPixelfedOverride;

  /// Constructor
  ProfileScreen({
    Key? key,
    required this.accountId,
    this.domainOverride,
    this.isPixelfedOverride,
  }) : super(key: key ?? ValueKey<String>(accountId));

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  Future<List<model.Status>>? _likesFuture;
  Future<List<model.Status>>? _bookmarksFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Debug print to check for duplicate ProfileScreens
    // ignore: avoid_print
    print('ProfileScreen initState for accountId: \'${widget.accountId}\'');
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    // Debug print to check for duplicate ProfileScreens
    // ignore: avoid_print
    print('ProfileScreen dispose for accountId: \'${widget.accountId}\'');
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final profileNotifier = ref.read(profileProvider(widget.accountId).notifier);

      switch (_tabController.index) {
        case 1: // Comments
          profileNotifier.setFilters(
            excludeReplies: false,
            excludeReblogs: true,
            onlyMedia: false,
          );
          break;
        case 4: // Boosts
          profileNotifier.setFilters(
            excludeReplies: true,
            excludeReblogs: false,
            onlyMedia: false,
          );
          break;
        default: // Posts, Favorites, Bookmarks
          final isPixelfed = ref.read(profileProvider(widget.accountId)).account?.isPixelfed ??
              (ref.read(activeInstanceProvider)?.isPixelfed ?? false);

          profileNotifier.setFilters(
            excludeReplies: true,
            excludeReblogs: true,
            onlyMedia: isPixelfed ? true : false,
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply overrides (if provided) before reading profile provider
    if (widget.domainOverride != null || widget.isPixelfedOverride != null) {
      final overridesNotifier = ref.read(profileOverridesProvider(widget.accountId).notifier);
      final currentOverrides = ref.read(profileOverridesProvider(widget.accountId));
      final nextOverrides = (
        domain: widget.domainOverride ?? currentOverrides.domain,
        isPixelfed: widget.isPixelfedOverride ?? currentOverrides.isPixelfed
      );
      if (currentOverrides.domain != nextOverrides.domain || currentOverrides.isPixelfed != nextOverrides.isPixelfed) {
        overridesNotifier.state = nextOverrides;
      }
    }

    final profileState = ref.watch(profileProvider(widget.accountId));
    final profileNotifier = ref.read(profileProvider(widget.accountId).notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    final isSelfViewer = (ref.read(activeAccountProvider)?.id == widget.accountId);
    final isPixelfed = widget.isPixelfedOverride ??
        (isSelfViewer ? (activeInstance?.isPixelfed ?? false) : (profileState.account?.isPixelfed ?? false));

    // Force profile loading if not already loading/loaded
    if (profileState.account == null && !profileState.isLoading && !profileState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          profileNotifier.loadProfile();
        }
      });
    }

    return PlatformScaffold(
      body: profileState.isLoading
          ? Center(
              child: PlatformCircularProgressIndicator(),
            )
          : profileState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PlatformIcons(context).error,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profileState.errorMessage ?? 'An error occurred',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      PlatformElevatedButton(
                        onPressed: profileNotifier.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(profileState, profileNotifier, isPixelfed),
    );
  }

  Widget _buildProfileContent(ProfileState profileState, ProfileNotifier profileNotifier, bool isPixelfed) {
    final activeAccount = ref.read(activeAccountProvider);
    final displayAccount = profileState.account ??
        ((activeAccount?.id == widget.accountId) ? activeAccount : null);

    if (displayAccount == null) {
      return const Center(child: Text('Account not found'));
    }

    return RefreshIndicator(
      onRefresh: profileNotifier.refreshProfile,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: ProfileHeader(
                account: _getEnrichedAccount(displayAccount, profileState),
                isPixelfed: isPixelfed,
                isCurrentUser: (ref.read(activeAccountProvider)?.id == widget.accountId),
                isFollowing: profileState.isFollowing,
                isFollowRequestPending: profileState.isFollowRequestPending,
                activeDomain: widget.domainOverride ?? ref.read(activeInstanceProvider)?.domain,
                onFollow: profileNotifier.followAccount,
                onUnfollow: profileNotifier.unfollowAccount,
                onEditProfile: () {
                  // TODO: Navigate to edit profile
                },
              ),
            ),
            // About section
            SliverToBoxAdapter(
              child: _AboutSection(account: displayAccount),
            ),
            // TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                tabController: _tabController,
                tabs: _buildTabs(),
                isPixelfed: isPixelfed,
                key: ValueKey('tabbar_${widget.accountId}'),
              ),
            ),
          ];
        },
        body: TabBarView(
          key: ValueKey('tabview_${widget.accountId}'),
          controller: _tabController,
          children: _buildTabViews(profileState, profileNotifier, isPixelfed),
        ),
      ),
    );
  }

  Account _getEnrichedAccount(Account displayAccount, ProfileState profileState) {
    final cf = profileState.computedFollowersCount;
    final cfo = profileState.computedFollowingCount;
    final cp = profileState.cachedPostsCount;

    if (cf != null || cfo != null || cp != null) {
      return displayAccount.copyWith(
        followersCount: cf ?? displayAccount.followersCount,
        followingCount: cfo ?? displayAccount.followingCount,
        statusesCount: cp ?? displayAccount.statusesCount,
      );
    }
    return displayAccount;
  }

  List<Widget> _buildTabs() {
    return const [
      Tab(text: 'Posts'),
      Tab(text: 'Comments'),
      Tab(text: 'Favorites'),
      Tab(text: 'Bookmarks'),
      Tab(text: 'Boosts'),
    ];
  }

  List<Widget> _buildTabViews(ProfileState profileState, ProfileNotifier profileNotifier, bool isPixelfed) {
    final isSelf = (ref.read(activeAccountProvider)?.id == widget.accountId);
    final safeStatuses = profileState.statuses;
    
    return [
      // Posts (index 0)
      PostsTab(
        key: ValueKey('posts_tab_${widget.accountId}'),
        statuses: isPixelfed
            ? safeStatuses.where((s) => s.mediaAttachments.isNotEmpty).toList()
            : safeStatuses.where((s) => s.inReplyToId == null).toList(),
        isLoading: profileState.isLoadingStatuses,
        hasError: profileState.hasError,
        errorMessage: profileState.errorMessage,
        hasMore: profileState.hasMore,
        isPixelfed: isPixelfed,
        onlyMedia: isPixelfed,
        onLoadMore: profileNotifier.loadMoreStatuses,
        onRefresh: profileNotifier.refreshProfile,
        onEnsureOnlyMedia: (_) {},
        onStatusUpdated: (status) => profileNotifier.updateStatus(status),
        uniqueId: 'posts_${widget.accountId}',
      ),
      
      // Comments (index 1)
      PostsTab(
        key: ValueKey('comments_tab_${widget.accountId}'),
        statuses: safeStatuses.where((s) => s.inReplyToId != null).toList(),
        isLoading: profileState.isLoadingStatuses,
        hasError: profileState.hasError,
        errorMessage: profileState.errorMessage,
        hasMore: profileState.hasMore,
        isPixelfed: false,
        onlyMedia: false,
        onLoadMore: profileNotifier.loadMoreStatuses,
        onRefresh: profileNotifier.refreshProfile,
        onEnsureOnlyMedia: (_) {},
        onStatusUpdated: (status) => profileNotifier.updateStatus(status),
        uniqueId: 'comments_${widget.accountId}',
      ),
      
      // Favorites (index 2)
      _buildLikesTab(isSelf),

      // Bookmarks (index 3)
      _buildBookmarksTab(isSelf),

      // Boosts (index 4)
      PostsTab(
        key: ValueKey('boosts_tab_${widget.accountId}'),
        statuses: safeStatuses.where((s) => s.rebloggedStatus != null).toList(),
        isLoading: profileState.isLoadingStatuses,
        hasError: profileState.hasError,
        errorMessage: profileState.errorMessage,
        hasMore: false,
        isPixelfed: false,
        onlyMedia: false,
        onLoadMore: () {},
        onRefresh: profileNotifier.refreshProfile,
        onEnsureOnlyMedia: (_) {},
        onStatusUpdated: (status) => profileNotifier.updateStatus(status),
        uniqueId: 'boosts_${widget.accountId}',
      ),
    ];
  }

  Widget _buildLikesTab(bool isSelf) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final timelineService = ref.watch(timelineServiceProvider);

    if (!isSelf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Favorites are private and only visible for your own profile.'),
        ),
      );
    }

    return FutureBuilder<List<model.Status>>(
      key: ValueKey('likes_future_${widget.accountId}'),
      future: _likesFuture ?? (_likesFuture = activeInstance?.domain == null
          ? Future.value(const <model.Status>[])
          : timelineService.getFavourites(activeInstance!.domain, limit: 40)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load favorites: ${snapshot.error}'));
        }
        final data = snapshot.data ?? <model.Status>[];
        return FeedList(
          key: ValueKey('likes_feed_${widget.accountId}'),
          statuses: data,
          isLoading: false,
          hasError: false,
          hasMore: false,
          onLoadMore: null,
          onRefresh: () async {
            setState(() {
              _likesFuture = activeInstance?.domain == null
                  ? Future.value(const <model.Status>[])
                  : timelineService.getFavourites(activeInstance!.domain, limit: 40);
            });
            // Wait for the future to complete but return void
            await _likesFuture;
            return;
          },
          wrapWithRefreshIndicator: false,
        );
      },
    );
  }

  Widget _buildBookmarksTab(bool isSelf) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final timelineService = ref.watch(timelineServiceProvider);

    if (!isSelf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Bookmarks are private and only visible for your own profile.'),
        ),
      );
    }

    return FutureBuilder<List<model.Status>>(
      key: ValueKey('bookmarks_future_${widget.accountId}'),
      future: _bookmarksFuture ?? (_bookmarksFuture = activeInstance?.domain == null
          ? Future.value(const <model.Status>[])
          : timelineService.getBookmarks(activeInstance!.domain, limit: 40)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load bookmarks: ${snapshot.error}'));
        }
        final data = snapshot.data ?? <model.Status>[];
        return FeedList(
          key: ValueKey('bookmarks_feed_${widget.accountId}'),
          statuses: data,
          isLoading: false,
          hasError: false,
          hasMore: false,
          onLoadMore: null,
          onRefresh: () async {
            setState(() {
              _bookmarksFuture = activeInstance?.domain == null
                  ? Future.value(const <model.Status>[])
                  : timelineService.getBookmarks(activeInstance!.domain, limit: 40);
            });
            // Wait for the future to complete but return void
            await _bookmarksFuture;
            return;
          },
          wrapWithRefreshIndicator: false,
        );
      },
    );
  }
}

/// About section content moved from the About tab to below profile description
class _AboutSection extends StatelessWidget {
  final Account account;
  const _AboutSection({required this.account});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (account.fields != null && account.fields!.isNotEmpty) ...[
            Text(
              'Profile Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...account.fields!.map((field) => ProfileFieldItem(field: field)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// Delegate for the pinned TabBar header
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Widget> tabs;
  final bool isPixelfed;
  final Key? key;

  const _SliverTabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.isPixelfed,
    this.key,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 4 : 0,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: tabs,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _SliverTabBarDelegate ||
        oldDelegate.tabs != tabs ||
        oldDelegate.isPixelfed != isPixelfed;
  }
}
