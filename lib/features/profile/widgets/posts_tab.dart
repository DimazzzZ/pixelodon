import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/widgets/feed/feed_list.dart';

enum MediaLayout { grid3, single }

class PostsTab extends StatefulWidget {
  final List<model.Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final bool isPixelfed;
  final bool onlyMedia;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Function(bool onlyMedia) onEnsureOnlyMedia;
  final void Function(model.Status status) onStatusUpdated;
  final String? uniqueId; // Add unique identifier to prevent key conflicts

  const PostsTab({
    super.key,
    required this.statuses,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.hasMore,
    required this.isPixelfed,
    required this.onlyMedia,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onEnsureOnlyMedia,
    required this.onStatusUpdated,
    this.uniqueId,
  });

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  MediaLayout _layout = MediaLayout.grid3;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    final crossAxisCount = isTablet 
      ? (screenSize.width > 1200 ? 5 : 4) // Desktop: 5 cols, Tablet: 4 cols
      : 3; // Mobile: 3 cols
    
    // Ensure Pixelfed shows only media grid
    if (widget.isPixelfed && !widget.onlyMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onEnsureOnlyMedia(true);
      });
    }

    // For Posts tab: show grid layout for media posts
    if (widget.isPixelfed || widget.onlyMedia) {
      return _buildMediaGrid(crossAxisCount);
    }

    // For other tabs (Comments, Favorites, Bookmarks, Boosts): show list view
    return _buildFeedList();
  }

  Widget _buildMediaGrid(int crossAxisCount) {
    // Filter statuses to only include those with media attachments
    final mediaStatuses = widget.statuses.where((s) => s.mediaAttachments.isNotEmpty).toList();
    
    if (mediaStatuses.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.onlyMedia || widget.isPixelfed
                          ? 'No media posts yet'
                          : 'No posts yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
            ),
          ),
          if (widget.isPixelfed)
            Positioned(
              top: 8,
              right: 8,
              child: _buildLayoutToggle(show: true),
            ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _layout == MediaLayout.grid3 || !widget.isPixelfed
              ? _buildGrid(crossAxisCount, mediaStatuses)
              : _buildSingleColumnList(mediaStatuses),
        ),
        if (widget.isPixelfed)
          Positioned(
            top: 8,
            right: 8,
            child: _buildLayoutToggle(show: true),
          ),
      ],
    );
  }

  Widget _buildGrid(int crossAxisCount, List<model.Status> statuses) {
    final keyPrefix = widget.uniqueId ?? 'default';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MasonryGridView.count(
        key: PageStorageKey('${keyPrefix}_media_grid_$crossAxisCount'),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: statuses.length + (widget.isLoading && widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == statuses.length) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          final status = statuses[index];
          final attachment = status.mediaAttachments.first;

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () {
                if (status.id.isNotEmpty) {
                  context.push('/status/${status.id}');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  imageUrl: attachment.previewUrl ?? attachment.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleColumnList(List<model.Status> statuses) {
    final keyPrefix = widget.uniqueId ?? 'default';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        key: PageStorageKey('${keyPrefix}_media_single'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: statuses.length + (widget.isLoading && widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == statuses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final status = statuses[index];
          final attachment = status.mediaAttachments.first;

          // Determine aspect ratio if possible
          double? aspectRatio;
          final w = attachment.width;
          final h = attachment.height;
          if (w != null && h != null && w > 0 && h > 0) {
            aspectRatio = w / h;
          }

          final image = CachedNetworkImage(
            imageUrl: attachment.previewUrl ?? attachment.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 280,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 280,
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          );

          return GestureDetector(
            onTap: () {
              if (status.id.isNotEmpty) {
                context.push('/status/${status.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: aspectRatio != null
                      ? AspectRatio(
                          aspectRatio: aspectRatio,
                          child: image,
                        )
                      : image,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedList() {
    return FeedList(
      statuses: widget.statuses,
      isLoading: widget.isLoading,
      hasError: widget.hasError,
      errorMessage: widget.errorMessage,
      hasMore: widget.hasMore,
      onLoadMore: widget.onLoadMore,
      onRefresh: widget.onRefresh,
      onPostLiked: (status, liked) => widget.onStatusUpdated(status),
      onPostReblogged: (status, reblogged) => widget.onStatusUpdated(status),
      onPostBookmarked: (status, bookmarked) => widget.onStatusUpdated(status),
      wrapWithRefreshIndicator: false,
    );
  }

  Widget _buildLayoutToggle({required bool show}) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                icon: Icons.grid_view,
                selected: _layout == MediaLayout.grid3,
                onTap: () => setState(() => _layout = MediaLayout.grid3),
                tooltip: 'Grid view',
              ),
              _buildToggleButton(
                icon: Icons.view_agenda_outlined,
                selected: _layout == MediaLayout.single,
                onTap: () => setState(() => _layout = MediaLayout.single),
                tooltip: 'Single column',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey[600];
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
