import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/data/recommendation_engine.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/infra/api/discovery/discovery_repository.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/services/browser_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

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

  // Search suggestions state
  List<InstanceCaps> _suggestions = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  
  @override
  void dispose() {
    _instanceController.dispose();
    _searchDebounce?.cancel();
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

  @override
  void initState() {
    super.initState();
    // Show default suggestions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDefaultSuggestions();
    });
  }

  /// Search for instances based on user input with debouncing
  void _onSearchChanged(String query) {
    // Cancel previous search
    _searchDebounce?.cancel();

    // Show default suggestions if input is empty
    if (query.trim().isEmpty) {
      _showDefaultSuggestions();
      return;
    }

    // Clear suggestions if query is too short
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    // Set searching state
    setState(() {
      _isSearching = true;
    });

    // Debounce the search
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim().toLowerCase());
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    try {
      final suggestions = <InstanceCaps>[];

      // 1. First, search in static curated instances for instant results
      final staticCuratedInstances = _getCuratedPopularServers();
      final curatedMatches = staticCuratedInstances.where((instance) {
        final domain = instance.domain.toLowerCase();
        final title = instance.title.toLowerCase();
        final description = instance.description.toLowerCase();

        return domain.contains(query) ||
               title.contains(query) ||
               description.contains(query);
      }).take(3).toList(); // Limit curated to 3

      suggestions.addAll(curatedMatches);

      // 2. Also search in recommendation engine curated instances
      try {
        final recommendationEngine = ref.read(recommendationEngineProvider);
        final engineCuratedInstances = await recommendationEngine.getAllInstances();

        final engineMatches = engineCuratedInstances.where((instance) {
          final domain = instance.domain.toLowerCase();
          final title = instance.title.toLowerCase();
          final description = instance.description.toLowerCase();

          // Don't add duplicates from static list
          final alreadyExists = suggestions.any((existing) =>
              existing.domain.toLowerCase() == domain);

          return !alreadyExists && (domain.contains(query) ||
                 title.contains(query) ||
                 description.contains(query));
        }).take(2).toList(); // Limit engine results to 2

        suggestions.addAll(engineMatches);
      } catch (e) {
        // If recommendation engine fails, continue with static results
      }

      // 3. Try to discover the query as a direct domain
      if (query.contains('.') && !query.contains(' ')) {
        try {
          final discoveryRepository = ref.read(discoveryRepositoryProvider);
          final discoveredInstance = await discoveryRepository.discoverInstance(query);

          // Check if this instance is not already in curated results
          final alreadyExists = suggestions.any((instance) =>
              instance.domain.toLowerCase() == discoveredInstance.domain.toLowerCase());

          if (!alreadyExists) {
            suggestions.insert(0, discoveredInstance); // Add at the beginning
          }
        } catch (e) {
          // Discovery failed, that's okay - we'll show curated results
        }
      }

      // 4. Search for instances containing the query as substring
      if (!query.contains('.')) {
        await _searchBySubstring(query, suggestions);
      }

      // Note: Removed automatic domain variations to avoid suggesting fake instances
      // Users should type the complete domain if they know it exists

      if (mounted) {
        setState(() {
          _suggestions = suggestions.take(5).toList(); // Limit total to 5
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    }
  }

  /// Search for instances by substring in domain names
  Future<void> _searchBySubstring(String query, List<InstanceCaps> suggestions) async {
    // List of known instance domains that might contain the query
    final knownDomains = [
      // Pixelfed instances
      'pixelfed.social',
      'pixelfed.de',
      'pixelfed.art',
      'pixelfed.fr',
      'pixelfed.tokyo',
      'pixelfed.nz',
      'pixelfed.uno',

      // Mastodon instances
      'mastodon.social',
      'mastodon.online',
      'mastodon.world',
      'mastodon.art',
      'mastodon.gamedev.place',
      'mas.to',
      'mstdn.social',
      'fosstodon.org',
      'hachyderm.io',
      'chaos.social',
      'scholar.social',
      'tech.lgbt',
      'ruby.social',
      'indieweb.social',
      'mozilla.social',
      'vivaldi.net',
      'toot.community',
      'universeodon.com',
      'mathstodon.xyz',
      'photog.social',
      'musicians.today',
      'writing.exchange',
      'bookwyrm.social',
      'wandering.shop',
      'dice.camp',
      'tabletop.social',
      'gamedev.place',
      'techhub.social',
      'infosec.exchange',
      'social.vivaldi.net',
    ];

    // Filter domains that contain the query
    final matchingDomains = knownDomains
        .where((domain) => domain.toLowerCase().contains(query.toLowerCase()))
        .take(3) // Limit to 3 substring matches
        .toList();

    // Try to discover each matching domain
    for (final domain in matchingDomains) {
      try {
        final discoveryRepository = ref.read(discoveryRepositoryProvider);
        final discoveredInstance = await discoveryRepository.discoverInstance(domain);

        // Check if this instance is not already in results
        final alreadyExists = suggestions.any((instance) =>
            instance.domain.toLowerCase() == discoveredInstance.domain.toLowerCase());

        if (!alreadyExists) {
          suggestions.add(discoveredInstance);
        }
      } catch (e) {
        // This instance doesn't exist or discovery failed, continue with next
        continue;
      }
    }
  }

  /// Show default popular suggestions (static, curated list)
  void _showDefaultSuggestions() {
    // Static curated list of popular servers - loads immediately
    final suggestions = _getCuratedPopularServers();

    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
    });
  }

  /// Get curated list of popular servers (static data)
  List<InstanceCaps> _getCuratedPopularServers() {
    return [
      // Mastodon instances
      InstanceCaps(
        domain: 'mastodon.social',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 25.0,
        title: 'Mastodon Social',
        description: 'The original Mastodon server operated by the Mastodon gGmbH non-profit',
        activeUsers: 850000,
        languages: ['en'],
      ),
      InstanceCaps(
        domain: 'mastodon.world',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 20.0,
        title: 'Mastodon World',
        description: 'A general-purpose Mastodon server with a focus on community and moderation',
        activeUsers: 180000,
        languages: ['en'],
      ),
      InstanceCaps(
        domain: 'mas.to',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 15.0,
        title: 'mas.to',
        description: 'A fast, secure and up-to-date Mastodon instance',
        activeUsers: 95000,
        languages: ['en'],
      ),
      InstanceCaps(
        domain: 'fosstodon.org',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 18.0,
        title: 'Fosstodon',
        description: 'A community for anyone interested in technology, particularly free & open source software',
        activeUsers: 45000,
        languages: ['en'],
      ),
      InstanceCaps(
        domain: 'hachyderm.io',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 22.0,
        title: 'Hachyderm',
        description: 'A safe space for tech workers, academics, digital rights activists, and more',
        activeUsers: 35000,
        languages: ['en'],
      ),
      InstanceCaps(
        domain: 'mastodon.online',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 28.0,
        title: 'Mastodon Online',
        description: 'A general-purpose Mastodon instance with a focus on being fast and reliable',
        activeUsers: 120000,
        languages: ['en'],
      ),

      // Pixelfed instances
      InstanceCaps(
        domain: 'pixelfed.social',
        platform: InstancePlatform.pixelfed,
        openRegistration: true,
        maxMediaPerPost: 20,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 30.0,
        title: 'Pixelfed Social',
        description: 'The flagship Pixelfed instance for photo sharing',
        activeUsers: 25000,
        languages: ['en'],
        photoFocused: true,
        supportsStories: true,
      ),
      InstanceCaps(
        domain: 'pixelfed.art',
        platform: InstancePlatform.pixelfed,
        openRegistration: true,
        maxMediaPerPost: 20,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 25.0,
        title: 'Pixelfed Art',
        description: 'A Pixelfed instance focused on art and creative photography',
        activeUsers: 8000,
        languages: ['en'],
        photoFocused: true,
        supportsStories: true,
      ),
      InstanceCaps(
        domain: 'pixelfed.de',
        platform: InstancePlatform.pixelfed,
        openRegistration: true,
        maxMediaPerPost: 20,
        moderationStyle: ModerationStyle.balanced,
        loadScore: 35.0,
        title: 'Pixelfed DE',
        description: 'A German Pixelfed instance for photo sharing',
        activeUsers: 5000,
        languages: ['de'],
        photoFocused: true,
        supportsStories: true,
      ),
    ];
  }

  /// Select a suggested instance
  void _selectSuggestion(InstanceCaps instance) {
    _instanceController.text = instance.domain;
    setState(() {
      _suggestions = [];
      _isSearching = false;
    });
    // Automatically discover the instance
    _discoverInstance();
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

  /// Build the suggestions widget
  Widget _buildSuggestions() {
    final theme = Theme.of(context);

    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: PlatformCircularProgressIndicator(),
            ),
            const SizedBox(width: 12),
            Text(
              'Searching servers...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine if these are default suggestions or search results
    final isDefaultSuggestions = _instanceController.text.trim().isEmpty;
    final headerText = isDefaultSuggestions ? 'Popular servers' : 'Suggested servers';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            headerText,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._suggestions.map((instance) => _buildSuggestionCard(instance)),
      ],
    );
  }

  /// Build a single suggestion card
  Widget _buildSuggestionCard(InstanceCaps instance) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectSuggestion(instance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and platform badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          instance.domain,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Platform badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: instance.platform == InstancePlatform.pixelfed
                          ? theme.colorScheme.secondaryContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          instance.platform == InstancePlatform.pixelfed
                              ? Icons.photo_camera
                              : Icons.forum,
                          size: 14,
                          color: instance.platform == InstancePlatform.pixelfed
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          instance.platform == InstancePlatform.pixelfed ? 'Pixelfed' : 'Mastodon',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: instance.platform == InstancePlatform.pixelfed
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description
              if (instance.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  instance.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Server thumbnail - only show if available
              if (instance.thumbnail != null && instance.thumbnail!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      instance.thumbnail!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // If image fails to load, show nothing
                        return const SizedBox.shrink();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Stats and info
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${instance.activeUsers} users',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to select',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepository = ref.watch(authRepositoryProvider);
    final isLoggedIn = authRepository.instances.isNotEmpty;

    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          title: const Text('Login'),
          // Show back button only if user is not logged in (to go back to onboarding)
          leading: !isLoggedIn ? PlatformIconButton(
            icon: Icon(PlatformIcons(context).back),
            onPressed: () => context.go('/onboarding'),
          ) : null,
        ),
      ),
      usesSlivers: false, // SingleChildScrollView is not sliver-based
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
                  Material(
                    child: TextFormField(
                      controller: _instanceController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., mastodon.social, pixelfed.social',
                        prefixIcon: Icon(Icons.language),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      onChanged: _onSearchChanged,
                      onFieldSubmitted: (_) => _discoverInstance(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an instance domain';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  PlatformElevatedButton(
                    onPressed: _isLoading ? null : _discoverInstance,
                    child: _isLoading && _discoveredInstance == null
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: PlatformCircularProgressIndicator(),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),

            // Server suggestions - show when searching, have suggestions, or input is empty
            if (_isSearching || _suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSuggestions(),
            ],
            
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
                      PlatformElevatedButton(
                        onPressed: _isLoading ? null : _startOAuthFlow,
                        material: (context, platform) => MaterialElevatedButtonData(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: PlatformCircularProgressIndicator(),
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
