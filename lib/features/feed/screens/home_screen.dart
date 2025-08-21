import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';

/// Provider for the home timeline
final homeTimelineProvider = StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  
  return TimelineNotifier(
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
  
  TimelineState({
    this.statuses = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
  });
  
  TimelineState copyWith({
    List<Status>? statuses,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
  }) {
    return TimelineState(
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
    );
  }
}

/// Notifier for a timeline
class TimelineNotifier extends StateNotifier<TimelineState> {
  final timelineService;
  final String? domain;
  
  TimelineNotifier({
    required this.timelineService,
    this.domain,
  }) : super(TimelineState()) {
    if (domain != null) {
      loadTimeline();
    }
  }
  
  /// Load the initial timeline
  Future<void> loadTimeline() async {
    if (domain == null) return;
    
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );
    
    try {
      final statuses = await timelineService.getHomeTimeline(
        domain!,
        limit: 20,
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
    
    try {
      final statuses = await timelineService.getHomeTimeline(
        domain!,
        limit: 20,
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
    
    state = state.copyWith(
      isLoading: true,
    );
    
    try {
      final statuses = await timelineService.getHomeTimeline(
        domain!,
        limit: 20,
        maxId: state.maxId,
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

/// Screen for displaying the home timeline
/// Notifier for public timelines (Local and Federated)
class PublicTimelineNotifier extends StateNotifier<TimelineState> {
  final dynamic timelineService;
  final String? domain;
  final bool? local; // true for Local
  final bool? remote; // true for Federated
  
  PublicTimelineNotifier({
    required this.timelineService,
    required this.domain,
    this.local,
    this.remote,
  }) : super(TimelineState()) {
    if (domain != null) {
      loadTimeline();
    }
  }
  
  Future<void> loadTimeline() async {
    if (domain == null) return;
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        local: local,
        remote: remote,
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
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load timeline: $e',
      );
    }
  }
  
  Future<void> refreshTimeline() async {
    if (domain == null) return;
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        local: local,
        remote: remote,
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
  
  Future<void> loadMore() async {
    if (domain == null || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final statuses = await timelineService.getPublicTimeline(
        domain!,
        limit: 20,
        maxId: state.maxId,
        local: local,
        remote: remote,
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
  
  void updateStatus(Status status) {
    final index = state.statuses.indexWhere((s) => s.id == status.id);
    if (index != -1) {
      final updatedStatuses = List<Status>.from(state.statuses);
      updatedStatuses[index] = status;
      state = state.copyWith(statuses: updatedStatuses);
    }
  }
}

/// Providers for Local and Federated timelines on Home
final localTimelineProvider = StateNotifierProvider<PublicTimelineNotifier, TimelineState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  return PublicTimelineNotifier(
    timelineService: timelineService,
    domain: activeInstance?.domain,
    local: true,
  );
});

final federatedTimelineProvider = StateNotifierProvider<PublicTimelineNotifier, TimelineState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  return PublicTimelineNotifier(
    timelineService: timelineService,
    domain: activeInstance?.domain,
    local: false,
    remote: true,
  );
});

class HomeScreen extends ConsumerWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(homeTimelineProvider);
    final timelineNotifier = ref.read(homeTimelineProvider.notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    
    return Scaffold(
      body: activeInstance == null
          ? const Center(
              child: Text('No active instance selected'),
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.home_outlined), text: 'Following'),
                      Tab(icon: Icon(Icons.apartment_outlined), text: 'Local'),
                      Tab(icon: Icon(Icons.public), text: 'Federated'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Following
                        FeedList(
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
                        ),
                        // Local (public local)
                        Builder(
                          builder: (context) {
                            final localState = ref.watch(localTimelineProvider);
                            final localNotifier = ref.read(localTimelineProvider.notifier);
                            return FeedList(
                              statuses: localState.statuses,
                              isLoading: localState.isLoading,
                              hasError: localState.hasError,
                              errorMessage: localState.errorMessage,
                              hasMore: localState.hasMore,
                              onLoadMore: localNotifier.loadMore,
                              onRefresh: localNotifier.refreshTimeline,
                              onPostLiked: (status, liked) {
                                localNotifier.updateStatus(status);
                              },
                              onPostReblogged: (status, reblogged) {
                                localNotifier.updateStatus(status);
                              },
                              onPostBookmarked: (status, bookmarked) {
                                localNotifier.updateStatus(status);
                              },
                            );
                          },
                        ),
                        // Federated (public federated)
                        Builder(
                          builder: (context) {
                            final fedState = ref.watch(federatedTimelineProvider);
                            final fedNotifier = ref.read(federatedTimelineProvider.notifier);
                            return FeedList(
                              statuses: fedState.statuses,
                              isLoading: fedState.isLoading,
                              hasError: fedState.hasError,
                              errorMessage: fedState.errorMessage,
                              hasMore: fedState.hasMore,
                              onLoadMore: fedNotifier.loadMore,
                              onRefresh: fedNotifier.refreshTimeline,
                              onPostLiked: (status, liked) {
                                fedNotifier.updateStatus(status);
                              },
                              onPostReblogged: (status, reblogged) {
                                fedNotifier.updateStatus(status);
                              },
                              onPostBookmarked: (status, bookmarked) {
                                fedNotifier.updateStatus(status);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
