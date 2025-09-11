import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';


/// Widget for displaying posts in a three-column image grid
class ImageGridView extends ConsumerWidget {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;
  final SliverOverlapAbsorberHandle? overlapHandle;

  const ImageGridView({
    super.key,
    required this.statuses,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.onLoadMore,
    this.onRefresh,
    this.overlapHandle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter statuses to only include those with images
    final imageStatuses = statuses.where((status) {
      return status.mediaAttachments.any((media) =>
        media.type == AttachmentType.image || media.type == AttachmentType.gifv);
    }).toList();

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Failed to load images',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (imageStatuses.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No images found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Posts with images will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            hasMore && !isLoading) {
          onLoadMore?.call();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          if (overlapHandle != null)
            SliverOverlapInjector(handle: overlapHandle!),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              onRefresh?.call();
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.all(4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= imageStatuses.length) {
                    // Loading placeholder
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final status = imageStatuses[index];
                  final imageMedia = status.mediaAttachments.firstWhere(
                    (media) => media.type == AttachmentType.image || media.type == AttachmentType.gifv,
                  );

                  return _buildImageTile(context, status, imageMedia);
                },
                childCount: imageStatuses.length + (isLoading ? 3 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(BuildContext context, Status status, MediaAttachment media) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail
        context.push('/status/${status.id}');
      },
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                media.previewUrl ?? media.url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 32,
                    ),
                  );
                },
              ),
              
              // Overlay for multiple images indicator
              if (status.mediaAttachments.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${status.mediaAttachments.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // GIF indicator
              if (media.type == AttachmentType.gifv)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
