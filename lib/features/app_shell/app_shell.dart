import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_shell.g.dart';

/// Provider for the current navigation index
@Riverpod(keepAlive: true)
class CurrentIndex extends _$CurrentIndex {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

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

    return PlatformWidget(
      material: (_, __) => Scaffold(
        body: widget.child,
        bottomNavigationBar: _buildBottomNavigation(context, currentIndex),
      ),
      cupertino: (_, __) => CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(child: widget.child),
            _buildBottomNavigation(context, currentIndex),
          ],
        ),
      ),
    );
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
      ref.read(currentIndexProvider.notifier).setIndex(index);
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
