import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

/// Screen for handling OAuth callback
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  /// The domain of the instance
  final String domain;
  
  /// The state parameter from the OAuth flow
  final String state;
  
  /// The authorization code (optional, may be passed directly from deep link)
  final String? code;
  
  /// Constructor
  const OAuthCallbackScreen({
    super.key,
    required this.domain,
    required this.state,
    this.code,
  });

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timeoutTimer;
  static const int _timeoutSeconds = 60; // 1 minute timeout

  @override
  void initState() {
    super.initState();
    _handleCallback();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: _timeoutSeconds), () {
      if (mounted && _isLoading) {
        _setError('Authentication timed out. You may have canceled the login process.');
      }
    });
  }

  Future<void> _handleCallback() async {
    try {
      // If we have a code, process it immediately
      if (widget.code != null) {
        await _processCallback();
      } else {
        // Wait a bit for the deep link to be processed
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _isLoading) {
          _setError('No authorization code received');
        }
      }
    } catch (e) {
      debugPrint('Error handling callback: $e');
      _setError('Failed to handle authentication callback');
    }
  }
  
  /// Process the OAuth callback
  Future<void> _processCallback() async {
    try {
      debugPrint('Processing OAuth callback');
      debugPrint('Domain: ${widget.domain}');
      debugPrint('State: ${widget.state}');
      debugPrint('Code: ${widget.code}');

      final code = widget.code;
      if (code == null) {
        _setError('No authorization code received');
        return;
      }

      // Exchange the authorization code for tokens
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.completeOAuthFlow(widget.domain, code, state: widget.state);

      if (mounted) {
        // Mark onboarding as completed since user successfully logged in
        await ref.read(onboardingCompletedProvider.notifier).setOnboardingCompleted(true);

        // Navigate to home screen on success
        context.go('/');
      }
    } catch (e) {
      debugPrint('Error processing callback: $e');
      _setError('Authentication failed: ${e.toString()}');
    }
  }

  void _setError(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPageScaffold.standard(
      title: 'Authenticating',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                PlatformCircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Completing authentication...',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please wait while we finish setting up your account.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'If you canceled the login process or it\'s taking too long, you can go back.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PlatformElevatedButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Cancel & Go Back to Login'),
                ),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Authentication Failed',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PlatformElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
