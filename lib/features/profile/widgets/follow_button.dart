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
    ButtonStyle _compactStyle({Color? bg, Color? fg}) {
      return ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        //shape: const RoundedRectangleBorder(),
      );
    }

    if (isCurrentUser) {
      return ElevatedButton(
        onPressed: onEditProfile,
        style: _compactStyle(bg: Colors.grey[200], fg: Colors.black),
        child: const Text('Edit Profile'),
      );
    }

    if (isFollowRequestPending) {
      return ElevatedButton(
        onPressed: onUnfollow,
        style: _compactStyle(bg: Colors.grey[200], fg: Colors.black),
        child: const Text('Requested'),
      );
    }

    if (isFollowing) {
      return ElevatedButton(
        onPressed: onUnfollow,
        style: _compactStyle(bg: Colors.grey[200], fg: Colors.black),
        child: const Text('Unfollow'),
      );
    }

    return ElevatedButton(
      onPressed: onFollow,
      style: _compactStyle(),
      child: const Text('Follow'),
    );
  }
}
