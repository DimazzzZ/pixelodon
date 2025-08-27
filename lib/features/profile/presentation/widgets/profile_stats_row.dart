import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/profile_models.dart';
import 'shimmer_placeholders.dart';

/// Stats row widget showing Posts, Followers, Following counts
class ProfileStatsRow extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final bool isLoading;

  const ProfileStatsRow({
    super.key,
    this.profile,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null) {
      return const ProfileStatsShimmer();
    }

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Posts
            Expanded(
              child: _StatItem(
                count: profile!.posts,
                label: 'Posts',
                onTap: onPostsTap,
              ),
            ),
            // Divider
            _buildDivider(theme),
            // Followers
            Expanded(
              child: _StatItem(
                count: profile!.followers,
                label: 'Followers',
                onTap: onFollowersTap,
              ),
            ),
            // Divider
            _buildDivider(theme),
            // Following
            Expanded(
              child: _StatItem(
                count: profile!.following,
                label: 'Following',
                onTap: onFollowingTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.3),
      ),
    );
  }
}

/// Individual stat item widget
class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Count
            Text(
              _formatCount(count),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format count with K/M suffixes for large numbers
  String _formatCount(int count) {
    final formatter = NumberFormat.compact(locale: 'en');
    return formatter.format(count);
  }
}

/// Alternative stats row with dot separators instead of dividers
class ProfileStatsRowDots extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final bool isLoading;

  const ProfileStatsRowDots({
    super.key,
    this.profile,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null) {
      return const ProfileStatsShimmer();
    }

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Posts
          _StatItemCompact(
            count: profile!.posts,
            label: 'Posts',
            onTap: onPostsTap,
          ),
          // Dot separator
          _buildDotSeparator(theme),
          // Followers
          _StatItemCompact(
            count: profile!.followers,
            label: 'Followers',
            onTap: onFollowersTap,
          ),
          // Dot separator
          _buildDotSeparator(theme),
          // Following
          _StatItemCompact(
            count: profile!.following,
            label: 'Following',
            onTap: onFollowingTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDotSeparator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Icon(
        Icons.circle,
        size: 4,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
    );
  }
}

/// Compact stat item for dot-separated layout
class _StatItemCompact extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItemCompact({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _formatCount(count),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format count with K/M suffixes for large numbers
  String _formatCount(int count) {
    final formatter = NumberFormat.compact(locale: 'en');
    return formatter.format(count);
  }
}

/// Extension methods for ProfileStatsRow
extension ProfileStatsRowExtensions on ProfileStatsRow {
  /// Create a shimmer version for loading states
  ProfileStatsRow asShimmer() {
    return const ProfileStatsRow(isLoading: true);
  }
}

/// Sliver version of ProfileStatsRow
class SliverProfileStatsRow extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final bool isLoading;
  final bool useDots;

  const SliverProfileStatsRow({
    super.key,
    this.profile,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.isLoading = false,
    this.useDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: useDots
          ? ProfileStatsRowDots(
              profile: profile,
              onPostsTap: onPostsTap,
              onFollowersTap: onFollowersTap,
              onFollowingTap: onFollowingTap,
              isLoading: isLoading,
            )
          : ProfileStatsRow(
              profile: profile,
              onPostsTap: onPostsTap,
              onFollowersTap: onFollowersTap,
              onFollowingTap: onFollowingTap,
              isLoading: isLoading,
            ),
    );
  }
}
