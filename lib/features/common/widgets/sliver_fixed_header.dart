import 'package:flutter/material.dart';

/// Fixed height sliver header delegate for pinned headers
class FixedHeightHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool pinned;

  FixedHeightHeaderDelegate({
    required this.child,
    required this.height,
    this.pinned = true,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant FixedHeightHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || 
           oldDelegate.child.runtimeType != child.runtimeType;
  }
}

/// Helper to create pinned headers with dynamic type scaling
class SliverFixedHeader extends StatelessWidget {
  final Widget child;
  final double baseHeight;
  final bool pinned;

  const SliverFixedHeader({
    super.key,
    required this.child,
    required this.baseHeight,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = baseHeight + (fontScale > 1.3 ? 8 : 0);
    
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: FixedHeightHeaderDelegate(
        child: child,
        height: height,
        pinned: pinned,
      ),
    );
  }
}
