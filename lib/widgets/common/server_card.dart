import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'dart:io';

/// Standardized server card widget used across the app
class ServerCard extends StatelessWidget {
  final InstanceCaps instance;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final VoidCallback? onJoin;
  final bool isFeatured;
  final List<InstanceBadge> badges;
  final String? primaryActionText;
  final String? secondaryActionText;
  final bool showActions;
  final bool showThumbnail;
  final int? maxDescriptionLines;

  const ServerCard({
    super.key,
    required this.instance,
    this.onTap,
    this.onPreview,
    this.onJoin,
    this.isFeatured = false,
    this.badges = const [],
    this.primaryActionText,
    this.secondaryActionText,
    this.showActions = true,
    this.showThumbnail = true,
    this.maxDescriptionLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (Platform.isIOS) {
      return _buildIOSCard(context, theme);
    } else {
      return _buildAndroidCard(context, theme);
    }
  }

  Widget _buildIOSCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: isFeatured
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(color: AppTheme.separator(context).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 12),
                _buildDescription(context, theme),
                if (showThumbnail) _buildThumbnail(context, theme),
                _buildBadges(context, theme),
                _buildStats(context, theme),
                if (showActions) _buildActions(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      color: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFeatured
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 12),
                _buildDescription(context, theme),
                if (showThumbnail) _buildThumbnail(context, theme),
                _buildBadges(context, theme),
                _buildStats(context, theme),
                if (showActions) _buildActions(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.title.isNotEmpty ? instance.title : instance.domain,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                instance.domain,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(
          instance.platform == InstancePlatform.pixelfed
              ? Icons.photo_camera
              : Icons.forum,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, ThemeData theme) {
    if (instance.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(
          instance.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: maxDescriptionLines,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context, ThemeData theme) {
    if (!showThumbnail || instance.thumbnail == null || instance.thumbnail!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              instance.thumbnail!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBadges(BuildContext context, ThemeData theme) {
    final allBadges = <Widget>[];

    // Only add badges from the badges list (no automatic registration badge)
    for (final badge in badges) {
      allBadges.add(_buildBadge(context, theme, badge));
    }

    if (allBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allBadges,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, ThemeData theme, InstanceBadge badge) {
    final badgeInfo = _getBadgeInfo(badge);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeInfo.color.withOpacity(Platform.isIOS ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(Platform.isIOS ? 8 : 12),
        border: Platform.isIOS
            ? null
            : Border.all(color: badgeInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeInfo.icon,
            size: 14,
            color: badgeInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeInfo.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeInfo.color,
              fontWeight: Platform.isIOS ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatUserCount(instance.activeUsers),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.speed,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _getLoadDescription(instance.loadScore),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    if (!showActions || (onPreview == null && onJoin == null)) {
      return const SizedBox.shrink();
    }

    if (Platform.isIOS) {
      return _buildIOSActions(context, theme);
    } else {
      return _buildAndroidActions(context, theme);
    }
  }

  Widget _buildIOSActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (onPreview != null)
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: theme.colorScheme.surfaceContainerHighest,
              onPressed: onPreview,
              child: Text(
                secondaryActionText ?? 'Preview',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (onPreview != null && onJoin != null) const SizedBox(width: 12),
        if (onJoin != null)
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: theme.colorScheme.primary,
              onPressed: onJoin,
              child: Text(
                primaryActionText ?? 'Join',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAndroidActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (onPreview != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(secondaryActionText ?? 'Preview'),
            ),
          ),
        if (onPreview != null && onJoin != null) const SizedBox(width: 12),
        if (onJoin != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(primaryActionText ?? 'Join'),
            ),
          ),
      ],
    );
  }

  BadgeInfo _getBadgeInfo(InstanceBadge badge) {
    switch (badge) {
      case InstanceBadge.openRegistration:
        return BadgeInfo(Icons.lock_open, 'Open Registration', Colors.green);
      case InstanceBadge.lowLoad:
        return BadgeInfo(Icons.speed, 'Fast Server', Colors.orange);
      case InstanceBadge.mastodon:
        return BadgeInfo(Icons.forum, 'Mastodon', Colors.purple);
      case InstanceBadge.pixelfed:
        return BadgeInfo(Icons.photo_camera, 'Pixelfed', Colors.pink);
      case InstanceBadge.photoFocused:
        return BadgeInfo(Icons.photo, 'Photo-focused', Colors.orange);
      case InstanceBadge.multilingual:
        return BadgeInfo(Icons.language, 'Multilingual', Colors.teal);
      case InstanceBadge.strictModeration:
        return BadgeInfo(Icons.shield, 'Well-moderated', Colors.indigo);
      case InstanceBadge.balancedModeration:
        return BadgeInfo(Icons.balance, 'Balanced', Colors.grey);
      case InstanceBadge.freeModeration:
        return BadgeInfo(Icons.forum, 'Free Expression', Colors.amber);
      case InstanceBadge.largeCommunity:
        return BadgeInfo(Icons.people, 'Large Community', Colors.red);
      case InstanceBadge.growingCommunity:
        return BadgeInfo(Icons.trending_up, 'Growing', Colors.lightGreen);
      case InstanceBadge.newInstance:
        return BadgeInfo(Icons.new_releases, 'New', Colors.cyan);
    }
  }

  String _formatUserCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M users';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K users';
    } else {
      return '$count users';
    }
  }

  String _getLoadDescription(double loadScore) {
    if (loadScore < 30) return 'Very Fast';
    if (loadScore < 50) return 'Fast';
    if (loadScore < 70) return 'Good';
    return 'Moderate';
  }
}

class BadgeInfo {
  final IconData icon;
  final String label;
  final Color color;

  BadgeInfo(this.icon, this.label, this.color);
}
