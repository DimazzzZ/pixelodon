import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pixelodon/core/routing/app_router.dart';
import 'package:pixelodon/core/theme/app_theme.dart';
import 'package:pixelodon/services/deep_link_service.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (non-fatal if missing)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Ignore if .env is absent; defaults will apply
  }
  
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
  
  /// Helper function to convert ThemeMode to Brightness for Cupertino
  Brightness _getBrightnessForThemeMode(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the router from the provider
    final router = ref.watch(appRouterProvider);
    // Get the current theme mode from settings
    final themeMode = ref.watch(themeModeProvider);
    
    return PlatformApp.router(
      title: 'Pixelodon',
      material: (context, platform) => MaterialAppRouterData(
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
        ],
      ),
      cupertino: (context, platform) => CupertinoAppRouterData(
        theme: CupertinoThemeData(
          brightness: _getBrightnessForThemeMode(themeMode, context),
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
        ],
      ),
      routerConfig: router,
    );
  }
}
