import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/core/theme/app_theme.dart';

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
  final TimelineService timelineService;
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

/// Provider for the selected tab index in the home screen
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(homeTimelineProvider);
    final timelineNotifier = ref.read(homeTimelineProvider.notifier);
    final activeInstance = ref.watch(activeInstanceProvider);

    if (activeInstance == null) {
      return AppPageScaffold.standard(
        title: 'Pixelodon',
        body: Container(
          color: AppTheme.pageBg(context),
          child: const Center(
            child: Text('No active instance selected'),
          ),
        ),
      );
    }

    return AppPageScaffold.sliver(
      largeTitle: 'Pixelodon',
      sliverBodyBuilder: () => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildTabSelector(context, ref),
          ),
          _buildSelectedTabContent(context, ref, timelineState, timelineNotifier),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppTheme.pageBg(context),
      padding: EdgeInsets.only(
        left: Platform.isIOS ? 20 : 16,
        right: Platform.isIOS ? 20 : 16,
        top: 8,
        bottom: 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(Platform.isIOS ? 10 : 12),
          border: Platform.isIOS ? Border.all(
            color: AppTheme.separator(context),
            width: 0.5,
          ) : null,
        ),
        child: Platform.isIOS ? _buildIOSSegmentedControl(context, ref) : _buildAndroidTabBar(context, ref),
      ),
    );
  }

  Widget _buildIOSSegmentedControl(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return CupertinoSlidingSegmentedControl<int>(
      groupValue: selectedTabIndex,
      onValueChanged: (int? value) {
        if (value != null) {
          ref.read(homeTabIndexProvider.notifier).state = value;
        }
      },
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.home, size: 16),
              SizedBox(width: 6),
              Text('Following', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.building_2_fill, size: 16),
              SizedBox(width: 6),
              Text('Local', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        2: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.globe, size: 16),
              SizedBox(width: 6),
              Text('Federated', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      },
    );
  }

  Widget _buildAndroidTabBar(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: selectedTabIndex,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          tabBarTheme: Theme.of(context).tabBarTheme.copyWith(
            indicator: BoxDecoration(
              color: AppTheme.tertiaryBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        child: TabBar(
          onTap: (index) {
            ref.read(homeTabIndexProvider.notifier).state = index;
          },
          padding: const EdgeInsets.all(4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              key: Key('following_tab'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Following', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Tab(
              key: Key('local_tab'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Local', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Tab(
              key: Key('federated_tab'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 18),
                  SizedBox(width: 6),
                  Text('Federated', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context, WidgetRef ref, TimelineState timelineState, TimelineNotifier timelineNotifier) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);
    Widget content;

    switch (selectedTabIndex) {
      case 0:
        // Following
        content = Transform.translate(
          offset: const Offset(0, -8), // Move content up by 8 pixels
          child: FeedList(
            key: const Key('feed_list_following'),
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
          ),
        );
        break;
      case 1:
        // Local (public local)
        content = Transform.translate(
          offset: const Offset(0, -8), // Move content up by 8 pixels
          child: Consumer(
            builder: (context, ref, child) {
              final localState = ref.watch(localTimelineProvider);
              final localNotifier = ref.read(localTimelineProvider.notifier);
              return FeedList(
                key: const Key('feed_list_local'),
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
                wrapWithRefreshIndicator: false,
              );
            },
          ),
        );
        break;
      case 2:
      default:
        // Federated (public federated)
        content = Transform.translate(
          offset: const Offset(0, -8), // Move content up by 8 pixels
          child: Consumer(
            builder: (context, ref, child) {
              final fedState = ref.watch(federatedTimelineProvider);
              final fedNotifier = ref.read(federatedTimelineProvider.notifier);
              return FeedList(
                key: const Key('feed_list_federated'),
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
                wrapWithRefreshIndicator: false,
              );
            },
          ),
        );
        break;
    }

    return SliverFillRemaining(
      hasScrollBody: true,
      fillOverscroll: false,
      child: ColoredBox(
        color: AppTheme.pageBg(context),
        child: content,
      ),
    );
  }
}
