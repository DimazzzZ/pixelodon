import 'package:flutter/material.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/utils/link_tap_handler.dart';

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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
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
                Expanded(
                  child: Text(
                    field.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (field.verifiedAt != null) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            SafeHtmlWidget(
              htmlContent: field.value,
              onLinkTap: (url) => LinkTapHandler.handleLinkTap(context, url),
            ),
          ],
        ),
      ),
    );
  }
}
