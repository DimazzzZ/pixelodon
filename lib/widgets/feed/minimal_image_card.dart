import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pixelodon/models/status.dart';
import 'dart:io';

/// Minimal image card for seamless image feed experience
/// Shows only the image with user avatar and name overlay
class MinimalImageCard extends ConsumerWidget {
  final Status status;
  final String domain;

  const MinimalImageCard({
    super.key,
    required this.status,
    required this.domain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Platform.isIOS;
    final theme = Theme.of(context);
    
    // Get the first image attachment
    final imageAttachment = status.mediaAttachments.firstWhere(
      (media) => media.type == AttachmentType.image || media.type == AttachmentType.gifv,
    );

    return GestureDetector(
      onTap: () {
        context.push('/status/${status.id}');
      },
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            // Main image
            _buildImage(context, imageAttachment),
            
            // User info overlay (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: _buildUserOverlay(context, isIOS, theme),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the main image
  Widget _buildImage(BuildContext context, MediaAttachment attachment) {
    return AspectRatio(
      aspectRatio: _calculateAspectRatio(attachment),
      child: ClipRRect(
        borderRadius: BorderRadius.zero, // No border radius for seamless look
        child: CachedNetworkImage(
          imageUrl: attachment.url,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Platform.isIOS 
                ? CupertinoColors.systemGrey5.resolveFrom(context)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Platform.isIOS ? CupertinoIcons.photo : Icons.image,
                size: 48,
                color: Platform.isIOS 
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Platform.isIOS 
                ? CupertinoColors.systemGrey5.resolveFrom(context)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Platform.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.broken_image,
                size: 48,
                color: Platform.isIOS 
                    ? CupertinoColors.systemRed.resolveFrom(context)
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build user info overlay
  Widget _buildUserOverlay(BuildContext context, bool isIOS, ThemeData theme) {
    final account = status.account;
    if (account == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: account.avatar ?? '',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 24,
                height: 24,
                color: Colors.grey[600],
                child: Icon(
                  isIOS ? CupertinoIcons.person : Icons.person,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 24,
                height: 24,
                color: Colors.grey[600],
                child: Icon(
                  isIOS ? CupertinoIcons.person : Icons.person,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          
          // User display name
          Flexible(
            child: Text(
              account.displayName.isNotEmpty ? account.displayName : account.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate aspect ratio for the image
  double _calculateAspectRatio(MediaAttachment attachment) {
    // Try to get aspect ratio from meta data
    final meta = attachment.meta;
    if (meta != null && meta['original'] != null) {
      final original = meta['original'];
      final width = original['width'];
      final height = original['height'];
      
      if (width != null && height != null && height > 0) {
        final ratio = width / height;
        // Clamp aspect ratio to reasonable bounds for feed display
        return ratio.clamp(0.5, 2.0);
      }
    }
    
    // Default aspect ratio for unknown dimensions
    return 1.0;
  }
}
