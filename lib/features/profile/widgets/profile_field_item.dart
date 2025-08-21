import 'package:flutter/material.dart';
import 'package:pixelodon/models/account.dart';

class ProfileFieldItem extends StatelessWidget {
  final Field field;
  const ProfileFieldItem({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  field.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (field.verifiedAt != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(field.value),
          ],
        ),
      ),
    );
  }
}
