import 'package:flutter/material.dart';
import '../../state/profile_state.dart';

/// Pinned tab bar for profile tabs (Media, Comments, Boosts, Likes)
class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;
  final bool isOwnProfile;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter tabs based on profile ownership - hide likes tab for other users
    final visibleTabs = <MapEntry<int, String>>[];
    for (final entry in ProfileTabs.labels.asMap().entries) {
      final index = entry.key;
      final label = entry.value;
      
      // Hide likes tab (index 3) if not viewing own profile
      if (index == ProfileTabs.likes && !isOwnProfile) {
        continue;
      }
      
      visibleTabs.add(entry);
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: visibleTabs.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = index == selectedIndex;

          return Expanded(
            child: _TabItem(
              label: label,
              isSelected: isSelected,
              isLoading: isLoading,
              onTap: () => onTabChanged(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual tab item widget
class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isLoading ? null : onTap,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 40 : 0,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver persistent header delegate for pinned tab bar
class SliverProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;
  final bool isOwnProfile;

  SliverProfileTabBarDelegate({
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
    this.isOwnProfile = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ProfileTabBar(
      selectedIndex: selectedIndex,
      onTabChanged: onTabChanged,
      isLoading: isLoading,
      isOwnProfile: isOwnProfile,
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant SliverProfileTabBarDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex ||
           isLoading != oldDelegate.isLoading ||
           isOwnProfile != oldDelegate.isOwnProfile;
  }
}

/// Sliver version of the profile tab bar
class SliverProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;
  final bool pinned;
  final bool isOwnProfile;

  const SliverProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
    this.pinned = true,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: SliverProfileTabBarDelegate(
        selectedIndex: selectedIndex,
        onTabChanged: onTabChanged,
        isLoading: isLoading,
        isOwnProfile: isOwnProfile,
      ),
    );
  }
}

/// Alternative Material 3 style tab bar with segmented button look
class ProfileTabBarSegmented extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;

  const ProfileTabBarSegmented({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SegmentedButton<int>(
        segments: ProfileTabs.labels.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;

          return ButtonSegment<int>(
            value: index,
            label: Text(
              label,
              style: theme.textTheme.labelLarge,
            ),
          );
        }).toList(),
        selected: {selectedIndex},
        onSelectionChanged: isLoading 
            ? null 
            : (Set<int> selected) {
                if (selected.isNotEmpty) {
                  onTabChanged(selected.first);
                }
              },
        style: SegmentedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          selectedForegroundColor: theme.colorScheme.onSecondaryContainer,
          selectedBackgroundColor: theme.colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}

/// Sliver version of segmented tab bar
class SliverProfileTabBarSegmented extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;
  final bool pinned;

  const SliverProfileTabBarSegmented({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _SegmentedTabBarDelegate(
        selectedIndex: selectedIndex,
        onTabChanged: onTabChanged,
        isLoading: isLoading,
      ),
    );
  }
}

/// Delegate for segmented tab bar
class _SegmentedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isLoading;

  _SegmentedTabBarDelegate({
    required this.selectedIndex,
    required this.onTabChanged,
    this.isLoading = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ProfileTabBarSegmented(
      selectedIndex: selectedIndex,
      onTabChanged: onTabChanged,
      isLoading: isLoading,
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _SegmentedTabBarDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex ||
           isLoading != oldDelegate.isLoading;
  }
}

/// Tab configuration and utilities
class ProfileTabConfig {
  static const double tabBarHeight = 48.0;
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  /// Get tab icon for given index (optional)
  static IconData? getTabIcon(int index) {
    switch (index) {
      case ProfileTabs.media:
        return Icons.grid_view_rounded;
      case ProfileTabs.comments:
        return Icons.chat_bubble_outline;
      case ProfileTabs.boosts:
        return Icons.repeat;
      default:
        return null;
    }
  }

  /// Get semantic label for accessibility
  static String getSemanticLabel(int index) {
    switch (index) {
      case ProfileTabs.media:
        return 'Media posts tab';
      case ProfileTabs.comments:
        return 'Comments and replies tab';
      case ProfileTabs.boosts:
        return 'Boosted posts tab';
      default:
        return 'Tab $index';
    }
  }
}
