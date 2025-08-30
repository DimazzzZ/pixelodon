import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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
      return PlatformElevatedButton(
        onPressed: onEditProfile,
        child: const Text('Edit Profile'),
        material: (_, __) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cupertino: (_, __) => CupertinoElevatedButtonData(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
    }

    if (isFollowRequestPending) {
      return PlatformElevatedButton(
        onPressed: onUnfollow,
        child: const Text('Requested'),
        material: (_, __) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cupertino: (_, __) => CupertinoElevatedButtonData(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
    }

    if (isFollowing) {
      return PlatformElevatedButton(
        onPressed: onUnfollow,
        child: const Text('Unfollow'),
        material: (_, __) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cupertino: (_, __) => CupertinoElevatedButtonData(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
    }

    return PlatformElevatedButton(
      onPressed: onFollow,
      child: const Text('Follow'),
      material: (_, __) => MaterialElevatedButtonData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      cupertino: (_, __) => CupertinoElevatedButtonData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
