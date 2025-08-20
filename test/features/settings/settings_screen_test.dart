import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';

void main() {
  group('SettingsScreen Multiple Account Tests', () {
    testWidgets('should display multiple accounts when available', (tester) async {
      // Create test data
      final testInstances = [
        const Instance(
          domain: 'mastodon.social',
          name: 'Mastodon Social',
          isPixelfed: false,
        ),
        const Instance(
          domain: 'pixelfed.social',
          name: 'Pixelfed Social', 
          isPixelfed: true,
        ),
      ];

      final testAccount1 = const Account(
        id: '1',
        username: 'testuser1',
        acct: 'testuser1@mastodon.social',
        displayName: 'Test User 1',
        domain: 'mastodon.social',
      );

      final testAccount2 = const Account(
        id: '2', 
        username: 'testuser2',
        acct: 'testuser2@pixelfed.social',
        displayName: 'Test User 2',
        domain: 'pixelfed.social',
        isPixelfed: true,
      );

      // Build the widget with providers
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => testInstances),
            activeInstanceProvider.overrideWith((ref) => testInstances.first),
            accountInfoProvider.overrideWith((ref, domain) {
              switch (domain) {
                case 'mastodon.social':
                  return testAccount1;
                case 'pixelfed.social':
                  return testAccount2;
                default:
                  return null;
              }
            }),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
      
      // Verify accounts are displayed
      expect(find.text('Test User 1'), findsOneWidget);
      expect(find.text('Test User 2'), findsOneWidget);
      expect(find.text('@testuser1@mastodon.social'), findsOneWidget);
      expect(find.text('@testuser2@pixelfed.social'), findsOneWidget);
      
      // Verify add account button is present
      expect(find.text('Add Account'), findsOneWidget);
      
      // Verify active account indicator
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display add account button when no accounts exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
      
      // Verify add account button is still present
      expect(find.text('Add Account'), findsOneWidget);
      
      // Verify no logout button when no accounts
      expect(find.text('Log Out Current Account'), findsNothing);
    });

    testWidgets('should show account management options', (tester) async {
      final testInstance = const Instance(
        domain: 'mastodon.social',
        name: 'Mastodon Social',
        isPixelfed: false,
      );

      final testAccount = const Account(
        id: '1',
        username: 'testuser',
        acct: 'testuser@mastodon.social',
        displayName: 'Test User',
        domain: 'mastodon.social',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => [testInstance]),
            activeInstanceProvider.overrideWith((ref) => testInstance),
            accountInfoProvider.overrideWith((ref, domain) => 
              domain == 'mastodon.social' ? testAccount : null),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Find and tap the popup menu button
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);
      
      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Verify remove account option is present
      expect(find.text('Remove account'), findsOneWidget);
    });
  });
}
