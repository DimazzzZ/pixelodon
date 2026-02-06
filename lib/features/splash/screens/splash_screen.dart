import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/repositories/auth_repository.dart';

/// Splash screen that shows the app logo and loading indicator
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Set to true in tests to skip the splash delay
  static bool testMode = false;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Initialize and navigate after a short delay
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // The AuthRepository is now automatically initialized by the provider
      // Just ensure the provider is created by reading it
      ref.read(authRepositoryProvider);

      // Wait at least 2 seconds to show the splash screen (skip in test mode)
      if (!SplashScreen.testMode) {
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        // Let the router handle redirection based on auth state and onboarding status
        // Navigate to root and let the router redirect appropriately
        // Use addPostFrameCallback to avoid calling go() during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/');
          }
        });
      }
    } catch (e) {
      // If initialization fails, still allow navigation to login
      debugPrint('Failed to initialize auth repository: $e');

      if (!SplashScreen.testMode) {
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        // Let the router handle redirection
        // Use addPostFrameCallback to avoid calling go() during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),
            
            const SizedBox(height: 24),
            
            // App name
            Text(
              'Pixelodon',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading spinner
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
