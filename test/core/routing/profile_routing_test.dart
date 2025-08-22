import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/core/routing/app_router.dart';

void main() {
  debugPrint('[DEBUG_LOG] Testing profile routing...');
  
  // Create a test container
  final container = ProviderContainer();
  
  try {
    // Get the router
    final router = container.read(appRouterProvider);
    
    debugPrint('[DEBUG_LOG] Router created successfully');
    
    // Test navigation to /profile
    router.go('/profile');
    
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    debugPrint('[DEBUG_LOG] Current location after navigating to /profile: $currentLocation');
    
    // Test navigation to /profile/123
    router.go('/profile/123');
    
    final specificProfileLocation = router.routerDelegate.currentConfiguration.uri.path;
    debugPrint('[DEBUG_LOG] Current location after navigating to /profile/123: $specificProfileLocation');
    
    debugPrint('[DEBUG_LOG] Profile routing test completed successfully');
    
  } catch (e, stackTrace) {
    debugPrint('[DEBUG_LOG] Error during profile routing test: $e');
    debugPrint('[DEBUG_LOG] Stack trace: $stackTrace');
  }
  
  container.dispose();
}
