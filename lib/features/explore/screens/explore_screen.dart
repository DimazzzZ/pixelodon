import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/providers/api_provider.dart' as api_providers;
import 'package:pixelodon/services/timeline_service.dart';

/// Provider for the public timeline
final publicTimelineProvider = StateNotifierProvider<PublicTimelineNotifier, TimelineState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  
  return PublicTimelineNotifier(
    timelineService: timelineService,
    domain: activeInstance?.domain,
  );
});

/// State for a timeline
class TimelineState {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;
  final bool local;
  final bool onlyMedia;
  
  TimelineState({
    this.statuses = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
    this.local = false,
    this.onlyMedia = false,
  });
  
  TimelineState copyWith({
    List<Status>? statuses,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
    bool? local,
    bool? onlyMedia,
  }) {
    return TimelineState(
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
      local: local ?? this.local,
      onlyMedia: onlyMedia ?? this.onlyMedia,
    );
  }
}

/// Notifier for the public timeline
class PublicTimelineNotifier extends StateNotifier<TimelineState> {
  final TimelineService timelineService;
  final String? domain;
  CancelToken? _cancelToken;
  
  PublicTimelineNotifier({
    required this.timelineService,
    this.domain,
  }) : super(TimelineState()) {
    if (domain != null) {
      loadTimeline();
    }
  }
  
  @override
  void dispose() {
    _cancelToken?.cancel('Timeline navigation cancelled');
    super.dispose();
  }
  
  /// Set timeline filters
  void setFilters({bool? local, bool? onlyMedia}) {
    final newLocal = local ?? state.local;
    final newOnlyMedia = onlyMedia ?? state.onlyMedia;
    
    // Only reload if filters actually changed
    if (newLocal != state.local || newOnlyMedia != state.onlyMedia) {
      state = state.copyWith(
        local: newLocal,
        onlyMedia: newOnlyMedia,
      );
      
      loadTimeline();
    }
  }
  
  /// Load the initial timeline
  Future<void> loadTimeline({int retryCount = 0, bool isRetry = false}) async {
    if (domain == null) return;
    
    // Only cancel if this is NOT a retry attempt - let retries use existing token
    if (!isRetry) {
      if (_cancelToken != null && !_cancelToken!.isCancelled) {
        _cancelToken!.cancel('New timeline request');
      }
      _cancelToken = CancelToken();
    }
    
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );
    
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        local: state.local,
        onlyMedia: state.onlyMedia,
        cancelToken: _cancelToken,
      );
      
      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }
      
      state = state.copyWith(
        statuses: statuses,
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      // Automatic retry for cancellation errors with longer delays to allow network requests to complete
      if (e is CancellationException && retryCount < 3) {
        final delay = Duration(milliseconds: 1000 * (retryCount + 1)); // 1s, 2s, 3s - more reasonable for network requests
        await Future.delayed(delay);
        return loadTimeline(retryCount: retryCount + 1, isRetry: true);
      }
      
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load timeline: $e',
      );
    }
  }
  
  /// Refresh the timeline
  Future<void> refreshTimeline() async {
    if (domain == null) return;
    
    // Cancel any previous request
    _cancelToken?.cancel('Timeline refresh');
    _cancelToken = CancelToken();
    
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        local: state.local,
        onlyMedia: state.onlyMedia,
        cancelToken: _cancelToken,
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
        errorMessage: 'Failed to refresh timeline: $e',
      );
    }
  }
  
  /// Load more posts
  Future<void> loadMore() async {
    if (domain == null || state.isLoading || !state.hasMore) return;
    
    // Cancel any previous request
    _cancelToken?.cancel('Load more request');
    _cancelToken = CancelToken();
    
    state = state.copyWith(
      isLoading: true,
    );
    
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        maxId: state.maxId,
        local: state.local,
        onlyMedia: state.onlyMedia,
        cancelToken: _cancelToken,
      );
      
      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }
      
      state = state.copyWith(
        statuses: [...state.statuses, ...statuses],
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load more posts: $e',
      );
    }
  }
  
  /// Update a status in the timeline
  void updateStatus(Status status) {
    final index = state.statuses.indexWhere((s) => s.id == status.id);
    
    if (index != -1) {
      final updatedStatuses = List<Status>.from(state.statuses);
      updatedStatuses[index] = status;
      
      state = state.copyWith(
        statuses: updatedStatuses,
      );
    }
  }
}

