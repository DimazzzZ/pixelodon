import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A unified cross-platform scaffold that handles proper top insets
/// and prevents content from sliding under headers on all platforms.
class AppPageScaffold extends StatelessWidget {
  /// The app bar widget
  final PreferredSizeWidget? appBar;
  
  /// The body content widget
  final Widget body;
  
  /// Whether the body uses slivers (CustomScrollView)
  final bool usesSlivers;
  
  /// Background color
  final Color? backgroundColor;
  
  /// Floating action button
  final Widget? floatingActionButton;
  
  /// Bottom navigation bar
  final Widget? bottomNavigationBar;
  
  /// Drawer
  final Widget? drawer;
  
  /// End drawer
  final Widget? endDrawer;
  
  /// Whether to extend the body behind the app bar
  /// This is forced to false to prevent content overlap
  final bool extendBodyBehindAppBar;
  
  /// Whether to resize to avoid bottom inset
  final bool? resizeToAvoidBottomInset;

  const AppPageScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.usesSlivers = false,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.extendBodyBehindAppBar = false, // Force false to prevent overlap
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    // Use regular Scaffold for all platforms with proper SafeArea handling
    return Scaffold(
      appBar: appBar,
      body: _buildBodyWithProperInsets(context),
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      extendBodyBehindAppBar: false, // Always false to prevent overlap
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  Widget _buildBodyWithProperInsets(BuildContext context) {
    if (usesSlivers) {
      // For sliver-based content (CustomScrollView), the body should already handle slivers correctly
      // We just ensure proper safe area handling
      if (body is CustomScrollView) {
        final customScrollView = body as CustomScrollView;
        // For slivers, add SliverSafeArea at the beginning if no app bar
        final slivers = <Widget>[
          if (appBar == null)
            SliverSafeArea(
              top: true,
              bottom: false,
              sliver: SliverToBoxAdapter(child: Container()),
            ),
          ...customScrollView.slivers,
          // Add bottom safe area at the end
          SliverSafeArea(
            top: false,
            bottom: true,
            sliver: SliverToBoxAdapter(child: Container()),
          ),
        ];
        
        return CustomScrollView(
          controller: customScrollView.controller,
          scrollDirection: customScrollView.scrollDirection,
          reverse: customScrollView.reverse,
          physics: customScrollView.physics,
          shrinkWrap: customScrollView.shrinkWrap,
          center: customScrollView.center,
          anchor: customScrollView.anchor,
          cacheExtent: customScrollView.cacheExtent,
          clipBehavior: customScrollView.clipBehavior,
          dragStartBehavior: customScrollView.dragStartBehavior,
          keyboardDismissBehavior: customScrollView.keyboardDismissBehavior,
          restorationId: customScrollView.restorationId,
          scrollBehavior: customScrollView.scrollBehavior,
          slivers: slivers,
        );
      } else {
        // If marked as using slivers but not a CustomScrollView, just add SafeArea
        return SafeArea(
          top: appBar == null,
          bottom: true,
          child: body,
        );
      }
    } else {
      // For non-sliver content, add SafeArea
      // The app bar is handled automatically by Scaffold when present
      return SafeArea(
        top: appBar == null, // Only add top safe area if no app bar
        bottom: true,
        child: body,
      );
    }
  }
}

/// Extension to easily migrate existing PlatformScaffolds
extension PlatformScaffoldMigration on Widget {
  /// Wraps any widget in AppPageScaffold with proper inset handling
  Widget withProperInsets({
    PreferredSizeWidget? appBar,
    bool usesSlivers = false,
    Color? backgroundColor,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Widget? endDrawer,
    bool? resizeToAvoidBottomInset,
  }) {
    return AppPageScaffold(
      appBar: appBar,
      body: this,
      usesSlivers: usesSlivers,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
