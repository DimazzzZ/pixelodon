import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/services/browser_service.dart';

/// Screen for logging in to a Mastodon or Pixelfed instance
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instanceController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  Instance? _discoveredInstance;
  
  @override
  void dispose() {
    _instanceController.dispose();
    super.dispose();
  }
  
  /// Reset loading state when returning to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset loading state when screen becomes active again
    // This handles the case where user returns from OAuth callback
    if (_isLoading && _discoveredInstance != null) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Discover an instance by domain
  Future<void> _discoverInstance() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _discoveredInstance = null;
    });
    
    try {
      final domain = _instanceController.text.trim();
      final instance = await ref.read(authRepositoryProvider).discoverInstance(domain);
      
      setState(() {
        _discoveredInstance = instance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to instance. Please check the domain and try again.';
        _isLoading = false;
      });
    }
  }
  
  /// Start the OAuth flow for the discovered instance
  Future<void> _startOAuthFlow() async {
    if (_discoveredInstance == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final domain = _discoveredInstance!.domain;
      final authInfo = await ref.read(authRepositoryProvider).startOAuthFlow(domain);
      
      // Launch the authorization URL via centralized BrowserService
      final browser = BrowserService();
      await browser.launchURL(authInfo['url']!);

      // Navigate to the callback screen
      if (mounted) {
        context.push('/oauth/callback', extra: {
          'domain': domain,
          'state': authInfo['state'],
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during authentication. Please try again.';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            
            // Logo and app name
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pixelodon',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A Fediverse client for Mastodon and Pixelfed',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Instance form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter your instance domain',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _instanceController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., mastodon.social, pixelfed.social',
                      prefixIcon: Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onFieldSubmitted: (_) => _discoverInstance(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an instance domain';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _discoverInstance,
                    child: _isLoading && _discoveredInstance == null
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            
            // Discovered instance info
            if (_discoveredInstance != null) ...[
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_discoveredInstance!.thumbnail != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _discoveredInstance!.thumbnail!,
                                width: 48,
                                height: 48,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    _discoveredInstance!.isPixelfed
                                        ? Icons.photo_camera
                                        : Icons.chat_bubble,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _discoveredInstance!.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _discoveredInstance!.domain,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (_discoveredInstance!.isPixelfed)
                            Chip(
                              label: const Text('Pixelfed'),
                              avatar: const Icon(Icons.photo_camera, size: 16),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                        ],
                      ),
                      if (_discoveredInstance!.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _discoveredInstance!.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _startOAuthFlow,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login with this instance'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Existing accounts
            Consumer(
              builder: (context, ref, child) {
                final instances = ref.watch(instancesProvider);
                
                if (instances.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Your accounts',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...instances.map((instance) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          instance.isPixelfed ? Icons.photo_camera : Icons.chat_bubble,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(instance.name),
                      subtitle: Text(instance.domain),
                      trailing: const Icon(Icons.login),
                      onTap: () {
                        ref.read(authRepositoryProvider).setActiveInstance(instance.domain);
                        context.go('/home');
                      },
                    )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
