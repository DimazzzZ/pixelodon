import 'package:flutter/services.dart';

/// Abstraction for loading assets, primarily for testability.
/// This allows tests to inject mock asset content without relying on
/// Flutter's rootBundle which cannot be mocked in widget tests.
abstract class AssetLoader {
  /// Load a string asset from the given path.
  Future<String> loadString(String path);
}

/// Default implementation using Flutter's rootBundle.
class DefaultAssetLoader implements AssetLoader {
  const DefaultAssetLoader();
  
  @override
  Future<String> loadString(String path) => rootBundle.loadString(path);
}
