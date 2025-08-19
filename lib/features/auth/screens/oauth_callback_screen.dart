import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  
  @override
  void initState() {
    super.initState();
    // Process the callback on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processCallback();
    });
  }
  
  /// Process the OAuth callback
  Future<void> _processCallback() async {
    try {
      final routerState = GoRouterState.of(context);
      final uri = routerState.uri;

      // Try to get code from both query parameters and URI fragment
      String? authCode = widget.code ?? uri.queryParameters['code'];

      // If code is not in query params, check URI fragment
      if (authCode == null && uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        authCode = fragmentParams['code'];
      }

      if (authCode == null) {
        throw Exception('No authorization code found in callback');
      }

      // Check for error in query params or fragment
      final error = uri.queryParameters['error'] ??
        (uri.fragment.isNotEmpty ? Uri.splitQueryString(uri.fragment)['error'] : null);

      if (error != null) {
        final errorDescription = uri.queryParameters['error_description'] ??
          (uri.fragment.isNotEmpty ? Uri.splitQueryString(uri.fragment)['error_description'] : null) ??
          'Unknown error occurred';
        throw Exception(errorDescription);
      }

      // Process the authorization code
      await ref.read(authProvider.notifier).processAuthorizationCode(
        code: authCode,
        domain: widget.domain,
        state: widget.state,
      );

      if (mounted) {
        // Navigate to home on success
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Try Again'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