/// Provider for trending hashtags (fetches from /api/v1/trends/tags when available)
final trendingHashtagsProvider = FutureProvider<List<String>>((ref) async {
  final activeInstance = ref.watch(activeInstanceProvider);
  final domain = activeInstance?.domain;
  if (domain == null) return const <String>[];

  // Use ApiService directly to query the trends/tags endpoint
  final api = ref.watch(api_providers.apiServiceProvider);
  try {
    final response = await api.get('https://$domain/api/v1/trends/tags', queryParameters: {
      'limit': 10,
    });
    final data = response.data;
    if (data is List) {
      final names = data
          .map((e) => (e is Map && e['name'] is String) ? (e['name'] as String) : null)
          .whereType<String>()
          .toList();
      return names;
    }
    return const <String>[];
  } catch (e) {
    // Instances that do not support trends/tags should not break the UI
    if (e is NotFoundException) {
      return const <String>[];
    }
    // Re-throw other errors so the UI can show an error state
    rethrow;
  }
});

/// Trending posts timeline provider backed by a notifier for pagination
final trendingTimelineProvider = StateNotifierProvider<TrendingPostsNotifier, TimelineState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  return TrendingPostsNotifier(
    timelineService: timelineService,
    domain: activeInstance?.domain,
  );
});

class TrendingPostsNotifier extends StateNotifier<TimelineState> {
  final TimelineService timelineService;
  final String? domain;
  CancelToken? _cancelToken;
  bool _isFallbackMode = false; // true when using public timeline onlyMedia=true
  int _currentLimit = 20; // used for growing-window when trends endpoint exists

  TrendingPostsNotifier({
    required this.timelineService,
    required this.domain,
  }) : super(TimelineState(onlyMedia: true)) {
    if (domain != null) {
      loadInitial();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Trending navigation cancelled');
    super.dispose();
  }

  Future<void> loadInitial() async {
    if (domain == null) return;
    // Cancel ongoing
    _cancelToken?.cancel('Trending initial');
    _cancelToken = CancelToken();

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

    _currentLimit = 20;
    _isFallbackMode = false;

    try {
      // Try real trends endpoint first
      final statuses = await timelineService.getTrendingStatuses(
        domain!,
        limit: _currentLimit,
        cancelToken: _cancelToken,
      );

      state = state.copyWith(
        statuses: statuses,
        isLoading: false,
        // trends endpoint typically has no pagination; we simulate via growing window
        hasMore: true,
        maxId: statuses.isNotEmpty ? statuses.last.id : null,
      );
    } catch (e) {
      // Fallback to public timeline with only_media=true for real pagination
      _isFallbackMode = true;
      try {
        final statuses = await timelineService.getPublicTimeline(
          domain!,
          limit: 20,
          onlyMedia: true,
          cancelToken: _cancelToken,
        );
        state = state.copyWith(
          statuses: statuses,
          isLoading: false,
          hasMore: statuses.length >= 20,
          maxId: statuses.isNotEmpty ? statuses.last.id : null,
        );
      } catch (ee) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'Failed to load trending posts: $ee',
        );
      }
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (domain == null || state.isLoading || !state.hasMore) return;

    _cancelToken?.cancel('Trending load more');
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true);

    try {
      if (_isFallbackMode) {
        final statuses = await timelineService.getPublicTimeline(
          domain!,
          limit: 20,
          maxId: state.maxId,
          onlyMedia: true,
          cancelToken: _cancelToken,
        );
        final nextMaxId = statuses.isNotEmpty ? statuses.last.id : state.maxId;
        state = state.copyWith(
          statuses: [...state.statuses, ...statuses],
          isLoading: false,
          hasMore: statuses.length >= 20,
          maxId: nextMaxId,
        );
      } else {
        // Growing window approach for trends endpoint
        _currentLimit += 20;
        final fetched = await timelineService.getTrendingStatuses(
          domain!,
          limit: _currentLimit,
          cancelToken: _cancelToken,
        );
        // Append only new items (by id)
        final existingIds = state.statuses.map((s) => s.id).toSet();
        final newItems = fetched.where((s) => !existingIds.contains(s.id)).toList();
        final combined = [...state.statuses, ...newItems];
        state = state.copyWith(
          statuses: combined,
          isLoading: false,
          hasMore: fetched.length > state.statuses.length,
          maxId: combined.isNotEmpty ? combined.last.id : state.maxId,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load more trending posts: $e',
      );
    }
  }

