import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A thin platform-agnostic wrapper that forwards to flutter_platform_widgets' PlatformNavBar
class AppPlatformNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> itemChanged;
  final List<BottomNavigationBarItem> items;
  final PlatformBuilder<MaterialNavBarData>? material;
  final PlatformBuilder<CupertinoTabBarData>? cupertino;

  const AppPlatformNavBar({
    super.key,
    required this.currentIndex,
    required this.itemChanged,
    required this.items,
    this.material,
    this.cupertino,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformNavBar(
      currentIndex: currentIndex,
      itemChanged: itemChanged,
      items: items,
      material: material,
      cupertino: cupertino,
    );
  }
}
