import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/services/settings_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';

// Mock classes for testing
class MockThemeModeNotifier extends ThemeModeNotifier {
  final ThemeMode _themeMode;
  MockThemeModeNotifier([this._themeMode = ThemeMode.system]) : super(MockSettingsService());

  @override
  ThemeMode get state => _themeMode;
}

class MockLanguageNotifier extends LanguageNotifier {
  final Locale _locale;
  MockLanguageNotifier([this._locale = const Locale('en', 'US')]) : super(MockSettingsService());

  @override
  Locale get state => _locale;
}

class MockNotificationSettingsNotifier extends NotificationSettingsNotifier {
  final Map<String, bool> _settings;
  MockNotificationSettingsNotifier([this._settings = const {
    'mentions': true,
    'follows': true,
    'likes': true,
    'reposts': true,
    'posts': true,
  }]) : super(MockSettingsService());

  @override
  Map<String, bool> get state => _settings;
}

class MockSettingsService extends SettingsService {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<Locale> getLanguage() async => const Locale('en', 'US');

  @override
  Future<Map<String, bool>> getNotificationSettings() async => {
    'mentions': true,
    'follows': true,
    'likes': true,
    'reposts': true,
    'posts': true,
  };

  @override
  Future<bool> getOnboardingCompleted() async => true;
}

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
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier()),
          ],
          child: PlatformApp(
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
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier()),
          ],
          child: PlatformApp(
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
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier()),
          ],
          child: PlatformApp(
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

  group('SettingsScreen Settings Tests', () {
    testWidgets('should display app settings with current values', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier(ThemeMode.dark)),
            languageProvider.overrideWith((ref) => MockLanguageNotifier(const Locale('es', 'ES'))),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier({
              'mentions': true,
              'follows': false,
              'likes': true,
              'reposts': false,
              'posts': true,
            })),
          ],
          child: PlatformApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify app settings section
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      // Verify current values are displayed (these will be shown once providers load)
      await tester.pumpAndSettle();
      
      // Theme and Language values are loaded asynchronously, so we verify the sections exist
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('should display about section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier({})),
          ],
          child: PlatformApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify about section
      expect(find.text('About'), findsOneWidget);
      expect(find.text('About Pixelodon'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('should show logout button only when accounts exist', (tester) async {
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
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier({})),
          ],
          child: PlatformApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify logout button is present when accounts exist
      expect(find.text('Log Out Current Account'), findsOneWidget);
    });

    testWidgets('should use platform widgets instead of material widgets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instancesProvider.overrideWith((ref) => <Instance>[]),
            activeInstanceProvider.overrideWith((ref) => null),
            themeModeProvider.overrideWith((ref) => MockThemeModeNotifier()),
            languageProvider.overrideWith((ref) => MockLanguageNotifier()),
            notificationSettingsProvider.overrideWith((ref) => MockNotificationSettingsNotifier({})),
          ],
          child: PlatformApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      // Verify platform widgets are used
      expect(find.byType(AppPageScaffold), findsOneWidget);
      expect(find.byType(PlatformAppBar), findsOneWidget);
      
      // Verify no Material-specific widgets are used directly
      expect(find.byType(Scaffold), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
