import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for profile header
class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: theme.colorScheme.surface.withOpacity(0.8),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // Cover image placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            // Avatar placeholder
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 40,
              top: 164, // 200 - 36 (half avatar size)
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for profile info section
class ProfileInfoShimmer extends StatelessWidget {
  const ProfileInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: theme.colorScheme.surface.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16), // Space for overlapping avatar
            // Username placeholder
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Bio placeholder
            Container(
              width: 180,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            // Interests placeholder
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for stats row
class ProfileStatsShimmer extends StatelessWidget {
  const ProfileStatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: theme.colorScheme.surface.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for media grid items
class MediaGridShimmer extends StatelessWidget {
  final int itemCount;
  
  const MediaGridShimmer({
    super.key,
    this.itemCount = 9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          highlightColor: theme.colorScheme.surface.withOpacity(0.8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        childCount: itemCount,
      ),
    );
  }
}

/// Shimmer placeholder for list items (comments/boosts)
class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: theme.colorScheme.surface.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text content
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for list of items
class ListShimmer extends StatelessWidget {
  final int itemCount;
  
  const ListShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const ListItemShimmer(),
        childCount: itemCount,
      ),
    );
  }
}
