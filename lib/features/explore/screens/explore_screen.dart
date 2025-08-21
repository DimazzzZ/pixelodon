import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';
import 'package:pixelodon/core/network/api_service.dart';

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
  final timelineService;
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

/// Provider for trending hashtags (kept simple; can be wired to API later)
final trendingHashtagsProvider = FutureProvider<List<String>>((ref) async {
  // TODO: Replace with real endpoint (e.g., /api/v1/trends/tags) when available
  await Future.delayed(const Duration(milliseconds: 300));
  return const [
    'photography',
    'art',
    'nature',
    'technology',
    'travel',
    'food',
    'music',
    'fashion',
    'sports',
    'science',
  ];
});

/// Provider for trending posts
final trendingPostsProvider = FutureProvider<List<Status>>((ref) async {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  final domain = activeInstance?.domain;
  if (domain == null) return [];
  try {
    return await timelineService.getTrendingStatuses(domain, limit: 20);
  } catch (_) {
    // Fail safely
    return [];
  }
});

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
  int _currentTabIndex = 0;
  
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final isPixelfed = activeInstance?.isPixelfed ?? false;
    
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onSubmitted: (value) async {
                final query = value.trim();
                if (query.isEmpty) return;
                // If hashtag, go to tag timeline
                if (query.startsWith('#')) {
                  final tag = query.substring(1).trim();
                  if (tag.isNotEmpty) context.push('/tag/$tag');
                  return;
                }
                // Try account search (e.g., @user or user@domain). If found, open first result.
                try {
                  final container = ProviderScope.containerOf(context);
                  final active = container.read(activeInstanceProvider);
                  final domain = active?.domain;
                  if (domain != null) {
                    final acctQuery = query.startsWith('@') ? query.substring(1) : query;
                    final accountService = container.read(accountServiceProvider);
                    final accounts = await accountService.searchAccounts(
                      domain,
                      query: acctQuery,
                      limit: 1,
                      resolve: true,
                    );
                    if (accounts.isNotEmpty) {
                      if (mounted) context.push('/profile/${accounts.first.id}');
                      return;
                    }
                  }
                } catch (_) {}
                // Fallback: navigate to tag timeline attempting to use the query as tag
                final fallbackTag = query.replaceAll('#', '').split(' ').first;
                if (fallbackTag.isNotEmpty) context.push('/tag/$fallbackTag');
              },
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: isPixelfed ? 'Discover' : 'For You'),
              const Tab(text: 'Trending'),
              Tab(text: isPixelfed ? 'Local' : 'Community'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // For You / Discover tab
                _buildForYouTab(),
                
                // Trending tab
                _buildTrendingTab(),
                
                // Local / Community tab
                _buildLocalTab(),
              ],
            ),
          ),
        ],
      ),
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
    
    return trendingHashtags.when(
      data: (hashtags) {
        return ListView(
          padding: const EdgeInsets.all(16),
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
                    // Navigate to hashtag timeline
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
            const SizedBox(height: 16),
            // Trending posts
            Consumer(builder: (context, ref, _) {
              final posts = ref.watch(trendingPostsProvider);
              final activeInstance = ref.watch(activeInstanceProvider);
              return posts.when(
                data: (statuses) {
                  if (statuses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No trending posts available right now.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      return PostCard(
                        status: status,
                        domain: activeInstance?.domain ?? '',
                        onLiked: (_) {},
                        onReblogged: (_) {},
                        onBookmarked: (_) {},
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Failed to load trending posts: $e'),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Error loading trending content: $error'),
      ),
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
