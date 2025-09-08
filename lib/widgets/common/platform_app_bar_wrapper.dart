import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Platform-native app bar implementation with two factory constructors
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitleIOS;
  final bool pinned;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final bool _isSliver;

  const PlatformAppBar._({
    super.key,
    this.title,
    this.largeTitle,
    this.leading,
    this.actions,
    this.centerTitleIOS = true,
    this.pinned = true,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    required bool isSliver,
  }) : _isSliver = isSliver;

  /// Small/standard app bar factory
  factory PlatformAppBar.small({
    Key? key,
    Widget? title,
    Widget? leading,
    List<Widget>? actions,
    bool centerTitleIOS = true,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
  }) {
    return PlatformAppBar._(
      key: key,
      title: title,
      leading: leading,
      actions: actions,
      centerTitleIOS: centerTitleIOS,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      isSliver: false,
    );
  }

  /// Sliver app bar factory for large/collapsing titles
  factory PlatformAppBar.sliver({
    Key? key,
    String? largeTitle,
    Widget? leading,
    List<Widget>? actions,
    bool pinned = true,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
  }) {
    return PlatformAppBar._(
      key: key,
      largeTitle: largeTitle,
      leading: leading,
      actions: actions,
      pinned: pinned,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      isSliver: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSliver) {
      return _buildSliverAppBar(context);
    } else {
      return _buildStandardAppBar(context);
    }
  }

  Widget _buildStandardAppBar(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoNavigationBar(context);
    } else {
      return _buildMaterialAppBar(context);
    }
  }

  Widget _buildSliverAppBar(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoSliverNavigationBar(context);
    } else {
      return _buildMaterialSliverAppBar(context);
    }
  }

  CupertinoNavigationBar _buildCupertinoNavigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      middle: centerTitleIOS ? title : null,
      trailing: actions != null && actions!.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!.map((action) {
                // Ensure each action is a CupertinoButton with proper hit target
                if (action is IconButton) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44.0, // iOS minimum hit target
                    child: action.icon,
                    onPressed: action.onPressed,
                  );
                } else if (action is CupertinoButton) {
                  return action;
                } else {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44.0,
                    child: action,
                    onPressed: () {},
                  );
                }
              }).toList(),
            )
          : null,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildMaterialAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: title,
      leading: leading,
      actions: actions?.map((action) {
        // Ensure proper hit targets for Material
        if (action is IconButton) {
          return IconButton(
            icon: action.icon,
            onPressed: action.onPressed,
            constraints: const BoxConstraints(
              minWidth: 48.0, // Android minimum hit target
              minHeight: 48.0,
            ),
          );
        }
        return action;
      }).toList(),
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
      centerTitle: false, // Material Design uses left-aligned titles
    );
  }

  CupertinoSliverNavigationBar _buildCupertinoSliverNavigationBar(BuildContext context) {
    return CupertinoSliverNavigationBar(
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
                    child: action.icon,
                    onPressed: action.onPressed,
                  );
                } else if (action is CupertinoButton) {
                  return action;
                } else {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44.0,
                    child: action,
                    onPressed: () {},
                  );
                }
              }).toList(),
            )
          : null,
      backgroundColor: backgroundColor,
      stretch: false,
    );
  }

  SliverAppBar _buildMaterialSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar.medium(
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
      automaticallyImplyLeading: automaticallyImplyLeading,
      pinned: pinned,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
    );
  }

  @override
  Size get preferredSize {
    if (_isSliver) {
      // Sliver app bars don't use preferredSize
      return const Size.fromHeight(0);
    }

    if (Platform.isIOS) {
      return const Size.fromHeight(44.0); // iOS navigation bar height
    } else {
      return const Size.fromHeight(kToolbarHeight); // Material app bar height
    }
  }
}
