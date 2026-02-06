import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'dart:io';

/// A unified cross-platform scaffold with standard and sliver patterns
class AppPageScaffold extends StatelessWidget {
  final String? title;
  final String? largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? headerBelowSliver;
  final Widget Function()? sliverBodyBuilder;
  final Widget? bottomNavigationBar;
  final Widget? bottomAction;
  final bool useNestedScroll;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool _isSliver;

  const AppPageScaffold._({
    super.key,
    this.title,
    this.largeTitle,
    this.leading,
    this.actions,
    this.body,
    this.headerBelowSliver,
    this.sliverBodyBuilder,
    this.bottomNavigationBar,
    this.bottomAction,
    this.useNestedScroll = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
    required bool isSliver,
  }) : _isSliver = isSliver;

  /// Standard scaffold constructor
  factory AppPageScaffold.standard({
    Key? key,
    String? title,
    Widget? leading,
    List<Widget>? actions,
    required Widget body,
    Widget? bottomNavigationBar,
    Widget? bottomAction,
    Color? backgroundColor,
    Widget? floatingActionButton,
    Widget? drawer,
    Widget? endDrawer,
    bool? resizeToAvoidBottomInset,
    bool extendBodyBehindAppBar = false,
  }) {
    return AppPageScaffold._(
      key: key,
      title: title,
      leading: leading,
      actions: actions,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      bottomAction: bottomAction,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      isSliver: false,
    );
  }

  /// Sliver scaffold constructor for large titles and complex scrolling
  factory AppPageScaffold.sliver({
    Key? key,
    String? largeTitle,
    Widget? leading,
    List<Widget>? actions,
    Widget? headerBelowSliver,
    required Widget Function() sliverBodyBuilder,
    Widget? bottomNavigationBar,
    Widget? bottomAction,
    bool useNestedScroll = true,
    Color? backgroundColor,
    Widget? floatingActionButton,
    Widget? drawer,
    Widget? endDrawer,
    bool? resizeToAvoidBottomInset,
  }) {
    return AppPageScaffold._(
      key: key,
      largeTitle: largeTitle,
      leading: leading,
      actions: actions,
      headerBelowSliver: headerBelowSliver,
      sliverBodyBuilder: sliverBodyBuilder,
      bottomNavigationBar: bottomNavigationBar,
      bottomAction: bottomAction,
      useNestedScroll: useNestedScroll,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: false, // Never extend for slivers
      isSliver: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSliver) {
      return _buildSliverScaffold(context);
    } else {
      return _buildStandardScaffold(context);
    }
  }

  Widget _buildStandardScaffold(BuildContext context) {
    final appBar = (title != null || leading != null || (actions != null && actions!.isNotEmpty))
        ? PlatformAppBar.small(
            title: title != null ? Text(title!) : null,
            leading: leading,
            actions: actions,
          )
        : null;

    Widget bodyWidget = _BodyHost(child: body!);

    // Add bottom action if provided
    if (bottomAction != null) {
      bodyWidget = Column(
        children: [
          Expanded(child: bodyWidget),
          _buildBottomActionContainer(context),
        ],
      );
    }

    // For media viewer - add top padding manually when extending behind app bar
    if (extendBodyBehindAppBar) {
      bodyWidget = Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        child: bodyWidget,
      );
    }

