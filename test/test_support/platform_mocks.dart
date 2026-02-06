import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up mock platform channels for testing.
/// 
/// This should be called in setUp() blocks or at the start of test files
/// that use widgets requiring platform channels (like app_links, url_launcher, etc.)
void setupPlatformChannelMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock app_links channel
  _setupAppLinksMock();
  
  // Mock url_launcher channel
  _setupUrlLauncherMock();
  
  // Mock path_provider channel
  _setupPathProviderMock();
  
  // Mock shared_preferences channel
  _setupSharedPreferencesMock();
  
  // Mock flutter_secure_storage channel
  _setupSecureStorageMock();
}

/// Mock app_links platform channel
void _setupAppLinksMock() {
  const MethodChannel channel = MethodChannel('com.llfbandit.app_links/messages');
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getInitialLink':
        return null; // No initial deep link
      case 'getLatestLink':
        return null;
      default:
        return null;
    }
  });
  
  // Also mock the event channel for app_links
  const EventChannel eventChannel = EventChannel('com.llfbandit.app_links/events');
  // Event channels are more complex to mock, but for most tests returning null is sufficient
}

/// Mock url_launcher platform channel
void _setupUrlLauncherMock() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'canLaunch':
        return true;
      case 'launch':
        return true;
      case 'closeWebView':
        return null;
      default:
        return null;
    }
  });
  
  // Also mock the newer url_launcher channels
  const MethodChannel macosChannel = MethodChannel('plugins.flutter.io/url_launcher_macos');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(macosChannel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'canLaunch':
        return true;
      case 'launch':
        return true;
      default:
        return null;
    }
  });
}

/// Mock path_provider platform channel
void _setupPathProviderMock() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getTemporaryDirectory':
        return '/tmp';
      case 'getApplicationDocumentsDirectory':
        return '/tmp/documents';
      case 'getApplicationSupportDirectory':
        return '/tmp/support';
      case 'getLibraryDirectory':
        return '/tmp/library';
      default:
        return null;
    }
  });
  
  // Also mock macOS-specific channel
  const MethodChannel macosChannel = MethodChannel('plugins.flutter.io/path_provider_macos');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(macosChannel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getTemporaryDirectory':
        return '/tmp';
      case 'getApplicationDocumentsDirectory':
        return '/tmp/documents';
      case 'getApplicationSupportDirectory':
        return '/tmp/support';
      case 'getLibraryDirectory':
        return '/tmp/library';
      default:
        return null;
    }
  });
}

/// Mock shared_preferences platform channel
void _setupSharedPreferencesMock() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/shared_preferences');
  
  // In-memory storage for testing
  final Map<String, Object> storage = {};
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getAll':
        return storage;
      case 'setString':
        final args = methodCall.arguments as Map;
        storage[args['key'] as String] = args['value'];
        return true;
      case 'setBool':
        final args = methodCall.arguments as Map;
        storage[args['key'] as String] = args['value'];
        return true;
      case 'setInt':
        final args = methodCall.arguments as Map;
        storage[args['key'] as String] = args['value'];
        return true;
      case 'setDouble':
        final args = methodCall.arguments as Map;
        storage[args['key'] as String] = args['value'];
        return true;
      case 'setStringList':
        final args = methodCall.arguments as Map;
        storage[args['key'] as String] = args['value'];
        return true;
      case 'remove':
        storage.remove(methodCall.arguments['key']);
        return true;
      case 'clear':
        storage.clear();
        return true;
      default:
        return null;
    }
  });
}

/// Mock flutter_secure_storage platform channel
void _setupSecureStorageMock() {
  const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  
  // In-memory secure storage for testing
  final Map<String, String> secureStorage = {};
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'read':
        final args = methodCall.arguments as Map;
        return secureStorage[args['key']];
      case 'write':
        final args = methodCall.arguments as Map;
        secureStorage[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        final args = methodCall.arguments as Map;
        secureStorage.remove(args['key']);
        return null;
      case 'deleteAll':
        secureStorage.clear();
        return null;
      case 'readAll':
        return secureStorage;
      case 'containsKey':
        final args = methodCall.arguments as Map;
        return secureStorage.containsKey(args['key']);
      default:
        return null;
    }
  });
}

/// Clears all platform channel mocks.
/// Call this in tearDown() if needed.
void clearPlatformChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/messages'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher_macos'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider_macos'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
}
