import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/services/account_statuses_cache.dart';
import 'package:pixelodon/features/profile/widgets/profile_header.dart';
import 'package:pixelodon/features/profile/widgets/posts_tab.dart';
import 'package:pixelodon/features/profile/widgets/profile_field_item.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';

/// Provider for a user profile
final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
        (ref, accountId) {
  final accountService = ref.watch(accountServiceProvider);
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  final cache = ref.watch(accountStatusesCacheProvider);

  return ProfileNotifier(
    accountService: accountService,
    timelineService: timelineService,
    cache: cache,
    domain: activeInstance?.domain,
    isPixelfed: activeInstance?.isPixelfed ?? false,
    accountId: accountId,
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
      isFollowRequestPending:
          isFollowRequestPending ?? this.isFollowRequestPending,
    );
  }
}

/// Notifier for a profile
class ProfileNotifier extends StateNotifier<ProfileState> {
  final AccountService accountService;
  final TimelineService timelineService;
  final AccountStatusesCache cache;
  final String? domain;
  final bool isPixelfed;
  final String accountId;
  CancelToken? _cancelToken;

  ProfileNotifier({
    required this.accountService,
    required this.timelineService,
    required this.cache,
    this.domain,
    required this.isPixelfed,
    required this.accountId,
  }) : super(ProfileState()) {
    if (domain != null) {
      loadProfile();
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
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
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
        final delay = Duration(
            milliseconds: 1000 *
                (retryCount +
                    1)); // 1s, 2s, 3s - more reasonable for network requests
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
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
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
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
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

  /// Constructor
  const ProfileScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<List<model.Status>>? _likesFuture;
  Future<List<model.Status>>? _bookmarksFuture;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.accountId));
    final profileNotifier =
        ref.read(profileProvider(widget.accountId).notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    final isPixelfed = activeInstance?.isPixelfed ?? false;

    return Scaffold(
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : profileState.hasError
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
                        profileState.errorMessage ?? 'An error occurred',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: profileNotifier.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : profileState.account == null
                  ? const Center(
                      child: Text('Account not found'),
                    )
                  : RefreshIndicator(
                      onRefresh: profileNotifier.refreshProfile,
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: ProfileHeader(
                                account: profileState.account!,
                                isPixelfed: isPixelfed,
                                isCurrentUser:
                                    (ref.read(activeAccountProvider)?.id ==
                                        widget.accountId),
                                isFollowing: profileState.isFollowing,
                                isFollowRequestPending:
                                    profileState.isFollowRequestPending,
                                activeDomain: activeInstance?.domain,
                                onFollow: profileNotifier.followAccount,
                                onUnfollow: profileNotifier.unfollowAccount,
                                onEditProfile: () {
                                  /* TODO: Navigate to edit profile */
                                },
                              ),
                            ),
                            // About section moved below description
                            SliverToBoxAdapter(
                              child: _AboutSection(account: profileState.account!),
                            ),
                          ];
                        },
                        body: _buildProfileBody(context, isPixelfed, profileState, profileNotifier),
                      ),
                    ),
    );
  }
  Widget _buildProfileBody(BuildContext context, bool isPixelfed, ProfileState profileState, ProfileNotifier profileNotifier) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final isSelf = (ref.read(activeAccountProvider)?.id == widget.accountId);

    final tabs = <Tab>[];
    final views = <Widget>[];

    if (isPixelfed) {
      tabs.add(const Tab(text: 'Media'));
      views.add(
        PostsTab(
          statuses: profileState.statuses.where((s) => s.mediaAttachments.isNotEmpty).toList(),
          isLoading: profileState.isLoadingStatuses,
          hasError: profileState.hasError,
          errorMessage: profileState.errorMessage,
          hasMore: profileState.hasMore,
          isPixelfed: true,
          onlyMedia: true,
          onLoadMore: profileNotifier.loadMoreStatuses,
          onRefresh: profileNotifier.refreshStatuses,
          onEnsureOnlyMedia: (_) {},
          onStatusUpdated: (status) => profileNotifier.updateStatus(status),
        ),
      );
    } else {
      tabs.add(const Tab(text: 'Posts'));
      views.add(
        PostsTab(
          statuses: profileState.statuses.where((s) => s.inReplyToId == null).toList(),
          isLoading: profileState.isLoadingStatuses,
          hasError: profileState.hasError,
          errorMessage: profileState.errorMessage,
          hasMore: profileState.hasMore,
          isPixelfed: false,
          onlyMedia: false,
          onLoadMore: profileNotifier.loadMoreStatuses,
          onRefresh: profileNotifier.refreshStatuses,
          onEnsureOnlyMedia: (_) {},
          onStatusUpdated: (status) => profileNotifier.updateStatus(status),
        ),
      );
    }

    // Comments
    final commentsIndex = tabs.length;
    tabs.add(const Tab(text: 'Comments'));
    views.add(
      PostsTab(
        statuses: profileState.statuses.where((s) => s.inReplyToId != null).toList(),
        isLoading: profileState.isLoadingStatuses,
        hasError: profileState.hasError,
        errorMessage: profileState.errorMessage,
        hasMore: profileState.hasMore,
        isPixelfed: false,
        onlyMedia: false,
        onLoadMore: profileNotifier.loadMoreStatuses,
        onRefresh: profileNotifier.refreshStatuses,
        onEnsureOnlyMedia: (_) {},
        onStatusUpdated: (status) => profileNotifier.updateStatus(status),
      ),
    );

    // Likes
    final likesIndex = tabs.length;
    tabs.add(const Tab(text: 'Likes'));
    views.add(_buildLikesTab(isSelf, likesIndex));

    // Favorites
    final favIndex = tabs.length;
    tabs.add(const Tab(text: 'Favorites'));
    views.add(_buildBookmarksTab(isSelf, favIndex));

    // Boosts
    final boostsIndex = tabs.length;
    tabs.add(const Tab(text: 'Boosts'));
    // Per API: boosts are statuses where the `reblog` attribute is not null.
    // In our model, `reblog` maps to `rebloggedStatus`.
    final boosts = profileState.statuses
        .where((s) => s.rebloggedStatus != null)
        .toList();
    views.add(
      PostsTab(
        statuses: boosts,
        isLoading: profileState.isLoadingStatuses,
        hasError: profileState.hasError,
        errorMessage: profileState.errorMessage,
        hasMore: false,
        isPixelfed: false,
        onlyMedia: false,
        onLoadMore: () {},
        onRefresh: profileNotifier.refreshStatuses,
        onEnsureOnlyMedia: (_) {},
        onStatusUpdated: (status) => profileNotifier.updateStatus(status),
      ),
    );

    return DefaultTabController(
      length: tabs.length,
      child: _ProfileTabContainer(
        tabs: tabs,
        views: views,
        isPixelfed: isPixelfed,
        commentsIndex: commentsIndex,
        boostsIndex: boostsIndex,
        notifier: profileNotifier,
      ),
    );
  }

  Widget _buildLikesTab(bool isSelf, int tabIndex) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final timelineService = ref.watch(timelineServiceProvider);

    if (!isSelf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Likes are private and only visible for your own profile.'),
        ),
      );
    }

    return _LazyTabContent<model.Status>(
      tabIndex: tabIndex,
      initialFuture: _likesFuture,
      onFutureCreated: (future) => setState(() => _likesFuture = future),
      loader: () {
        if (activeInstance?.domain == null) return Future.value(const <model.Status>[]);
        return timelineService.getFavourites(activeInstance!.domain, limit: 40);
      },
      builder: (context, data, refresh) {
        return FeedList(
          statuses: data,
          isLoading: false,
          hasError: false,
          hasMore: false,
          onLoadMore: null,
          onRefresh: () async {
            await refresh();
          },
        );
      },
      errorBuilder: (err) => Center(child: Text('Failed to load likes: $err')),
      placeholder: const Center(child: SizedBox()),
    );
  }

  Widget _buildBookmarksTab(bool isSelf, int tabIndex) {
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

    return _LazyTabContent<model.Status>(
      tabIndex: tabIndex,
      initialFuture: _bookmarksFuture,
      onFutureCreated: (future) => setState(() => _bookmarksFuture = future),
      loader: () {
        if (activeInstance?.domain == null) return Future.value(const <model.Status>[]);
        return timelineService.getBookmarks(activeInstance!.domain, limit: 40);
      },
      builder: (context, data, refresh) {
        return FeedList(
          statuses: data,
          isLoading: false,
          hasError: false,
          hasMore: false,
          onLoadMore: null,
          onRefresh: () async {
            await refresh();
          },
        );
      },
      errorBuilder: (err) => Center(child: Text('Failed to load favorites: $err')),
      placeholder: const Center(child: SizedBox()),
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
            const Text(
              'Profile Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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


/// Lazily loads data for a tab only when it becomes active the first time.
class _LazyTabContent<T> extends StatefulWidget {
  final int tabIndex;
  final Future<List<T>>? initialFuture;
  final void Function(Future<List<T>> future) onFutureCreated;
  final Future<List<T>> Function() loader;
  final Widget Function(BuildContext context, List<T> data, Future<void> Function() refresh) builder;
  final Widget Function(Object error) errorBuilder;
  final Widget placeholder;

  const _LazyTabContent({
    required this.tabIndex,
    required this.initialFuture,
    required this.onFutureCreated,
    required this.loader,
    required this.builder,
    required this.errorBuilder,
    required this.placeholder,
  });

  @override
  State<_LazyTabContent<T>> createState() => _LazyTabContentState<T>();
}

class _LazyTabContentState<T> extends State<_LazyTabContent<T>> {
  Future<List<T>>? _future;
  TabController? _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= DefaultTabController.of(context);

    // Attach listener once
    if (!_initialized && _controller != null) {
      _initialized = true;
      // If the tab is already selected, start loading immediately
      if (_controller!.index == widget.tabIndex) {
        _startLoading();
      } else {
        _future = widget.initialFuture;
      }
      _controller!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_controller!.index == widget.tabIndex && _future == null) {
      _startLoading();
    }
  }

  void _startLoading() {
    final fut = widget.loader();
    widget.onFutureCreated(fut);
    setState(() {
      _future = fut;
    });
  }

  Future<void> _refresh() async {
    final fut = widget.loader();
    widget.onFutureCreated(fut);
    setState(() {
      _future = fut;
    });
    await fut.catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return widget.placeholder;
    }

    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return widget.errorBuilder(snapshot.error!);
        }
        final data = snapshot.data ?? <T>[];
        return widget.builder(context, data, _refresh);
      },
    );
  }
}

