import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'platform_adaptive.dart';
import 'tree_builder.dart';

class ReplyActionBar extends StatelessWidget {
  final ReplyNode node;
  final VoidCallback? onReply;
  final VoidCallback? onBoost;
  final VoidCallback? onFavourite;
  final VoidCallback? onShare;
  final VoidCallback? onOpenReplies;

  const ReplyActionBar({super.key, required this.node, this.onReply, this.onBoost, this.onFavourite, this.onShare, this.onOpenReplies});

  @override
  Widget build(BuildContext context) {
    return _ResponsiveActionLayout(node: node, onReply: onReply, onBoost: onBoost, onFavourite: onFavourite, onShare: onShare, onOpenReplies: onOpenReplies);
  }
}

/// Internal widget that implements deterministic two-mode layout to prevent overflow
class _ResponsiveActionLayout extends StatelessWidget {
  final ReplyNode node;
  final VoidCallback? onReply;
  final VoidCallback? onBoost;
  final VoidCallback? onFavourite;
  final VoidCallback? onShare;
  final VoidCallback? onOpenReplies;

  const _ResponsiveActionLayout({
    required this.node,
    this.onReply,
    this.onBoost,
    this.onFavourite,
    this.onShare,
    this.onOpenReplies,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textScaleFactor = textScaler.scale(1.0);
    
    // Force Mode B (stacked) if text scale is large to avoid jitter
    if (textScaleFactor >= 1.2) {
      return _buildStackedLayout(context);
    }
    
    // Use LayoutBuilder for width budget checking with actual measurements
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        // Measure actual required widths for the components
        final rightGroup = _buildRightGroup(context);
        final leftGroup = _buildLeftGroup(context, null);
        
        // Measure the natural widths of both groups
        final rightWidth = _measureWidgetWidth(rightGroup, constraints);
        final requiredLeftWidth = _measureWidgetWidth(leftGroup, constraints);
        
        const gapBetweenGroups = 12.0;
        const horizontalPadding = 0.0; // No extra padding since tile handles it
        
        final availableForLeft = maxWidth - rightWidth - gapBetweenGroups - horizontalPadding;
        
        // Fit passes → Mode A (single line), otherwise Mode B (stacked)
        // Be aggressive about single-line: only use stacked if truly cannot fit
        if (availableForLeft >= requiredLeftWidth) {
          return _buildSingleLineLayout(context, availableForLeft);
        } else {
          return _buildStackedLayout(context);
        }
      },
    );
  }
  
  /// Mode A - Single line layout (no spaceBetween - that causes overflow!)
  Widget _buildSingleLineLayout(BuildContext context, double maxLeftWidth) {
    final leftGroup = _buildLeftGroup(context, maxLeftWidth);
    final rightGroup = _buildRightGroup(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Constrain left group to prevent overflow
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxLeftWidth),
          child: leftGroup,
        ),
        const SizedBox(width: 12), // Fixed gap, no spaceBetween
        rightGroup,
      ],
    );
  }
  
  /// Mode B - Stacked (two-line) layout
  Widget _buildStackedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Line 1: Left group takes full width
        _buildLeftGroup(context, null),
        const SizedBox(height: 6), // 6-8pt vertical gap between lines
        // Line 2: Right group aligned end (start for RTL)
        Align(
          alignment: Directionality.of(context) == TextDirection.rtl 
              ? Alignment.centerLeft 
              : Alignment.centerRight,
          child: _buildRightGroup(context),
        ),
      ],
    );
  }
  
  Widget _buildLeftGroup(BuildContext context, double? maxWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeText = textScaler.scale(1.0) >= 1.3;
    
    return Wrap(
      spacing: 12,
      runSpacing: isLargeText ? 6 : 0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Action(icon: _I.reply(context), label: 'Reply', onTap: () => onReply?.call()),
        _Action(icon: _I.repeat(context), label: 'Boost', onTap: () => onBoost?.call()),
        _Action(icon: _I.heart(context), label: 'Like', onTap: () => onFavourite?.call(), count: node.post.counts.favourites),
      ],
    );
  }
  
  Widget _buildRightGroup(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeText = textScaler.scale(1.0) >= 1.3;
    
    return Wrap(
      spacing: 8,
      runSpacing: isLargeText ? 6 : 0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Action(icon: _I.share(context), label: 'Share', onTap: () => onShare?.call()),
        _ReplyCountChip(count: node.post.counts.replies, onTap: () => onOpenReplies?.call()),
      ],
    );
  }
  
  /// Measures the width a widget would take when rendered
  double _measureWidgetWidth(Widget widget, BoxConstraints constraints) {
    final renderObject = RenderIntrinsicWidth();
    final element = widget.createElement();
    element.mount(null, null);
    renderObject.child = element.renderObject as RenderBox?;
    renderObject.layout(constraints, parentUsesSize: true);
    final width = renderObject.getMinIntrinsicWidth(double.infinity);
    element.unmount();
    return width;
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = count == null
        ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text('${count!}', key: ValueKey(count)),
              ),
            ],
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        text,
      ],
    );

    return SizedBox(
      height: 44,
      child: _PlatformButton(onPressed: onTap, child: child),
    );
  }
}

class _PlatformButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _PlatformButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    
    void handleTap() {
      if (ap == AppPlatform.iOS) {
        HapticFeedback.lightImpact();
      }
      onPressed();
    }
    
    if (ap == AppPlatform.iOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minSize: 44,
        onPressed: handleTap,
        child: child,
      );
    }
    return TextButton(
      onPressed: handleTap,
      style: TextButton.styleFrom(minimumSize: const Size(44, 44), visualDensity: VisualDensity.compact),
      child: child,
    );
  }
}

class _ReplyCountChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ReplyCountChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    final icon = ap == AppPlatform.iOS ? CupertinoIcons.text_bubble : Icons.forum;

    // Platform-native fill colors
    final platformFillColor = ap == AppPlatform.iOS 
        ? CupertinoDynamicColor.resolve(CupertinoColors.systemFill, context)
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    return SizedBox(
      height: 44, // Minimum tap target
      child: _PlatformButton(
        onPressed: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: platformFillColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text('$count', key: ValueKey(count)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _I {
  static IconData reply(BuildContext c) => currentPlatform(c) == AppPlatform.iOS ? CupertinoIcons.reply : Icons.reply;
  static IconData repeat(BuildContext c) => currentPlatform(c) == AppPlatform.iOS ? CupertinoIcons.arrow_2_squarepath : Icons.repeat;
  static IconData heart(BuildContext c) => currentPlatform(c) == AppPlatform.iOS ? CupertinoIcons.heart : Icons.favorite_border;
  static IconData share(BuildContext c) => currentPlatform(c) == AppPlatform.iOS ? CupertinoIcons.share : Icons.share;
}
