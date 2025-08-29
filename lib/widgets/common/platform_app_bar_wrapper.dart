import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformAppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final PlatformAppBar platformAppBar;

  const PlatformAppBarWrapper({
    super.key,
    required this.platformAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return platformAppBar;
  }

  @override
  Size get preferredSize {
    // Use standard AppBar height as fallback
    return const Size.fromHeight(kToolbarHeight);
  }
}