  void updateStatus(Status status) {
    final index = state.statuses.indexWhere((s) => s.id == status.id);
    if (index != -1) {
      final updated = List<Status>.from(state.statuses);
      updated[index] = status;
      state = state.copyWith(statuses: updated);
    }
  }
}

/// Screen for exploring content
class ExploreScreen extends ConsumerStatefulWidget {
  /// Constructor
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentTabIndex = 0;
  bool _isSearchExpanded = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize with default tab count (will be updated in build)
    _tabController = TabController(length: 3, vsync: this);

    // Listen to tab changes to set filters appropriately
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return; // Ignore intermediate states during animation
      }

      final newIndex = _tabController.index;
      if (newIndex != _currentTabIndex) {
        setState(() {
          _currentTabIndex = newIndex;
        });
        _setFiltersForTab(newIndex);
      }
    });
  }

  void _updateTabController(bool isPixelfed) {
    final newTabCount = isPixelfed ? 3 : 4;
    if (_tabController.length != newTabCount) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: newTabCount, vsync: this);

      // Restore the tab index if it's still valid
      if (oldIndex < newTabCount) {
        _tabController.index = oldIndex;
        _currentTabIndex = oldIndex;
      } else {
        _currentTabIndex = 0;
      }

      // Re-add the listener
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          return;
        }

        final newIndex = _tabController.index;
        if (newIndex != _currentTabIndex) {
          setState(() {
            _currentTabIndex = newIndex;
          });
          _setFiltersForTab(newIndex);
        }
      });
    }
  }
  
  /// Set filters based on the tab index
  void _setFiltersForTab(int tabIndex) {
    final activeInstance = ref.read(activeInstanceProvider);
    final isPixelfed = activeInstance?.isPixelfed ?? false;
    final timelineNotifier = ref.read(publicTimelineProvider.notifier);

    if (isPixelfed) {
      // Pixelfed tabs: Posts, Hashtags, People
      switch (tabIndex) {
        case 0: // Posts tab
          timelineNotifier.setFilters(local: false, onlyMedia: true);
          break;
        // Hashtags and People tabs don't use timeline data
      }
    } else {
      // Mastodon tabs: Posts, News, Hashtags, People
      switch (tabIndex) {
        case 0: // Posts tab
          timelineNotifier.setFilters(local: false, onlyMedia: false);
          break;
        case 1: // News tab
          timelineNotifier.setFilters(local: false, onlyMedia: false);
          break;
        // Hashtags and People tabs don't use timeline data
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final isPixelfed = activeInstance?.isPixelfed ?? false;

    // Update tab controller if needed
    _updateTabController(isPixelfed);

    // Use standard platform-specific scaffold with proper TabBar integration
    if (Platform.isIOS) {
      return _buildIOSScaffold(context, isPixelfed);
    } else {
      return _buildMaterialScaffold(context, isPixelfed);
    }
  }

  /// Build iOS-style scaffold with CupertinoNavigationBar and segmented control
  Widget _buildIOSScaffold(BuildContext context, bool isPixelfed) {
    return CupertinoPageScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Navigation bar with title
            CupertinoNavigationBar(
              middle: const Text('Explore'),
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
            ),
            // Search bar
            _buildIOSSearchBar(context),
            // Segmented control for tabs
            _buildIOSSegmentedControl(context, isPixelfed),
            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: _buildIOSTabViews(context, isPixelfed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar and TabBar
  Widget _buildMaterialScaffold(BuildContext context, bool isPixelfed) {
    return Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar.medium(
                  title: _isSearchExpanded
                      ? _buildMaterialSearchField(context)
                      : const Text('Explore'),
                  pinned: true,
                  actions: _isSearchExpanded
                      ? [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = false;
                                _searchController.clear();
                              });
                            },
                          ),
                        ]
                      : [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                            },
                          ),
                        ],
                  bottom: _isSearchExpanded
                      ? null
                      : TabBar(
                          controller: _tabController,
                          tabs: _buildMaterialTabs(isPixelfed),
                        ),
                ),
              ),
              // Show tabs below search when expanded
              if (_isSearchExpanded)
                SliverToBoxAdapter(
                  child: Material(
                    elevation: 4,
                    child: TabBar(
                      controller: _tabController,
                      tabs: _buildMaterialTabs(isPixelfed),
                    ),
                  ),
                ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: _buildMaterialTabViews(context, isPixelfed),
          ),
        ),
    );
  }

  /// Build iOS search bar widget (native CupertinoSearchTextField)
  Widget _buildIOSSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Search hashtags, accounts...',
        onSubmitted: _handleSearchSubmitted,
        onChanged: (value) {
          // Optional: implement real-time search suggestions
        },
      ),
    );
  }

  /// Build Material search field for Android
  Widget _buildMaterialSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search hashtags, accounts...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white),
      onSubmitted: _handleSearchSubmitted,
    );
  }

  /// Handle search submission for both platforms
  Future<void> _handleSearchSubmitted(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    // If hashtag, go to tag timeline
    if (query.startsWith('#')) {
      final tag = query.substring(1).trim();
      if (tag.isNotEmpty && mounted) {
        context.push('/tag/$tag');
      }
      return;
    }

    // Try account search (e.g., @user or user@domain). If found, open first result.
    try {
      // Get references before async operations
      final activeInstance = ref.read(activeInstanceProvider);
      final accountService = ref.read(accountServiceProvider);
      final domain = activeInstance?.domain;

      if (domain != null) {
        final acctQuery = query.startsWith('@') ? query.substring(1) : query;
        final accounts = await accountService.searchAccounts(
          domain,
          query: acctQuery,
          limit: 1,
          resolve: true,
        );
        if (accounts.isNotEmpty && mounted) {
          context.push('/profile/${accounts.first.id}');
          return;
        }
      }
    } catch (_) {}

    // Fallback: navigate to tag timeline attempting to use the query as tag
    final fallbackTag = query.replaceAll('#', '').split(' ').first;
    if (fallbackTag.isNotEmpty && mounted) {
      context.push('/tag/$fallbackTag');
    }
  }

  /// Build Material tabs based on platform type
  List<Tab> _buildMaterialTabs(bool isPixelfed) {
    if (isPixelfed) {
      // Pixelfed: Posts, Hashtags, People
      return const [
        Tab(icon: Icon(Icons.photo_library), text: 'Posts'),
        Tab(icon: Icon(Icons.tag), text: 'Hashtags'),
        Tab(icon: Icon(Icons.people), text: 'People'),
      ];
    } else {
      // Mastodon: Posts, News, Hashtags, People
      return const [
        Tab(icon: Icon(Icons.article), text: 'Posts'),
        Tab(icon: Icon(Icons.newspaper), text: 'News'),
        Tab(icon: Icon(Icons.tag), text: 'Hashtags'),
        Tab(icon: Icon(Icons.people), text: 'People'),
      ];
    }
  }

  /// Build Material tab views based on platform type
  List<Widget> _buildMaterialTabViews(BuildContext context, bool isPixelfed) {
    if (isPixelfed) {
      // Pixelfed: Posts, Hashtags, People
      return [
        _buildMaterialPostsTab(context),
        _buildMaterialHashtagsTab(context),
        _buildMaterialPeopleTab(context),
      ];
    } else {
      // Mastodon: Posts, News, Hashtags, People
      return [
        _buildMaterialPostsTab(context),
        _buildMaterialNewsTab(context),
        _buildMaterialHashtagsTab(context),
        _buildMaterialPeopleTab(context),
      ];
    }
  }

  /// Build iOS tab views based on platform type
  List<Widget> _buildIOSTabViews(BuildContext context, bool isPixelfed) {
    if (isPixelfed) {
      // Pixelfed: Posts, Hashtags, People
      return [
        _buildPostsTab(),
        _buildHashtagsTab(),
        _buildPeopleTab(),
      ];
    } else {
      // Mastodon: Posts, News, Hashtags, People
      return [
        _buildPostsTab(),
        _buildNewsTab(),
        _buildHashtagsTab(),
        _buildPeopleTab(),
      ];
    }
  }

  /// Build iOS segmented control for tabs
  Widget _buildIOSSegmentedControl(BuildContext context, bool isPixelfed) {
    Map<int, Widget> children;

    if (isPixelfed) {
      // Pixelfed: Posts, Hashtags, People
      children = {
        0: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Posts'),
        ),
        1: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Hashtags'),
        ),
        2: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('People'),
        ),
      };
    } else {
      // Mastodon: Posts, News, Hashtags, People
      children = {
        0: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Posts'),
        ),
        1: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('News'),
        ),
        2: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Hashtags'),
        ),
        3: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('People'),
        ),
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _currentTabIndex,
        onValueChanged: (int? value) {
          if (value != null) {
            setState(() {
              _currentTabIndex = value;
            });
            _tabController.animateTo(value);
            _setFiltersForTab(value);
          }
        },
        children: children,
      ),
    );
  }



  /// Build the Posts tab (iOS)
  Widget _buildPostsTab() {
    final timelineState = ref.watch(publicTimelineProvider);
    final timelineNotifier = ref.read(publicTimelineProvider.notifier);

    return FeedList(
      statuses: timelineState.statuses,
      isLoading: timelineState.isLoading,
      hasError: timelineState.hasError,
      errorMessage: timelineState.errorMessage,
      hasMore: timelineState.hasMore,
      onLoadMore: timelineNotifier.loadMore,
      onRefresh: timelineNotifier.refreshTimeline,
      onPostLiked: (status, liked) {
        timelineNotifier.updateStatus(status);
      },
      onPostReblogged: (status, reblogged) {
        timelineNotifier.updateStatus(status);
      },
      onPostBookmarked: (status, bookmarked) {
        timelineNotifier.updateStatus(status);
      },
    );
  }



  /// Build the News tab (iOS - Mastodon only)
  Widget _buildNewsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'News',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'News content coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build the Hashtags tab (iOS)
  Widget _buildHashtagsTab() {
    final trendingHashtags = ref.watch(trendingHashtagsProvider);

    return trendingHashtags.when(
      data: (hashtags) {
        if (hashtags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No trending hashtags',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hashtags.length,
          itemBuilder: (context, index) {
            final hashtag = hashtags[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.tag),
                title: Text('#$hashtag'),
                subtitle: Text('Trending hashtag'),
                onTap: () {
                  context.push('/tag/$hashtag');
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading hashtags: $error'),
          ],
        ),
      ),
    );
  }

  /// Build the People tab (iOS)
  Widget _buildPeopleTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'People',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'People discovery coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build the Posts tab (Material)
  Widget _buildMaterialPostsTab(BuildContext context) {
    final timelineState = ref.watch(publicTimelineProvider);
    final timelineNotifier = ref.read(publicTimelineProvider.notifier);

    // Try to get the overlap handle, but handle the case where NestedScrollView isn't available yet
    SliverOverlapAbsorberHandle? overlapHandle;
    try {
      overlapHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    } catch (e) {
      // NestedScrollView not available in this context, use null
      overlapHandle = null;
    }

    return FeedList(
      statuses: timelineState.statuses,
      isLoading: timelineState.isLoading,
      hasError: timelineState.hasError,
      errorMessage: timelineState.errorMessage,
      hasMore: timelineState.hasMore,
      onLoadMore: timelineNotifier.loadMore,
      onRefresh: timelineNotifier.refreshTimeline,
      onPostLiked: (status, liked) {
        timelineNotifier.updateStatus(status);
      },
      onPostReblogged: (status, reblogged) {
        timelineNotifier.updateStatus(status);
      },
      onPostBookmarked: (status, bookmarked) {
        timelineNotifier.updateStatus(status);
      },
      wrapWithRefreshIndicator: false,
      overlapHandle: overlapHandle,
    );
  }

  /// Build the News tab (Material - Mastodon only)
  Widget _buildMaterialNewsTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildNewsTab(),
            ),
          ],
        );
      },
    );
  }

  /// Build the Hashtags tab (Material)
  Widget _buildMaterialHashtagsTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildHashtagsTab(),
            ),
          ],
        );
      },
    );
  }

  /// Build the People tab (Material)
  Widget _buildMaterialPeopleTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildPeopleTab(),
            ),
          ],
        );
      },
    );
  }
}
