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
    // Get the authorization code from the deep link
    // We need to use GoRouter to access query parameters
    final routerState = GoRouterState.of(context);
    final queryParams = routerState.uri.queryParameters;
    
    debugPrint('OAuth callback - Processing callback with URI: ${routerState.uri}');
    debugPrint('OAuth callback - Query parameters: $queryParams');
    debugPrint('OAuth callback - Widget state: ${widget.state}');
    
    // Check for error parameters first
    if (queryParams.containsKey('error')) {
      final error = queryParams['error'];
      final errorDescription = queryParams['error_description'] ?? 'Unknown error';
      debugPrint('OAuth callback - Error received: $error - $errorDescription');
      setState(() {
        _errorMessage = 'Authentication error: $errorDescription';
        _isLoading = false;
      });
      return;
    }
    
    // Try to get code from widget parameter first, then query parameters
    String? code = widget.code ?? queryParams['code'];
    String? state = queryParams['state'] ?? widget.state;
    String domain = queryParams['domain'] ?? widget.domain;
    
    // If code is not in query parameters, check if it's in the fragment
    if ((code == null || code.isEmpty) && routerState.uri.fragment.isNotEmpty) {
      debugPrint('OAuth callback - Checking fragment for code: ${routerState.uri.fragment}');
      // Parse the fragment as query parameters
      final fragmentParams = Uri.splitQueryString(routerState.uri.fragment);
      code = fragmentParams['code'];
      
      // Also check for state and domain in fragment
      if (state == null || state.isEmpty) {
        state = fragmentParams['state'];
      }
      
      if (domain.isEmpty) {
        domain = fragmentParams['domain'] ?? domain;
      }
      
      debugPrint('OAuth callback - Code from fragment: $code');
      debugPrint('OAuth callback - State from fragment: $state');
      debugPrint('OAuth callback - Domain from fragment: $domain');
    }
    
    debugPrint('OAuth callback - Final extracted code: $code');
    debugPrint('OAuth callback - Final extracted state: $state');
    debugPrint('OAuth callback - Final extracted domain: $domain');
    
    // Validate the state parameter if we have one
    if (state != null && state != widget.state) {
      debugPrint('OAuth callback - State mismatch: $state != ${widget.state}');
      setState(() {
        _errorMessage = 'Invalid state parameter. Authentication failed.';
        _isLoading = false;
      });
      return;
    }
    
    // Check if we have a code
    if (code == null || code.isEmpty) {
      debugPrint('OAuth callback - No authorization code received');
      setState(() {
        _errorMessage = 'No authorization code received. Authentication failed.';
        _isLoading = false;
      });
      return;
    }
    
    // Check if we have a domain
    if (domain.isEmpty) {
      debugPrint('OAuth callback - No domain received');
      setState(() {
        _errorMessage = 'No domain received. Authentication failed.';
        _isLoading = false;
      });
      return;
    }
    
    debugPrint('OAuth callback - Proceeding with code: $code, state: $state, domain: $domain');
    
    try {
      // Complete the OAuth flow
      debugPrint('OAuth callback - Calling completeOAuthFlow with domain: $domain, code: $code, state: $state');
      final success = await ref.read(authRepositoryProvider).completeOAuthFlow(
        domain,
        code,
        state: state,
      );
      
      if (success) {
        // Navigate to the home screen
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('OAuth callback - Error during authentication: $e');
      setState(() {
        _errorMessage = e.toString().contains('Exception:') 
            ? e.toString().split('Exception:')[1].trim() 
            : 'An error occurred during authentication. Please try again.';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completing Login'),
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
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Authentication Error',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/auth/login'),
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
