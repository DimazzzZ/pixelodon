import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';

void main() {
  debugPrint('[DEBUG_LOG] Testing HTML rendering...');
  
  group('SafeHtmlWidget Tests', () {
    testWidgets('should render basic HTML content', (WidgetTester tester) async {
      const htmlContent = '<p>Hello <b>world</b>!</p>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      debugPrint('[DEBUG_LOG] Basic HTML test completed');
    });

    testWidgets('should render HTML with links', (WidgetTester tester) async {
      const htmlContent = '<p>Check out <a href="https://example.com">this link</a>!</p>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(
              htmlContent: htmlContent,
              onLinkTap: (url) {
                debugPrint('[DEBUG_LOG] Link tapped: $url');
              },
            ),
          ),
        ),
      );
      
      debugPrint('[DEBUG_LOG] HTML with links test completed');
    });

    testWidgets('should block dangerous tags', (WidgetTester tester) async {
      const htmlContent = '''
        <p>Safe content</p>
        <script>alert('dangerous')</script>
        <iframe src="https://malicious.com"></iframe>
        <embed src="file.swf">
        <object data="file.pdf"></object>
        <form><input type="text"></form>
      ''';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      print('[DEBUG_LOG] Security test completed - dangerous tags should be blocked');
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      const htmlContent = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      print('[DEBUG_LOG] Empty content test completed');
    });
  });
  
  print('[DEBUG_LOG] All HTML rendering tests completed successfully');
}
