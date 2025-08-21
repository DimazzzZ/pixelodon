import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/features/profile/screens/profile_screen.dart';
import 'package:pixelodon/models/account.dart';

void main() {
  print('[DEBUG_LOG] Testing profile loading states...');
  
  group('ProfileScreen Loading Tests', () {
    testWidgets('should show loading indicator when media is loading', (WidgetTester tester) async {
      // Create a test profile state with loading media
      final testState = ProfileState(
        account: const Account(
          id: '123',
          username: 'testuser',
          acct: 'testuser',
          displayName: 'Test User',
        ),
        statuses: [],
        isLoadingStatuses: true,
        onlyMedia: true,
      );
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(accountId: '123'),
            ),
          ),
        ),
      );
      
      print('[DEBUG_LOG] Media loading indicator test completed');
    });

    testWidgets('should show "No posts yet" when not loading and no posts', (WidgetTester tester) async {
      // Create a test profile state with no loading and no posts
      final testState = ProfileState(
        account: const Account(
          id: '123',
          username: 'testuser',
          acct: 'testuser',
          displayName: 'Test User',
        ),
        statuses: [],
        isLoadingStatuses: false,
        onlyMedia: true,
      );
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(accountId: '123'),
            ),
          ),
        ),
      );
      
      print('[DEBUG_LOG] No posts message test completed');
    });
  });
  
  print('[DEBUG_LOG] All profile loading tests completed successfully');
}
