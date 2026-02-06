import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/services/auth_service.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('AuthProvider Tests', () {
    late MockAuthService mockAuthService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      
      // Create a container with the mocked auth service
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('AuthRepository should initialize with stored accounts', () async {
      // Arrange
      const testDomain = 'mastodon.social';
      const testInstance = Instance(
        domain: testDomain,
        name: 'Test Instance',
        description: 'Test Description',
        version: '4.0.0',
        languages: ['en'],
      );
      final testAccount = Account(
        id: '123',
        username: 'testuser',
        acct: 'testuser',
        displayName: 'Test User',
        note: 'Test note',
        url: 'https://mastodon.social/@testuser',
        avatar: 'https://example.com/avatar.jpg',
        avatarStatic: 'https://example.com/avatar.jpg',
        header: 'https://example.com/header.jpg',
        headerStatic: 'https://example.com/header.jpg',
        followersCount: 100,
        followingCount: 50,
        statusesCount: 200,
        lastStatusAt: DateTime.now(),
        createdAt: DateTime.now(),
        bot: false,
        locked: false,
        discoverable: true,
        group: false,
        suspended: false,
        fields: const [],
      );

      // Mock the auth service methods
      when(mockAuthService.getAuthenticatedInstances())
          .thenAnswer((_) async => [testDomain]);
      when(mockAuthService.discoverInstance(testDomain))
          .thenAnswer((_) async => testInstance);
      when(mockAuthService.getAccountInfo(testDomain))
          .thenAnswer((_) async => testAccount);

      // Act
      final authState = container.read(authRepositoryProvider);
      final authRepository = container.read(authRepositoryProvider.notifier);
      
      // Wait a bit for the async initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Read the updated state after initialization
      final updatedState = container.read(authRepositoryProvider);

      // Assert
      expect(updatedState.instances, contains(testInstance));
      expect(updatedState.activeInstance, equals(testInstance));
      expect(updatedState.activeAccount, equals(testAccount));
      expect(authRepository.getAccount(testDomain), equals(testAccount));

      // Verify that the auth service methods were called
      verify(mockAuthService.getAuthenticatedInstances()).called(1);
      verify(mockAuthService.discoverInstance(testDomain)).called(1);
      verify(mockAuthService.getAccountInfo(testDomain)).called(1);
    });

    test('AuthRepository should handle initialization errors gracefully', () async {
      // Arrange
      when(mockAuthService.getAuthenticatedInstances())
          .thenThrow(Exception('Storage error'));

      // Act
      final authState = container.read(authRepositoryProvider);
      
      // Wait a bit for the async initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Read the updated state after initialization
      final updatedState = container.read(authRepositoryProvider);

      // Assert - should not crash and should have empty state
      expect(updatedState.instances, isEmpty);
      expect(updatedState.activeInstance, isNull);
      expect(updatedState.activeAccount, isNull);

      // Verify that the auth service method was called
      verify(mockAuthService.getAuthenticatedInstances()).called(1);
    });

    test('AuthRepository logout should remove account and update state', () async {
      // Arrange
      const testDomain = 'mastodon.social';
      const testInstance = Instance(
        domain: testDomain,
        name: 'Test Instance',
        description: 'Test Description',
        version: '4.0.0',
        languages: ['en'],
      );

      // Mock successful initialization
      when(mockAuthService.getAuthenticatedInstances())
          .thenAnswer((_) async => [testDomain]);
      when(mockAuthService.discoverInstance(testDomain))
          .thenAnswer((_) async => testInstance);
      when(mockAuthService.getAccountInfo(testDomain))
          .thenAnswer((_) async => null);
      when(mockAuthService.logout(testDomain))
          .thenAnswer((_) async {});

      // Act
      final authRepository = container.read(authRepositoryProvider.notifier);
      
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Perform logout
      await authRepository.logout(testDomain);
      
      // Read the updated state after logout
      final updatedState = container.read(authRepositoryProvider);

      // Assert
      expect(updatedState.instances, isEmpty);
      expect(updatedState.activeInstance, isNull);
      expect(updatedState.activeAccount, isNull);

      // Verify that logout was called
      verify(mockAuthService.logout(testDomain)).called(1);
    });
  });
}
