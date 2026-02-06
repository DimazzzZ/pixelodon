import 'package:pixelodon/models/status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';

part 'timeline_state.g.dart';

/// Type alias for timeline notifiers for backward compatibility
typedef TimelineNotifier = HomeTimeline;

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

/// Provider for the selected tab index in the home screen
@Riverpod(keepAlive: true)
class HomeTabIndex extends _$HomeTabIndex {
  @override
  int build() => 0;
  
  void setIndex(int index) {
    state = index;
  }
}

/// Notifier for the home timeline
@Riverpod(keepAlive: true)
class HomeTimeline extends _$HomeTimeline {
  @override
  TimelineState build() {
    // Initial load
    Future.microtask(() => loadTimeline());
    return TimelineState();
  }
  
  /// Load the initial timeline
  Future<void> loadTimeline() async {
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;
    
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );
    
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getHomeTimeline(
        domain,
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
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;
    
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getHomeTimeline(
        domain,
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
    if (state.isLoading || !state.hasMore) return;
    
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;
    
    state = state.copyWith(
      isLoading: true,
    );
    
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getHomeTimeline(
        domain,
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

@Riverpod(keepAlive: true)
class LocalTimeline extends _$LocalTimeline {
  @override
  TimelineState build() {
    Future.microtask(() => loadTimeline());
    return TimelineState();
  }
  
  Future<void> loadTimeline() async {
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        local: true,
        remote: false,
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
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        local: true,
        remote: false,
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
    if (state.isLoading || !state.hasMore) return;
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    state = state.copyWith(isLoading: true);
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        maxId: state.maxId,
        local: true,
        remote: false,
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

@Riverpod(keepAlive: true)
class FederatedTimeline extends _$FederatedTimeline {
  @override
  TimelineState build() {
    Future.microtask(() => loadTimeline());
    return TimelineState();
  }
  
  Future<void> loadTimeline() async {
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        local: false,
        remote: true,
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
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        local: false,
        remote: true,
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
    if (state.isLoading || !state.hasMore) return;
    final activeInstance = ref.read(activeInstanceProvider);
    if (activeInstance?.domain == null) return;
    final domain = activeInstance!.domain;

    state = state.copyWith(isLoading: true);
    try {
      final timelineService = ref.read(timelineServiceProvider);
      final statuses = await timelineService.getPublicTimeline(
        domain,
        limit: 20,
        maxId: state.maxId,
        local: false,
        remote: true,
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
