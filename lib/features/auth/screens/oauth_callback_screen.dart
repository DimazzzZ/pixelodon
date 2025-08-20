import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:pixelodon/providers/auth_provider.dart';

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
  late AppLinks _appLinks;
  Timer? _timeoutTimer;
  static const int _timeoutSeconds = 60; // 1 minute timeout
  
  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _setupDeepLinkListener();
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

  void _setupDeepLinkListener() {
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Received deep link: $uri');
      _processCallback(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
      _setError('Failed to handle authentication callback');
    });
  }

  Future<void> _handleCallback() async {
    try {
      // Get the initial link in case the app was opened by the callback
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial URI: $initialUri');
        await _processCallback(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
      // Continue waiting for deep link
    }
  }
  
  /// Process the OAuth callback
  Future<void> _processCallback(Uri uri) async {
    try {
      debugPrint('Processing callback URI: $uri');
      
      // Check if this is our OAuth callback
      if (uri.scheme != 'pixelodon' || uri.host != 'oauth' || uri.pathSegments.first != 'callback') {
        debugPrint('URI is not OAuth callback: ${uri.scheme}://${uri.host}${uri.path}');
        return;
      }

      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        _setError('Authentication failed: ${errorDescription ?? error}');
        return;
      }

      if (code == null) {
        _setError('No authorization code received');
        return;
      }

      debugPrint('Received authorization code: $code');
      debugPrint('Received state: $state');
      debugPrint('Expected state: ${widget.state}');

      // Verify state if provided
      if (state != widget.state) {
        _setError('State mismatch - possible security issue');
        return;
      }

      // Exchange the authorization code for tokens
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.completeOAuthFlow(widget.domain, code, state: state);

      if (mounted) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticating'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
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
                ElevatedButton(
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
                ElevatedButton(
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
