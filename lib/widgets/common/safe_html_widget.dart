import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// A widget that renders HTML content with security constraints
/// 
/// This widget provides a secure way to render HTML content by:
/// - Disabling dangerous tags like script, iframe, embed, object
/// - Providing consistent styling
/// - Handling links safely
class SafeHtmlWidget extends StatelessWidget {
  /// The HTML content to render
  final String htmlContent;
  
  /// Optional callback when a link is tapped
  final Function(String? url)? onLinkTap;
  
  /// Additional custom styles (optional)
  final Map<String, Style>? customStyles;

  const SafeHtmlWidget({
    super.key,
    required this.htmlContent,
    this.onLinkTap,
    this.customStyles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Default styles with security in mind
    final defaultStyles = <String, Style>{
      "body": Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      "p": Style(
        margin: Margins.only(bottom: 8),
      ),
      "a": Style(
        color: theme.colorScheme.primary,
      ),
    };
    
    // Merge custom styles if provided
    final finalStyles = customStyles != null 
        ? {...defaultStyles, ...customStyles!}
        : defaultStyles;

    return Html(
      data: htmlContent,
      style: finalStyles,
      onLinkTap: (url, _, __) {
        if (onLinkTap != null) {
          onLinkTap!(url);
        } else {
          // Default safe link handling - validate URL before any action
          if (url != null && Uri.tryParse(url) != null) {
            // TODO: Implement safe link handling (e.g., open in browser with warning)
            debugPrint('Link tapped: $url');
          }
        }
      },
      extensions: [
        // Disable potentially dangerous tags for security
        TagWrapExtension(
          tagsToWrap: {"script", "iframe", "embed", "object", "form", "input"},
          builder: (child) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
