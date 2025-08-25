import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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

  void _handleNavigation(int index) {
    if (index == 2) {
      context.push(_destinations[index].path);
    } else {
      ref.read(currentIndexProvider.notifier).state = index;
      context.go(_destinations[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final activeInstance = ref.watch(activeInstanceProvider);

    final titleRow = Row(
      children: [
        if (activeInstance != null) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              activeInstance.isPixelfed
                ? (isMaterial(context) ? Icons.photo_camera : CupertinoIcons.camera)
                : (isMaterial(context) ? Icons.chat_bubble : CupertinoIcons.chat_bubble),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activeInstance.domain,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ] else
          const Text('Pixelodon'),
      ],
    );

    return PlatformScaffold(
      appBar: PlatformAppBar(
        material: (_, __) => MaterialAppBarData(
          title: titleRow,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
          // Tighten to platform guidelines
          toolbarHeight: 56,
          centerTitle: false,
          titleSpacing: 16,
          elevation: 0,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          title: Text(
            activeInstance != null ? activeInstance.domain : 'Pixelodon',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          // Keep trailing compact
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push('/settings'),
            child: const Icon(CupertinoIcons.settings),
          ),
        ),
      ),
      body: widget.child,
      bottomNavBar: PlatformNavBar(
        currentIndex: currentIndex,
        itemChanged: _handleNavigation,
        items: _destinations.map((destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            activeIcon: Icon(destination.selectedIcon),
            label: destination.label,
          );
        }).toList(),
        material: (_, __) => MaterialNavBarData(
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          height: 56,
        ),
        cupertino: (_, __) => CupertinoTabBarData(
          activeColor: Theme.of(context).colorScheme.primary,
          height: 50,
        ),
      ),
    );
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
