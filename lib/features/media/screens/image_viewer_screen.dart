import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/models/status.dart';
import 'dart:io';

/// Fullscreen image viewer supporting multiple images and swipe/zoom.
class ImageViewerScreen extends StatefulWidget {
  final List<String>? imageUrls; // For backward compatibility
  final List<MediaAttachment>? mediaAttachments; // New parameter for alt text support
  final int initialIndex;
  final String? heroTagPrefix;

  const ImageViewerScreen({
    super.key,
    this.imageUrls,
    this.mediaAttachments,
    this.initialIndex = 0,
    this.heroTagPrefix,
  }) : assert(imageUrls != null || mediaAttachments != null, 'Either imageUrls or mediaAttachments must be provided');

  /// Constructor for backward compatibility with just URLs
  const ImageViewerScreen.fromUrls({
    super.key,
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) : imageUrls = imageUrls,
       mediaAttachments = null,
       initialIndex = initialIndex,
       heroTagPrefix = heroTagPrefix;

  /// Constructor for MediaAttachment objects with alt text support
  const ImageViewerScreen.fromAttachments({
    super.key,
    required List<MediaAttachment> mediaAttachments,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) : imageUrls = null,
       mediaAttachments = mediaAttachments,
       initialIndex = initialIndex,
       heroTagPrefix = heroTagPrefix;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _imageUrls {
    if (widget.imageUrls != null) {
      return widget.imageUrls!;
    } else {
      return widget.mediaAttachments!.map((a) => a.url).toList();
    }
  }

  List<MediaAttachment>? get _attachments => widget.mediaAttachments;

  @override
  Widget build(BuildContext context) {
    final imageUrls = _imageUrls;
    final attachments = _attachments;

    return AppPageScaffold.standard(
      title: '${_currentIndex + 1}/${imageUrls.length}',
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      actions: [
        // ALT button if current image has alt text
        if (attachments != null &&
            _currentIndex < attachments.length &&
            attachments[_currentIndex].description != null &&
            attachments[_currentIndex].description!.isNotEmpty)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ALT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () => _showAltTextDialog(context, attachments[_currentIndex].description!),
            tooltip: 'Show image description',
          ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: PhotoViewGallery.builder(
          pageController: _controller,
          itemCount: imageUrls.length,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          builder: (context, index) {
            final url = imageUrls[index];
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(url),
              heroAttributes: widget.heroTagPrefix != null
                  ? PhotoViewHeroAttributes(tag: '${widget.heroTagPrefix}_$index')
                  : null,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
            );
          },
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// Show alt text dialog with platform-specific styling
  void _showAltTextDialog(BuildContext context, String altText) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Image Description'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              altText,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Description'),
          content: SingleChildScrollView(
            child: Text(
              altText,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
