import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'package:pixelodon/features/feed/state/timeline_providers.dart';
import 'package:pixelodon/features/feed/state/timeline_state.dart';
import 'package:pixelodon/features/feed/widgets/timeline_content.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(homeTimelineProvider);
    final timelineNotifier = ref.read(homeTimelineProvider.notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    final homeViewMode = ref.watch(homeViewModeNotifierProvider);
    final homeContentFilter = ref.watch(homeContentFilterNotifierProvider);

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
      crossAxisAlignment: CrossAxisAlignment.center,
      textBaseline: TextBaseline.alphabetic,
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
            style: isIOS
                ? null
                : Platform.isAndroid
                    ? const TextStyle(
                        textBaseline: TextBaseline.alphabetic,
                        height: 1.0, // Reduce line height to align better with icon
                      )
                    : null,
          ),
        ),
      ],
    );
  }

  /// Build iOS-style scaffold with CupertinoSliverNavigationBar and segmented control
  Widget _buildIOSScaffold(BuildContext context, WidgetRef ref, TimelineState timelineState, HomeTimeline timelineNotifier, Instance activeInstance, String homeViewMode, String homeContentFilter) {
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
                  TimelineContent(
                    statuses: timelineState.statuses,
                    isLoading: timelineState.isLoading,
                    hasError: timelineState.hasError,
                    errorMessage: timelineState.errorMessage,
                    hasMore: timelineState.hasMore,
                    onLoadMore: timelineNotifier.loadMore,
                    onRefresh: timelineNotifier.refreshTimeline,
                    updateStatus: (status, _) => timelineNotifier.updateStatus(status),
                    viewMode: homeViewMode,
                    domain: activeInstance.domain,
                    tabKey: 'following',
                  ),
                  Consumer(builder: (context, ref, _) {
                    final state = ref.watch(localTimelineProvider);
                    final notifier = ref.read(localTimelineProvider.notifier);
                    return TimelineContent(
                      statuses: state.statuses,
                      isLoading: state.isLoading,
                      hasError: state.hasError,
                      errorMessage: state.errorMessage,
                      hasMore: state.hasMore,
                      onLoadMore: notifier.loadMore,
                      onRefresh: notifier.refreshTimeline,
                      updateStatus: (status, _) => notifier.updateStatus(status),
                      viewMode: homeViewMode,
                      domain: activeInstance.domain,
                      tabKey: 'local',
                    );
                  }),
                  Consumer(builder: (context, ref, _) {
                    final state = ref.watch(federatedTimelineProvider);
                    final notifier = ref.read(federatedTimelineProvider.notifier);
                    return TimelineContent(
                      statuses: state.statuses,
                      isLoading: state.isLoading,
                      hasError: state.hasError,
                      errorMessage: state.errorMessage,
                      hasMore: state.hasMore,
                      onLoadMore: notifier.loadMore,
                      onRefresh: notifier.refreshTimeline,
                      updateStatus: (status, _) => notifier.updateStatus(status),
                      viewMode: homeViewMode,
                      domain: activeInstance.domain,
                      tabKey: 'federated',
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material 3 scaffold with SliverAppBar and TabBar
  Widget _buildMaterialScaffold(BuildContext context, WidgetRef ref, TimelineState timelineState, HomeTimeline timelineNotifier, Instance activeInstance, String homeViewMode, String homeContentFilter) {
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
                      ref.read(homeTabIndexProvider.notifier).setIndex(index);
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
              Builder(builder: (context) {
                return TimelineContent(
                  statuses: timelineState.statuses,
                  isLoading: timelineState.isLoading,
                  hasError: timelineState.hasError,
                  errorMessage: timelineState.errorMessage,
                  hasMore: timelineState.hasMore,
                  onLoadMore: timelineNotifier.loadMore,
                  onRefresh: timelineNotifier.refreshTimeline,
                  updateStatus: (status, _) => timelineNotifier.updateStatus(status),
                  viewMode: homeViewMode,
                  domain: activeInstance.domain,
                  tabKey: 'following',
                  wrapWithRefreshIndicator: false,
                  overlapHandle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                );
              }),
              Builder(builder: (context) {
                return Consumer(builder: (context, ref, _) {
                  final state = ref.watch(localTimelineProvider);
                  final notifier = ref.read(localTimelineProvider.notifier);
                  return TimelineContent(
                    statuses: state.statuses,
                    isLoading: state.isLoading,
                    hasError: state.hasError,
                    errorMessage: state.errorMessage,
                    hasMore: state.hasMore,
                    onLoadMore: notifier.loadMore,
                    onRefresh: notifier.refreshTimeline,
                    updateStatus: (status, _) => notifier.updateStatus(status),
                    viewMode: homeViewMode,
                    domain: activeInstance.domain,
                    tabKey: 'local',
                    wrapWithRefreshIndicator: false,
                    overlapHandle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  );
                });
              }),
              Builder(builder: (context) {
                return Consumer(builder: (context, ref, _) {
                  final state = ref.watch(federatedTimelineProvider);
                  final notifier = ref.read(federatedTimelineProvider.notifier);
                  return TimelineContent(
                    statuses: state.statuses,
                    isLoading: state.isLoading,
                    hasError: state.hasError,
                    errorMessage: state.errorMessage,
                    hasMore: state.hasMore,
                    onLoadMore: notifier.loadMore,
                    onRefresh: notifier.refreshTimeline,
                    updateStatus: (status, _) => notifier.updateStatus(status),
                    viewMode: homeViewMode,
                    domain: activeInstance.domain,
                    tabKey: 'federated',
                    wrapWithRefreshIndicator: false,
                    overlapHandle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Build view mode button for switching between different view modes
  Widget _buildViewModeButton(BuildContext context, WidgetRef ref, {required bool isIOS}) {
    final homeViewMode = ref.watch(homeViewModeNotifierProvider);

    if (isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.all(0),
        minSize: 0,
        onPressed: () => _showViewModeSelector(context, ref, isIOS: true),
        child: Icon(
          _getViewModeIcon(homeViewMode),
          color: CupertinoColors.activeBlue.resolveFrom(context),
          size: 22,
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
    final currentViewMode = ref.read(homeViewModeNotifierProvider);

    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('View Mode'),
          actions: availableViewModes.map((mode) {
            return CupertinoActionSheetAction(
              onPressed: () {
                ref.read(homeViewModeNotifierProvider.notifier).setHomeViewMode(mode);
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
                    ref.read(homeViewModeNotifierProvider.notifier).setHomeViewMode(mode);
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
            ref.read(homeTabIndexProvider.notifier).setIndex(value);
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
}
