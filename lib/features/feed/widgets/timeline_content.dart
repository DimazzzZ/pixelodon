import 'package:flutter/material.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/widgets/feed/image_grid_view.dart';
import 'package:pixelodon/widgets/feed/images_list_view.dart';

class TimelineContent extends StatelessWidget {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(Status, bool) updateStatus;
  final String viewMode;
  final String domain;
  final String tabKey;
  final bool wrapWithRefreshIndicator;
  final SliverOverlapAbsorberHandle? overlapHandle;

  const TimelineContent({
    super.key,
    required this.statuses,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.updateStatus,
    required this.viewMode,
    required this.domain,
    required this.tabKey,
    this.wrapWithRefreshIndicator = true,
    this.overlapHandle,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case 'images':
        return ImagesListView(
          key: Key('images_list_$tabKey'),
          statuses: statuses,
          domain: domain,
          isLoading: isLoading,
          hasError: hasError,
          errorMessage: errorMessage,
          hasMore: hasMore,
          onLoadMore: onLoadMore,
          onRefresh: onRefresh,
          overlapHandle: overlapHandle,
        );
      case 'grid':
        return ImageGridView(
          key: Key('image_grid_$tabKey'),
          statuses: statuses,
          isLoading: isLoading,
          hasError: hasError,
          errorMessage: errorMessage,
          hasMore: hasMore,
          onLoadMore: onLoadMore,
          onRefresh: onRefresh,
          overlapHandle: overlapHandle,
        );
      case 'list':
      default:
        return FeedList(
          key: Key('feed_list_$tabKey'),
          statuses: statuses,
          isLoading: isLoading,
          hasError: hasError,
          errorMessage: errorMessage,
          hasMore: hasMore,
          onLoadMore: onLoadMore,
          onRefresh: onRefresh,
          onPostLiked: (status, liked) {
            updateStatus(status, liked);
          },
          onPostReblogged: (status, reblogged) {
            updateStatus(status, reblogged);
          },
          onPostBookmarked: (status, bookmarked) {
            updateStatus(status, bookmarked);
          },
          wrapWithRefreshIndicator: wrapWithRefreshIndicator,
          overlapHandle: overlapHandle,
        );
    }
  }
}
