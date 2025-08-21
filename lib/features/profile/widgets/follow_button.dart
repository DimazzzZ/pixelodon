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
    if (isCurrentUser) {
      return ElevatedButton(
        onPressed: onEditProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Edit Profile'),
      );
    }

    if (isFollowRequestPending) {
      return ElevatedButton(
        onPressed: onUnfollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Requested'),
      );
    }

    if (isFollowing) {
      return ElevatedButton(
        onPressed: onUnfollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Unfollow'),
      );
    }

    return ElevatedButton(
      onPressed: onFollow,
      child: const Text('Follow'),
    );
  }
}
