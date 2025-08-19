import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/core/routing/new_app_router.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'package:pixelodon/providers/new_auth_provider.dart';
import 'package:pixelodon/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize deep link handling
  await DeepLinkService().init();
  
  // Run the app with ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: PixelodonApp(),
    ),
  );
}

/// The main app widget
class PixelodonApp extends ConsumerStatefulWidget {
  const PixelodonApp({super.key});

  @override
  ConsumerState<PixelodonApp> createState() => _PixelodonAppState();
}

class _PixelodonAppState extends ConsumerState<PixelodonApp> {
  @override
  void initState() {
    super.initState();
    
    // Initialize the auth repository
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newAuthRepositoryProvider).initialize();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the router from the provider
    final router = ref.watch(newAppRouterProvider);
    
    return MaterialApp.router(
      title: 'Pixelodon',
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
