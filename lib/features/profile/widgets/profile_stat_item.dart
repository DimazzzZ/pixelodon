import 'package:flutter/material.dart';

class ProfileStatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;
  const ProfileStatItem({super.key, required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Center(child: content),
              ),
            )
          : Center(child: content),
    );
  }
}
