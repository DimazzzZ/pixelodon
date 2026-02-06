import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';

void main() {
  group('SettingsScreen Settings Tests', () {
    testWidgets('should display app settings with current values', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app settings section
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('should display about section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify about section
      expect(find.text('About'), findsOneWidget);
      expect(find.text('About Pixelodon'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('should display add account button when no accounts exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify add account button is present
      expect(find.text('Add Account'), findsOneWidget);

      // Verify no logout button when no accounts
      expect(find.text('Log Out Current Account'), findsNothing);
    });

    testWidgets('should show logout button when accounts exist', (tester) async {
      const testInstance = Instance(
        domain: 'mastodon.social',
        name: 'Mastodon Social',
        isPixelfed: false,
      );

      const testAccount = Account(
        id: '1',
        username: 'testuser',
        acct: 'testuser',
        displayName: 'Test User',
        domain: 'mastodon.social',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => [testInstance]),
            activeInstanceProvider.overrideWith((ref) => testInstance),
            accountInfoProvider('mastodon.social').overrideWith((ref) => testAccount),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to find the logout button (it's at the bottom)
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify logout button is present when accounts exist
      expect(find.text('Log Out Current Account'), findsOneWidget);
    });

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

      const testAccount1 = Account(
        id: '1',
        username: 'testuser1',
        acct: 'testuser1',
        displayName: 'Test User 1',
        domain: 'mastodon.social',
      );

      const testAccount2 = Account(
        id: '2',
        username: 'testuser2',
        acct: 'testuser2',
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
            accountInfoProvider('mastodon.social').overrideWith((ref) => testAccount1),
            accountInfoProvider('pixelfed.social').overrideWith((ref) => testAccount2),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify accounts section exists
      expect(find.text('Accounts'), findsOneWidget);

      // Verify accounts are displayed
      expect(find.text('Test User 1'), findsOneWidget);
      expect(find.text('Test User 2'), findsOneWidget);

      // Verify add account button is present
      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('should use Scaffold on Material platform', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
          ],
          child: const PlatformApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On Android/Material, it uses Scaffold with SliverAppBar
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
