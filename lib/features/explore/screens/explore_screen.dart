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

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentTabIndex = 0;
  bool _isSearchExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to tab changes to set filters appropriately
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return; // Ignore intermediate states during animation
      }
      
      final newIndex = _tabController.index;
      if (newIndex != _currentTabIndex) {
        _currentTabIndex = newIndex;
        _setFiltersForTab(newIndex);
      }
    });
    
    // Set initial filters for the first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setFiltersForTab(0);
    });
  }
  
  /// Set filters based on the tab index
  void _setFiltersForTab(int tabIndex) {
    final timelineNotifier = ref.read(publicTimelineProvider.notifier);
    
    switch (tabIndex) {
      case 0: // For You / Discover tab
        timelineNotifier.setFilters(local: false, onlyMedia: true);
        break;
      case 2: // Local / Community tab
        timelineNotifier.setFilters(local: true, onlyMedia: false);
        break;
      // Tab 1 is trending, which doesn't use timeline data
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
                index: _tabController.index,
                children: [
                  _buildForYouTab(),
                  _buildTrendingTab(),
                  _buildLocalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar and TabBar
  Widget _buildMaterialScaffold(BuildContext context, bool isPixelfed) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                          tabs: [
                            Tab(
                              icon: const Icon(Icons.explore),
                              text: isPixelfed ? 'Discover' : 'For You',
                            ),
                            const Tab(
                              icon: Icon(Icons.trending_up),
                              text: 'Trending',
                            ),
                            Tab(
                              icon: const Icon(Icons.location_city),
                              text: isPixelfed ? 'Local' : 'Community',
                            ),
                          ],
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
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.explore),
                          text: isPixelfed ? 'Discover' : 'For You',
                        ),
                        const Tab(
                          icon: Icon(Icons.trending_up),
                          text: 'Trending',
                        ),
                        Tab(
                          icon: const Icon(Icons.location_city),
                          text: isPixelfed ? 'Local' : 'Community',
                        ),
                      ],
                    ),
                  ),
                ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMaterialForYouTab(context),
              _buildMaterialTrendingTab(context),
              _buildMaterialLocalTab(context),
            ],
          ),
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

  /// Build iOS segmented control for tabs
  Widget _buildIOSSegmentedControl(BuildContext context, bool isPixelfed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _tabController.index,
        onValueChanged: (int? value) {
          if (value != null) {
            _tabController.animateTo(value);
          }
        },
        children: {
          0: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(isPixelfed ? 'Discover' : 'For You'),
          ),
          1: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Trending'),
          ),
          2: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(isPixelfed ? 'Local' : 'Community'),
          ),
        },
      ),
    );
  }

  /// Build Material tab content with proper overlap handling
  Widget _buildMaterialForYouTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildForYouTab(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialTrendingTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildTrendingTab(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialLocalTab(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: _buildLocalTab(),
            ),
          ],
        );
      },
    );
  }

  /// Build the For You / Discover tab
  Widget _buildForYouTab() {
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
  
  /// Build the Trending tab
  Widget _buildTrendingTab() {
    final trendingHashtags = ref.watch(trendingHashtagsProvider);
    final trendingState = ref.watch(trendingTimelineProvider);
    final trendingNotifier = ref.read(trendingTimelineProvider.notifier);

    Widget hashtagsHeader = trendingHashtags.when(
      data: (hashtags) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Hashtags',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hashtags.map((tag) {
                return ActionChip(
                  label: Text('#$tag'),
                  onPressed: () {
                    context.push('/tag/$tag');
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trending Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading trending hashtags...'),
          ],
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load trending hashtags: $error'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: hashtagsHeader,
        ),
        Expanded(
          child: FeedList(
            statuses: trendingState.statuses,
            isLoading: trendingState.isLoading,
            hasError: trendingState.hasError,
            errorMessage: trendingState.errorMessage,
            hasMore: trendingState.hasMore,
            onLoadMore: trendingNotifier.loadMore,
            onRefresh: trendingNotifier.refresh,
            onPostLiked: (status, liked) {
              trendingNotifier.updateStatus(status);
            },
            onPostReblogged: (status, reblogged) {
              trendingNotifier.updateStatus(status);
            },
            onPostBookmarked: (status, bookmarked) {
              trendingNotifier.updateStatus(status);
            },
          ),
        ),
      ],
    );
  }
  
  /// Build the Local / Community tab
  Widget _buildLocalTab() {
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
}
