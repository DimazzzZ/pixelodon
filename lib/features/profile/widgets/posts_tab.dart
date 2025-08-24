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
  });

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  MediaLayout _layout = MediaLayout.grid3;

  @override
  Widget build(BuildContext context) {
    // Ensure Pixelfed shows only media grid
    if (widget.isPixelfed && !widget.onlyMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onEnsureOnlyMedia(true);
      });
    }

    if (widget.isPixelfed) {
      // Provide toggle to switch between 3-column grid and single-column full-width
      if (widget.statuses.isEmpty) {
        // Provide a scrollable to enable pull-to-refresh (handled by outer indicator)
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildLayoutToggle(show: true),
            const SizedBox(height: 80),
            Center(
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('No posts yet'),
            ),
            const SizedBox(height: 120),
          ],
        );
      }

      return Column(
        children: [
          _buildLayoutToggle(show: true),
          Expanded(
            child: _layout == MediaLayout.grid3
                ? MasonryGridView.count(
                    key: const PageStorageKey('pixelfed_media_grid3'),
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.statuses.length + (widget.isLoading && widget.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.statuses.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final status = widget.statuses[index];
                      if (status.mediaAttachments.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final attachment = status.mediaAttachments.first;

                      return GestureDetector(
                        onTap: () {
                          if (status.id.isNotEmpty) {
                            context.push('/status/${status.id}');
                          }
                        },
                        child: CachedNetworkImage(
                          imageUrl: attachment.previewUrl ?? attachment.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.error)),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    key: const PageStorageKey('pixelfed_media_single'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.statuses.length + (widget.isLoading && widget.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.statuses.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final status = widget.statuses[index];
                      if (status.mediaAttachments.isEmpty) {
                        return const SizedBox.shrink();
                      }
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
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 280,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.error)),
                        ),
                      );

                      return GestureDetector(
                        onTap: () {
                          if (status.id.isNotEmpty) {
                            context.push('/status/${status.id}');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: aspectRatio != null
                                ? AspectRatio(
                                    aspectRatio: aspectRatio,
                                    child: image,
                                  )
                                : image,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // List for Mastodon
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