    if (Platform.isIOS) {
      // Build iOS-specific navigation bar
      CupertinoNavigationBar? iosNavBar;
      if (appBar != null) {
        iosNavBar = CupertinoNavigationBar(
          automaticallyImplyLeading: leading == null,
          leading: leading,
          middle: title != null ? Text(title!) : null,
          trailing: actions != null && actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.map((action) {
                    if (action is IconButton) {
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 44.0,
                        onPressed: action.onPressed,
                        child: action.icon,
                      );
                    }
                    return action;
                  }).toList(),
                )
              : null,
          backgroundColor: backgroundColor,
        );
      }

      return CupertinoPageScaffold(
        navigationBar: iosNavBar,
        backgroundColor: backgroundColor,
        child: _BodyHost(child: bodyWidget),
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: bodyWidget,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }
  }

  Widget _buildSliverScaffold(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoSliverScaffold(context);
    } else {
      return _buildMaterialSliverScaffold(context);
    }
  }

  Widget _buildCupertinoSliverScaffold(BuildContext context) {
    final slivers = <Widget>[
      // Cupertino sliver navigation bar with large title
      CupertinoSliverNavigationBar(
        largeTitle: largeTitle != null ? Text(largeTitle!) : null,
        leading: leading,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.map((action) {
                  if (action is IconButton) {
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 44.0,
                      onPressed: action.onPressed,
                      child: action.icon,
                    );
                  }
                  return action;
                }).toList(),
              )
            : null,
        backgroundColor: backgroundColor,
        stretch: false,
      ),

      // Optional header below sliver (like pinned tabs)
      if (headerBelowSliver != null) headerBelowSliver!,

      // Body content slivers
      ...(sliverBodyBuilder!() as CustomScrollView).slivers,

      // Bottom safe area
      SliverSafeArea(
        top: false,
        bottom: true,
        sliver: SliverToBoxAdapter(
          child: bottomAction != null
              ? _buildBottomActionContainer(context)
              : SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ),
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: _BodyHost(child: CustomScrollView(slivers: slivers)),
    );
  }

  Widget _buildMaterialSliverScaffold(BuildContext context) {
    if (useNestedScroll) {
      return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar.medium(
                  title: largeTitle != null ? Text(largeTitle!) : null,
                  leading: leading,
                  actions: actions?.map((action) {
                    if (action is IconButton) {
                      return IconButton(
                        icon: action.icon,
                        onPressed: action.onPressed,
                        constraints: const BoxConstraints(
                          minWidth: 48.0,
                          minHeight: 48.0,
                        ),
                      );
                    }
                    return action;
                  }).toList(),
                  automaticallyImplyLeading: leading == null,
                  pinned: true,
                  backgroundColor: backgroundColor,
                  centerTitle: false,
                ),
              ),
              if (headerBelowSliver != null) headerBelowSliver!,
            ];
          },
          body: Builder(
            builder: (context) {
              Widget bodyWidget = sliverBodyBuilder!();

              // Add overlap injector for nested scroll
              if (bodyWidget is CustomScrollView) {
                final customScrollView = bodyWidget;
                final slivers = [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  ),
                  ...customScrollView.slivers,
                  SliverSafeArea(
                    top: false,
                    bottom: true,
                    sliver: SliverToBoxAdapter(
                      child: bottomAction != null
                          ? _buildBottomActionContainer(context)
                          : SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
                    ),
                  ),
                ];

                return _BodyHost(child: CustomScrollView(slivers: slivers));
              }

              return _BodyHost(child: bodyWidget);
            },
          ),
        ),
      );
    } else {
      // Simple sliver scaffold without nested scroll
      final slivers = <Widget>[
        SliverAppBar.medium(
          title: largeTitle != null ? Text(largeTitle!) : null,
          leading: leading,
          actions: actions?.map((action) {
            if (action is IconButton) {
              return IconButton(
                icon: action.icon,
                onPressed: action.onPressed,
                constraints: const BoxConstraints(
                  minWidth: 48.0,
                  minHeight: 48.0,
                ),
              );
            }
            return action;
          }).toList(),
          automaticallyImplyLeading: leading == null,
          pinned: true,
          backgroundColor: backgroundColor,
          centerTitle: false,
        ),

        if (headerBelowSliver != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: headerBelowSliver!,
              height: 56.0,
            ),
          ),

        ...(sliverBodyBuilder!() as CustomScrollView).slivers,

        SliverSafeArea(
          top: false,
          bottom: true,
          sliver: SliverToBoxAdapter(
            child: bottomAction != null
                ? _buildBottomActionContainer(context)
                : SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
          ),
        ),
      ];

      return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: _BodyHost(child: CustomScrollView(slivers: slivers)),
      );
    }
  }

  Widget _buildBottomActionContainer(BuildContext context) {
    return buildBottomAction(context, bottomAction!);
  }

  /// Helper to build bottom action container with proper safe area and platform sizing
  static Widget buildBottomAction(BuildContext context, Widget child) {
    final horizontalPadding = Platform.isIOS ? 20.0 : 16.0;
    final containerHeight = Platform.isIOS ? 52.0 : 56.0;

    return SafeArea(
      bottom: true,
      child: SizedBox(
        height: containerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Body host wrapper that provides Material ancestor and proper safe area handling
class _BodyHost extends StatelessWidget {
  final Widget child;

  const _BodyHost({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pageBg(context),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          bottom: false,
          child: child,
        ),
      ),
    );
  }
}

/// Sliver header delegate for pinned headers
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}
