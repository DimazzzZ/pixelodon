import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixelodon/models/status.dart';

/// Widget for displaying media attachments in a post
class MediaGallery extends StatefulWidget {
  /// The media attachments to display
  final List<MediaAttachment> attachments;
  
  /// Whether the media is sensitive
  final bool sensitive;
  
  /// Maximum height of the gallery
  final double maxHeight;
  
  /// Callback when an attachment is tapped
  final Function(int index)? onTap;
  
  /// Constructor
  const MediaGallery({
    super.key,
    required this.attachments,
    this.sensitive = false,
    this.maxHeight = 300,
    this.onTap,
  });

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  bool _showSensitiveContent = false;
  
  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // If content is sensitive and not revealed, show blur overlay
    if (widget.sensitive && !_showSensitiveContent) {
      return _buildSensitiveOverlay();
    }
    
    // Choose layout based on number of attachments
    if (widget.attachments.length == 1) {
      return _buildSingleAttachment();
    } else if (widget.attachments.length <= 4) {
      return _buildGridLayout();
    } else {
      return _buildCarouselLayout();
    }
  }
  
  /// Build a sensitive content overlay
  Widget _buildSensitiveOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSensitiveContent = true;
        });
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sensitive Content',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showSensitiveContent = true;
                  });
                },
                child: const Text('Show Content'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build layout for a single attachment
  Widget _buildSingleAttachment() {
    final attachment = widget.attachments.first;
    
    return GestureDetector(
      onTap: () => widget.onTap?.call(0),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.maxHeight,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildAttachmentWidget(attachment),
        ),
      ),
    );
  }
  
  /// Build a grid layout for 2-4 attachments
  Widget _buildGridLayout() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (int i = 0; i < widget.attachments.length; i++)
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(i),
                  child: _buildAttachmentWidget(widget.attachments[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Build a carousel layout for more than 4 attachments
  Widget _buildCarouselLayout() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.attachments.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => widget.onTap?.call(index),
            child: Container(
              width: 200,
              margin: EdgeInsets.only(
                right: index < widget.attachments.length - 1 ? 8 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildAttachmentWidget(widget.attachments[index]),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Build a widget for a specific attachment type
  Widget _buildAttachmentWidget(MediaAttachment attachment) {
    switch (attachment.type) {
      case AttachmentType.image:
        return _buildImageAttachment(attachment);
      case AttachmentType.video:
      case AttachmentType.gifv:
        return _buildVideoAttachment(attachment);
      case AttachmentType.audio:
        return _buildAudioAttachment(attachment);
      default:
        return _buildUnknownAttachment(attachment);
    }
  }
  
  /// Build an image attachment
  Widget _buildImageAttachment(MediaAttachment attachment) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurhash placeholder if available
        if (attachment.blurhash != null)
          Container(
            color: Colors.grey[300],
            // TODO: Implement blurhash rendering
          ),
        
        // Image
        CachedNetworkImage(
          imageUrl: attachment.previewUrl ?? attachment.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
        ),
        
        // Alt text indicator
        if (attachment.description != null && attachment.description!.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ALT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build a video attachment
  Widget _buildVideoAttachment(MediaAttachment attachment) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail
        CachedNetworkImage(
          imageUrl: attachment.previewUrl ?? attachment.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
        ),
        
        // Play button
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // Duration indicator
        if (attachment.duration != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(attachment.duration!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build an audio attachment
  Widget _buildAudioAttachment(MediaAttachment attachment) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.audiotrack,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              attachment.description ?? 'Audio',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (attachment.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(attachment.duration!),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build an unknown attachment type
  Widget _buildUnknownAttachment(MediaAttachment attachment) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.attachment,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  /// Format duration in seconds to MM:SS
  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
