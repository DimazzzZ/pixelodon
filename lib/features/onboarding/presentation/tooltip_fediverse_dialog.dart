import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Simple dialog explaining the Fediverse concept to new users
class TooltipFediverseDialog extends StatelessWidget {
  const TooltipFediverseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PlatformAlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.public,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('What is Fediverse?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Fediverse is a network of independent social media servers that can communicate with each other.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Think of it like email: Gmail users can message Yahoo users. Similarly, Mastodon (like Twitter) and Pixelfed (like Instagram) users can interact across servers, but you own your data instead of big tech companies.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Benefits:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildBenefitItem(
              context,
              icon: Icons.security,
              text: 'No single company controls your data',
            ),
            const SizedBox(height: 4),
            _buildBenefitItem(
              context,
              icon: Icons.diversity_1,
              text: 'Choose a community that fits your values',
            ),
            const SizedBox(height: 4),
            _buildBenefitItem(
              context,
              icon: Icons.swap_horiz,
              text: 'Easy to switch servers anytime',
            ),
          ],
        ),
      ),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