/// Container that handles TabBar/TabBarView and switches timeline filters
/// only when Comments or Boosts tabs are selected.
class _ProfileTabContainer extends StatefulWidget {
  final List<Tab> tabs;
  final List<Widget> views;
  final bool isPixelfed;
  final int commentsIndex;
  final int boostsIndex;
  final ProfileNotifier notifier;

  const _ProfileTabContainer({
    required this.tabs,
    required this.views,
    required this.isPixelfed,
    required this.commentsIndex,
    required this.boostsIndex,
    required this.notifier,
  });

  @override
  State<_ProfileTabContainer> createState() => _ProfileTabContainerState();
}

class _ProfileTabContainerState extends State<_ProfileTabContainer> {
  TabController? _controller;
  String _appliedKey = 'posts';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= DefaultTabController.of(context);
    if (_controller != null) {
      _controller!.addListener(_handleTabChange);
      // Ensure initial key matches default filters (exclude replies & reblogs)
      _appliedKey = 'posts';
      // Apply initial filters right away respecting Pixelfed Media default
      widget.notifier.setFilters(
        excludeReplies: true,
        excludeReblogs: true,
        onlyMedia: widget.isPixelfed,
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (!_controller!.indexIsChanging) {
      final idx = _controller!.index;

      String key = 'posts';
      bool? excludeReplies = true;
      bool? excludeReblogs = true;
      bool? onlyMedia;

      if (idx == widget.commentsIndex) {
        key = 'comments';
        excludeReplies = false; // include replies
        excludeReblogs = true;  // keep boosts excluded
        onlyMedia = false;      // comments likely have no media
      } else if (idx == widget.boostsIndex) {
        key = 'boosts';
        excludeReplies = true;  // exclude replies to reduce extra data
        excludeReblogs = false; // include boosts
        onlyMedia = false;
      } else {
        key = 'posts';
        excludeReplies = true;
        excludeReblogs = true;
        onlyMedia = widget.isPixelfed ? true : null; // onlyMedia true for Pixelfed Media tab
      }

      if (key != _appliedKey) {
        _appliedKey = key;
        widget.notifier.setFilters(
          excludeReplies: excludeReplies,
          excludeReblogs: excludeReblogs,
          onlyMedia: onlyMedia,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: widget.tabs,
          ),
        ),
        Expanded(
          child: TabBarView(children: widget.views),
        ),
      ],
    );
  }
}
