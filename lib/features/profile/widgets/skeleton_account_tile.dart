import 'package:flutter/material.dart';

/// Skeleton placeholder for account tiles during loading
class SkeletonAccountTile extends StatefulWidget {
  const SkeletonAccountTile({super.key});

  @override
  State<SkeletonAccountTile> createState() => _SkeletonAccountTileState();
}

class _SkeletonAccountTileState extends State<SkeletonAccountTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          colorScheme.surfaceContainerHighest.withOpacity(0.3),
          colorScheme.surfaceContainerHighest.withOpacity(0.7),
          _animation.value,
        )!;

        return Padding(
          // Cell padding 16px to match CompactAccountTile
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar placeholder - 44px (radius 22) to match CompactAccountTile
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary name placeholder
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Handle placeholder
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Follow button placeholder - 36px height, 92px min width to match FollowButton
                  Container(
                    height: 36,
                    width: 92,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(12), // 12px radius to match FollowButton
                    ),
                  ),
                ],
              ),
              // Bio placeholder - 8px vertical spacing to match CompactAccountTile
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that shows 6 skeleton account tiles for loading state
class SkeletonAccountList extends StatelessWidget {
  const SkeletonAccountList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6, // Show 6 skeleton rows as per requirements
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        indent: 16, // 16px inset as per requirements
        endIndent: 0,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      itemBuilder: (context, index) => const SkeletonAccountTile(),
    );
  }
}
