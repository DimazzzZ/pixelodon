import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowRequestPending;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final VoidCallback onEditProfile;

  const FollowButton({
    super.key,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.isFollowRequestPending,
    required this.onFollow,
    required this.onUnfollow,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)));

    ButtonStyle compactFilled({Color? bg, Color? fg}) {
      return ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: borderRadius,
      );
    }

    ButtonStyle compactOutlined({Color? fg}) {
      return OutlinedButton.styleFrom(
        foregroundColor: fg,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: borderRadius,
        side: BorderSide(color: Theme.of(context).dividerColor),
      );
    }

    if (isCurrentUser) {
      return OutlinedButton(
        onPressed: onEditProfile,
        style: compactOutlined(fg: Theme.of(context).colorScheme.onSurface),
        child: const Text('Edit Profile'),
      );
    }

    if (isFollowRequestPending) {
      return OutlinedButton(
        onPressed: onUnfollow,
        style: compactOutlined(fg: Theme.of(context).colorScheme.onSurface),
        child: const Text('Requested'),
      );
    }

    if (isFollowing) {
      return OutlinedButton(
        onPressed: onUnfollow,
        style: compactOutlined(fg: Theme.of(context).colorScheme.onSurface),
        child: const Text('Unfollow'),
      );
    }

    return ElevatedButton(
      onPressed: onFollow,
      style: compactFilled(),
      child: const Text('Follow'),
    );
  }
}
