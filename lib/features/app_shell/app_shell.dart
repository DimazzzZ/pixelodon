import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/providers/auth_provider.dart';

/// Provider for the current navigation index
final currentIndexProvider = StateProvider<int>((ref) => 0);

/// The main app shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  /// The child widget to display
  final Widget child;

  /// Constructor
  const AppShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Navigation destinations
  final List<_NavigationDestination> _destinations = [
    _NavigationDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_outlined,
      label: 'Home',
      path: '/home',
    ),
    _NavigationDestination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_outlined,
      label: 'Explore',
      path: '/explore',
    ),
    _NavigationDestination(
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle_outline,
      label: 'New Post',
      path: '/compose',
    ),
    _NavigationDestination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_outlined,
      label: 'Notifications',
      path: '/notifications',
    ),
    _NavigationDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_outline,
      label: 'Profile',
      path: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final activeInstance = ref.watch(activeInstanceProvider);
    
    return PlatformWidget(
      material: (_, __) => Scaffold(
        appBar: _buildMaterialAppBar(context, activeInstance),
        body: widget.child,
        bottomNavigationBar: _buildBottomNavigation(context, currentIndex),
      ),
      cupertino: (_, __) => CupertinoPageScaffold(
        navigationBar: _buildCupertinoNavigationBar(context, activeInstance),
        child: Column(
          children: [
            Expanded(child: widget.child),
            _buildBottomNavigation(context, currentIndex),
          ],
        ),
      ),
    );
  }

  AppBar _buildMaterialAppBar(BuildContext context, dynamic activeInstance) {
    return AppBar(
      titleSpacing: 16.0,
      title: _buildAppBarTitle(context, activeInstance),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  CupertinoNavigationBar _buildCupertinoNavigationBar(BuildContext context, dynamic activeInstance) {
    return CupertinoNavigationBar(
      leading: _buildAppBarTitle(context, activeInstance),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.settings),
        onPressed: () => context.push('/settings'),
      ),
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
    );
  }

  Widget _buildAppBarTitle(BuildContext context, dynamic activeInstance) {
    if (activeInstance != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isMaterial(context)
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              activeInstance.isPixelfed ? Icons.photo_camera : Icons.chat_bubble,
              size: 16,
              color: isMaterial(context)
                  ? Theme.of(context).colorScheme.primary
                  : CupertinoTheme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              activeInstance.domain,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      return const Text('Pixelodon');
    }
  }

  Widget _buildBottomNavigation(BuildContext context, int currentIndex) {
    // Use platform-specific navigation
    return PlatformWidget(
      material: (_, __) => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _handleNavigation(index),
        destinations: _destinations.map((destination) {
          return NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          );
        }).toList(),
      ),
      cupertino: (_, __) => CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(index),
        items: _destinations.map((destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            activeIcon: Icon(destination.selectedIcon),
            label: destination.label,
          );
        }).toList(),
      ),
    );
  }

  void _handleNavigation(int index) {
    // If it's the compose button (index 2), just navigate without changing the selected index
    if (index == 2) {
      context.push(_destinations[index].path);
    } else {
      ref.read(currentIndexProvider.notifier).state = index;
      context.go(_destinations[index].path);
    }
  }
}

/// Navigation destination data
class _NavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;

  _NavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });
}
