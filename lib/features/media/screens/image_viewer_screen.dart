import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Fullscreen image viewer supporting multiple images and swipe/zoom.
class ImageViewerScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${initialIndex + 1}/${imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: controller,
        itemCount: imageUrls.length,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (context, index) {
          final url = imageUrls[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(url),
            heroAttributes: heroTagPrefix != null
                ? PhotoViewHeroAttributes(tag: '${heroTagPrefix}_$index')
                : null,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3.0,
          );
        },
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
