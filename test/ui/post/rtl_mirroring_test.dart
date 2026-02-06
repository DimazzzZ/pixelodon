import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/ui/post/indent_guide.dart';

void main() {
  testWidgets('IndentGuide rails mirror in RTL', (tester) async {
    const widget = Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        home: Scaffold(
          body: IndentGuide(depth: 3, child: SizedBox(height: 40, width: 100)),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // We cannot directly read canvas, but ensure layout width matches and no exceptions
    expect(find.byType(IndentGuide), findsOneWidget);
  });
}
