import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pixelodon/features/onboarding/presentation/quick_quiz_sheet.dart';

/// In-app Fediverse education sheet with platform-native design
class FediverseEducationSheet extends ConsumerStatefulWidget {
  const FediverseEducationSheet({super.key});

  @override
  ConsumerState<FediverseEducationSheet> createState() => _FediverseEducationSheetState();
}

class _FediverseEducationSheetState extends ConsumerState<FediverseEducationSheet>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<bool> _faqExpanded = [false, false, false];
  late List<AnimationController> _faqAnimationControllers;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for iOS FAQ expansion
    _faqAnimationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _faqAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isIOS = Platform.isIOS;
    
    // Platform-specific padding
    final horizontalPadding = isIOS ? 20.0 : 16.0;
    final bottomPadding = math.max(16.0, mediaQuery.viewInsets.bottom);
    
    // Content width constraints
    final maxContentWidth = isIOS ? 600.0 : 640.0;
    final screenWidth = mediaQuery.size.width;
    final contentWidth = screenWidth > maxContentWidth ? maxContentWidth : screenWidth;
    final sidePadding = (screenWidth - contentWidth) / 2;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            _buildHeader(context, theme, isIOS),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding + sidePadding,
                    0,
                    horizontalPadding + sidePadding,
                    bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // TL;DR block
                      _buildTldrBlock(context, theme, isIOS),
                      
                      const SizedBox(height: 16),
                      
                      // Three bite-size blocks
                      _buildBiteSizeBlocks(context, theme, isIOS),
                      
                      const SizedBox(height: 16),
                      
                      // FAQ section
                      _buildFaqSection(context, theme, isIOS),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      _buildActionButtons(context, theme, isIOS),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isIOS) {
    final l10n = AppLocalizations.of(context);

    if (isIOS) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [
            // Centered title
            Center(
              child: Text(
                l10n?.fediverseEducationTitle ?? 'What is the Fediverse?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left-aligned title
            Expanded(
              child: Text(
                l10n?.fediverseEducationTitle ?? 'What is the Fediverse?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Close icon button
            Semantics(
              button: true,
              label: l10n?.fediverseEducationCloseLabel ?? 'Close',
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                iconSize: 24,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTldrBlock(BuildContext context, ThemeData theme, bool isIOS) {
    final l10n = AppLocalizations.of(context);

    return Text(
      l10n?.fediverseEducationTldr ?? 'Think of it like email! You can pick any email company (Gmail, Yahoo, etc.) but still send messages to anyone. The Fediverse works the same way with social media.',
      style: theme.textTheme.bodyLarge,
      textAlign: isIOS ? TextAlign.center : TextAlign.start,
    );
  }

  Widget _buildBiteSizeBlocks(BuildContext context, ThemeData theme, bool isIOS) {
    final l10n = AppLocalizations.of(context);
    final iconSize = isIOS ? 20.0 : 24.0;

    final blocks = [
      {
        'icon': isIOS ? CupertinoIcons.house_fill : Icons.home,
        'title': l10n?.fediverseEducationBlock1Title ?? 'Pick your neighborhood',
        'subtitle': l10n?.fediverseEducationBlock1Subtitle ?? 'Just like choosing where to live! Each server is like a friendly neighborhood with its own rules.',
      },
      {
        'icon': isIOS ? CupertinoIcons.person_2_fill : Icons.diversity_3,
        'title': l10n?.fediverseEducationBlock2Title ?? 'Talk to everyone',
        'subtitle': l10n?.fediverseEducationBlock2Subtitle ?? 'You can follow and chat with people from any neighborhood, not just your own!',
      },
      {
        'icon': isIOS ? CupertinoIcons.arrow_right_arrow_left_circle_fill : Icons.compare_arrows,
        'title': l10n?.fediverseEducationBlock3Title ?? 'You can move',
        'subtitle': l10n?.fediverseEducationBlock3Subtitle ?? 'Don\'t like your neighborhood? You can move to a different one and keep your friends!',
      },
    ];

    return Column(
      children: blocks.asMap().entries.map((entry) {
        final index = entry.key;
        final block = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < blocks.length - 1 ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                block['icon'] as IconData,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block['title'] as String,
                      style: isIOS 
                          ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
                          : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      block['subtitle'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaqSection(BuildContext context, ThemeData theme, bool isIOS) {
    final l10n = AppLocalizations.of(context);

    final faqItems = [
      {
        'question': l10n?.fediverseEducationFaq1Question ?? 'Who\'s in charge?',
        'answer': l10n?.fediverseEducationFaq1Answer ?? 'Each neighborhood has its own friendly helpers who make sure everyone plays nice.',
      },
      {
        'question': l10n?.fediverseEducationFaq2Question ?? 'Who owns this?',
        'answer': l10n?.fediverseEducationFaq2Answer ?? 'Nobody! It\'s like a bunch of independent neighborhoods that decided to be friends.',
      },
      {
        'question': l10n?.fediverseEducationFaq3Question ?? 'What if I don\'t like my server?',
        'answer': l10n?.fediverseEducationFaq3Answer ?? 'You can pack up and move to a different neighborhood anytime! Your friends can come with you.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          if (isIOS) {
            return _buildIOSFaqItem(context, theme, index, item);
          } else {
            return _buildAndroidFaqItem(context, theme, index, item);
          }
        }),
      ],
    );
  }

  Widget _buildIOSFaqItem(BuildContext context, ThemeData theme, int index, Map<String, String> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
      child: Semantics(
        button: true,
        label: '${item['question']}, ${_faqExpanded[index] ? 'expanded' : 'collapsed'}',
        child: GestureDetector(
          onTap: () => _toggleFaqItem(index),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['question']!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _faqExpanded[index] ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _faqExpanded[index]
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item['answer']!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidFaqItem(BuildContext context, ThemeData theme, int index, Map<String, String> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            item['question']!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['answer']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          onExpansionChanged: (expanded) {
            setState(() {
              _faqExpanded[index] = expanded;
            });
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isIOS) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Primary button - Continue
        SizedBox(
          width: double.infinity,
          height: isIOS ? 52 : 48,
          child: isIOS
              ? CupertinoButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    l10n?.fediverseEducationContinueButton ?? 'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                )
              : FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n?.fediverseEducationContinueButton ?? 'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  void _toggleFaqItem(int index) {
    setState(() {
      _faqExpanded[index] = !_faqExpanded[index];
    });

    if (_faqExpanded[index]) {
      _faqAnimationControllers[index].forward();
    } else {
      _faqAnimationControllers[index].reverse();
    }
  }

  void _showRecommendedServers(BuildContext context) {
    // Close current sheet and show the quick quiz to start the recommendation flow
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickQuizSheet(),
    );
  }
}
