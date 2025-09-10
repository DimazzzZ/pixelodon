import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/widgets/feed/images_list_view.dart';
import 'package:pixelodon/widgets/feed/image_grid_view.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'package:pixelodon/providers/settings_provider.dart';

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
    final homeViewMode = ref.watch(homeViewModeProvider);
    final homeContentFilter = ref.watch(homeContentFilterProvider);

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

    // Use standard platform-specific scaffold with proper TabBar integration
    if (Platform.isIOS) {
      return _buildIOSScaffold(context, ref, timelineState, timelineNotifier, activeInstance, homeViewMode, homeContentFilter);
    } else {
      return _buildMaterialScaffold(context, ref, timelineState, timelineNotifier, activeInstance, homeViewMode, homeContentFilter);
    }
  }

  /// Build title widget with appropriate icon for the instance type
  Widget _buildTitleWithIcon(Instance instance, {bool isIOS = false}) {
    final icon = instance.isPixelfed
        ? (isIOS ? CupertinoIcons.camera : Icons.camera_alt)
        : (isIOS ? CupertinoIcons.chat_bubble_text : Icons.forum);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isIOS ? 20 : 24,
          color: isIOS ? CupertinoColors.label : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            instance.domain,
            overflow: TextOverflow.ellipsis,
            style: isIOS ? null : null,
          ),
        ),
      ],
    );
  }

  /// Build iOS-style scaffold with CupertinoSliverNavigationBar and segmented control
  Widget _buildIOSScaffold(BuildContext context, WidgetRef ref, TimelineState timelineState, TimelineNotifier timelineNotifier, Instance activeInstance, String homeViewMode, String homeContentFilter) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return CupertinoPageScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Navigation bar with large title
            CupertinoNavigationBar(
              middle: _buildTitleWithIcon(activeInstance, isIOS: true),
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
              trailing: _buildViewModeButton(context, ref, isIOS: true),
            ),
            // Segmented control
            _buildIOSSegmentedControl(context, ref),
            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: selectedTabIndex,
                children: [
                  _buildIOSFollowingTab(context, ref, timelineState, timelineNotifier, homeViewMode, homeContentFilter, activeInstance.domain),
                  _buildIOSLocalTab(context, ref),
                  _buildIOSFederatedTab(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar and TabBar
  Widget _buildMaterialScaffold(BuildContext context, WidgetRef ref, TimelineState timelineState, TimelineNotifier timelineNotifier, Instance activeInstance, String homeViewMode, String homeContentFilter) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: selectedTabIndex,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar.large(
                  title: _buildTitleWithIcon(activeInstance),
                  pinned: true,
                  actions: [
                    _buildViewModeButton(context, ref, isIOS: false),
                  ],
                  bottom: TabBar(
                    onTap: (index) {
                      ref.read(homeTabIndexProvider.notifier).state = index;
                    },
                    tabs: const [
                      Tab(icon: Icon(Icons.home), text: 'Following'),
                      Tab(icon: Icon(Icons.location_city), text: 'Local'),
                      Tab(icon: Icon(Icons.public), text: 'Federated'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildFollowingTab(context, ref, timelineState, timelineNotifier, homeViewMode, homeContentFilter, activeInstance.domain),
              _buildLocalTab(context, ref),
              _buildFederatedTab(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  /// Build view mode button for switching between different view modes
  Widget _buildViewModeButton(BuildContext context, WidgetRef ref, {required bool isIOS}) {
    final homeViewMode = ref.watch(homeViewModeProvider);

    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showViewModeSelector(context, ref, isIOS: true),
        child: Icon(
          _getViewModeIcon(homeViewMode),
          color: CupertinoColors.label.resolveFrom(context),
        ),
      );
    } else {
      return IconButton(
        onPressed: () => _showViewModeSelector(context, ref, isIOS: false),
        icon: Icon(_getViewModeIcon(homeViewMode)),
      );
    }
  }

  IconData _getViewModeIcon(String viewMode) {
    switch (viewMode) {
      case 'list':
        return Icons.view_list;
      case 'images':
        return Icons.photo_library;
      case 'grid':
        return Icons.grid_view;
      default:
        return Icons.view_list;
    }
  }

  void _showViewModeSelector(BuildContext context, WidgetRef ref, {required bool isIOS}) {
    final settingsService = ref.read(settingsServiceProvider);
    final availableViewModes = settingsService.getAvailableHomeViewModes();
    final currentViewMode = ref.read(homeViewModeProvider);

    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('View Mode'),
          actions: availableViewModes.map((mode) {
            return CupertinoActionSheetAction(
              onPressed: () {
                ref.read(homeViewModeProvider.notifier).setHomeViewMode(mode);
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getViewModeIcon(mode)),
                  const SizedBox(width: 8),
                  Text(settingsService.getHomeViewModeDisplayName(mode)),
                  if (mode == currentViewMode) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.check_mark, size: 16),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'View Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...availableViewModes.map((mode) {
                return ListTile(
                  leading: Icon(_getViewModeIcon(mode)),
                  title: Text(settingsService.getHomeViewModeDisplayName(mode)),
                  trailing: mode == currentViewMode ? const Icon(Icons.check) : null,
                  onTap: () {
                    ref.read(homeViewModeProvider.notifier).setHomeViewMode(mode);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildIOSSegmentedControl(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selectedTabIndex,
        onValueChanged: (int? value) {
          if (value != null) {
            ref.read(homeTabIndexProvider.notifier).state = value;
          }
        },
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Following'),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Local'),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Federated'),
          ),
        },
      ),
    );
  }


  /// Build iOS Following tab content
  Widget _buildIOSFollowingTab(BuildContext context, WidgetRef ref, TimelineState timelineState, TimelineNotifier timelineNotifier, String homeViewMode, String homeContentFilter, String domain) {
    switch (homeViewMode) {
      case 'images':
        return ImagesListView(
          key: const Key('images_list_following'),
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
      case 'grid':
        return ImageGridView(
          key: const Key('image_grid_following'),
          statuses: timelineState.statuses,
          isLoading: timelineState.isLoading,
          hasError: timelineState.hasError,
          errorMessage: timelineState.errorMessage,
          hasMore: timelineState.hasMore,
          onLoadMore: timelineNotifier.loadMore,
          onRefresh: timelineNotifier.refreshTimeline,
        );
      case 'list':
      default:
        return FeedList(
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
          wrapWithRefreshIndicator: true,
        );
    }
  }

  /// Build iOS Local tab content
  Widget _buildIOSLocalTab(BuildContext context, WidgetRef ref) {
    return Consumer(
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
          wrapWithRefreshIndicator: true,
        );
      },
    );
  }

  /// Build iOS Federated tab content
  Widget _buildIOSFederatedTab(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final federatedState = ref.watch(federatedTimelineProvider);
        final federatedNotifier = ref.read(federatedTimelineProvider.notifier);
        return FeedList(
          key: const Key('feed_list_federated'),
          statuses: federatedState.statuses,
          isLoading: federatedState.isLoading,
          hasError: federatedState.hasError,
          errorMessage: federatedState.errorMessage,
          hasMore: federatedState.hasMore,
          onLoadMore: federatedNotifier.loadMore,
          onRefresh: federatedNotifier.refreshTimeline,
          onPostLiked: (status, liked) {
            federatedNotifier.updateStatus(status);
          },
          onPostReblogged: (status, reblogged) {
            federatedNotifier.updateStatus(status);
          },
          onPostBookmarked: (status, bookmarked) {
            federatedNotifier.updateStatus(status);
          },
          wrapWithRefreshIndicator: true,
        );
      },
    );
  }

  /// Build Following tab content
  Widget _buildFollowingTab(BuildContext context, WidgetRef ref, TimelineState timelineState, TimelineNotifier timelineNotifier, String homeViewMode, String homeContentFilter, String domain) {
    return Builder(
      builder: (context) {
        Widget content;

        switch (homeViewMode) {
          case 'images':
            content = ImagesListView(
              key: const Key('images_list_following'),
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
            break;
          case 'grid':
            content = ImageGridView(
              key: const Key('image_grid_following'),
              statuses: timelineState.statuses,
              isLoading: timelineState.isLoading,
              hasError: timelineState.hasError,
              errorMessage: timelineState.errorMessage,
              hasMore: timelineState.hasMore,
              onLoadMore: timelineNotifier.loadMore,
              onRefresh: timelineNotifier.refreshTimeline,
            );
            break;
          case 'list':
          default:
            content = FeedList(
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
            );
            break;
        }

        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: content,
            ),
          ],
        );
      },
    );
  }

  /// Build Local tab content
  Widget _buildLocalTab(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final localState = ref.watch(localTimelineProvider);
            final localNotifier = ref.read(localTimelineProvider.notifier);
            return CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverToBoxAdapter(
                  child: FeedList(
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build Federated tab content
  Widget _buildFederatedTab(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final federatedState = ref.watch(federatedTimelineProvider);
            final federatedNotifier = ref.read(federatedTimelineProvider.notifier);
            return CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverToBoxAdapter(
                  child: FeedList(
                    key: const Key('feed_list_federated'),
                    statuses: federatedState.statuses,
                    isLoading: federatedState.isLoading,
                    hasError: federatedState.hasError,
                    errorMessage: federatedState.errorMessage,
                    hasMore: federatedState.hasMore,
                    onLoadMore: federatedNotifier.loadMore,
                    onRefresh: federatedNotifier.refreshTimeline,
                    onPostLiked: (status, liked) {
                      federatedNotifier.updateStatus(status);
                    },
                    onPostReblogged: (status, reblogged) {
                      federatedNotifier.updateStatus(status);
                    },
                    onPostBookmarked: (status, bookmarked) {
                      federatedNotifier.updateStatus(status);
                    },
                    wrapWithRefreshIndicator: false,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
