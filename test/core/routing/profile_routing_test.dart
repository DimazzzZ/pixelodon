import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/core/routing/app_router.dart';

void main() {
  print('[DEBUG_LOG] Testing profile routing...');
  
  // Create a test container
  final container = ProviderContainer();
  
  try {
    // Get the router
    final router = container.read(appRouterProvider);
    
    print('[DEBUG_LOG] Router created successfully');
    
    // Test navigation to /profile
    router.go('/profile');
    
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    print('[DEBUG_LOG] Current location after navigating to /profile: $currentLocation');
    
    // Test navigation to /profile/123
    router.go('/profile/123');
    
    final specificProfileLocation = router.routerDelegate.currentConfiguration.uri.path;
    print('[DEBUG_LOG] Current location after navigating to /profile/123: $specificProfileLocation');
    
    print('[DEBUG_LOG] Profile routing test completed successfully');
    
  } catch (e, stackTrace) {
    print('[DEBUG_LOG] Error during profile routing test: $e');
    print('[DEBUG_LOG] Stack trace: $stackTrace');
  }
  
  container.dispose();
}
