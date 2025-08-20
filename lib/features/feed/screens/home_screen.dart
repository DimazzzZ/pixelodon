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
          : FeedList(
              statuses: timelineState.statuses,
              isLoading: timelineState.isLoading,
              hasError: timelineState.hasError,
              errorMessage: timelineState.errorMessage,
              hasMore: timelineState.hasMore,
              onLoadMore: timelineNotifier.loadMore,
              onRefresh: timelineNotifier.refreshTimeline,
              onPostLiked: (status, liked) {
                // Status is already updated in the PostCard widget
                timelineNotifier.updateStatus(status);
              },
              onPostReblogged: (status, reblogged) {
                // Status is already updated in the PostCard widget
                timelineNotifier.updateStatus(status);
              },
              onPostBookmarked: (status, bookmarked) {
                // Status is already updated in the PostCard widget
                timelineNotifier.updateStatus(status);
              },
            ),
    );
  }
}
