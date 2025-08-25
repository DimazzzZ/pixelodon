import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Tiny platform helper
enum AppPlatform { iOS, Android }

AppPlatform currentPlatform(BuildContext c) {
  final platform = Theme.of(c).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return AppPlatform.iOS;
  }
  // Fallback to runtime if available
  try {
    if (Platform.isIOS) return AppPlatform.iOS;
  } catch (_) {}
  return AppPlatform.Android;
}

// Adaptive Scaffold
class AdaptiveScaffold extends StatelessWidget {
  final Widget? navBarTitle;
  final List<Widget>? trailingActions;
  final Widget body;
  final Widget? leading;

  const AdaptiveScaffold({super.key, this.navBarTitle, this.trailingActions, required this.body, this.leading});

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    if (ap == AppPlatform.iOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: leading,
          middle: navBarTitle,
          trailing: trailingActions == null
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: trailingActions!),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: navBarTitle,
        actions: trailingActions,
      ),
      body: body,
    );
  }
}

class AdaptiveNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  const AdaptiveNavBar({super.key, this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    if (ap == AppPlatform.iOS) {
      return CupertinoNavigationBar(
        leading: leading,
        middle: title,
        trailing: actions == null ? null : Row(mainAxisSize: MainAxisSize.min, children: actions!),
      );
    }
    return AppBar(leading: leading, title: title, actions: actions);
  }
}

class AdaptiveIconButton extends StatelessWidget {
  final IconData cupertinoIcon;
  final IconData materialIcon;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  const AdaptiveIconButton({super.key, required this.cupertinoIcon, required this.materialIcon, required this.semanticsLabel, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    if (ap == AppPlatform.iOS) {
      return CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: Semantics(
          label: semanticsLabel,
          button: true,
          child: Icon(cupertinoIcon, size: 22),
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: Semantics(label: semanticsLabel, button: true, child: Icon(materialIcon)),
    );
  }
}

class AdaptiveActionSheet {
  static Future<T?> show<T>({required BuildContext context, required List<AdaptiveActionSheetAction<T>> actions, AdaptiveActionSheetAction<T>? cancel}) {
    final ap = currentPlatform(context);
    if (ap == AppPlatform.iOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (c) => CupertinoActionSheet(
          actions: actions
              .map((a) => CupertinoActionSheetAction(
                    onPressed: () => Navigator.of(c).pop(a.value),
                    isDefaultAction: a.isDefault,
                    isDestructiveAction: a.isDestructive,
                    child: a.child,
                  ))
              .toList(),
          cancelButton: cancel == null
              ? null
              : CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(c).pop(cancel.value),
                  isDefaultAction: cancel.isDefault,
                  isDestructiveAction: cancel.isDestructive,
                  child: cancel.child,
                ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...actions.map((a) => ListTile(
                title: a.child,
                textColor: a.isDestructive ? Theme.of(c).colorScheme.error : null,
                onTap: () => Navigator.of(c).pop(a.value),
              )),
          if (cancel != null)
            ListTile(
              title: cancel.child,
              onTap: () => Navigator.of(c).pop(cancel.value),
            ),
        ]),
      ),
    );
  }
}

class AdaptiveActionSheetAction<T> {
  final Widget child;
  final T value;
  final bool isDefault;
  final bool isDestructive;
  AdaptiveActionSheetAction({required this.child, required this.value, this.isDefault = false, this.isDestructive = false});
}

class AdaptiveActivityIndicator extends StatelessWidget {
  final double? radius;
  const AdaptiveActivityIndicator({super.key, this.radius});

  @override
  Widget build(BuildContext context) {
    return currentPlatform(context) == AppPlatform.iOS
        ? CupertinoActivityIndicator(radius: radius ?? 10)
        : SizedBox(width: (radius ?? 10) * 2, height: (radius ?? 10) * 2, child: const CircularProgressIndicator(strokeWidth: 2));
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const AdaptiveTextButton({super.key, required this.child, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return currentPlatform(context) == AppPlatform.iOS
        ? CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), onPressed: onPressed, child: child)
        : TextButton(onPressed: onPressed, child: child);
  }
}

class AdaptiveDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;
  const AdaptiveDivider({super.key, this.indent, this.endIndent});
  @override
  Widget build(BuildContext context) {
    return Divider(indent: indent, endIndent: endIndent, height: 1);
  }
}

class AdaptiveDialog {
  static Future<T?> show<T>({required BuildContext context, required Widget title, required Widget content, required List<Widget> actions}) {
    if (currentPlatform(context) == AppPlatform.iOS) {
      return showCupertinoDialog<T>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
                title: title,
                content: content,
                actions: actions,
              ));
    }
    return showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(title: title, content: content, actions: actions),
    );
  }
}
