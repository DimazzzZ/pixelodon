import 'package:pixelodon/core/domain/asset_loader.dart';

/// Mock implementation of AssetLoader for testing.
/// Allows injection of custom JSON responses without relying on rootBundle.
class MockAssetLoader implements AssetLoader {
  final Map<String, String> _assets;
  final Exception? _throwOnLoad;
  int loadCallCount = 0;

  /// Create a mock that returns the given JSON for any path.
  MockAssetLoader.withJson(String json) 
      : _assets = {'assets/instances/curated.json': json},
        _throwOnLoad = null;

  /// Create a mock with specific path-to-content mappings.
  MockAssetLoader.withAssets(Map<String, String> assets)
      : _assets = assets,
        _throwOnLoad = null;

  /// Create a mock that throws an error on load.
  MockAssetLoader.failing([Exception? exception])
      : _assets = {},
        _throwOnLoad = exception ?? Exception('Mock asset load failure');

  @override
  Future<String> loadString(String path) async {
    loadCallCount++;
    if (_throwOnLoad != null) {
      throw _throwOnLoad!;
    }
    final content = _assets[path];
    if (content == null) {
      throw Exception('Asset not found: $path');
    }
    return content;
  }
}

/// Sample test data for curated instances.
class TestInstanceData {
  /// Generate a minimal valid curated.json with configurable instances.
  static String curatedJson({
    List<Map<String, dynamic>>? instances,
  }) {
    final instanceList = instances ?? defaultInstances;
    return '''
{
  "version": 1,
  "updated": "2026-02-09T12:00:00Z",
  "instances": ${_toJsonList(instanceList)}
}
''';
  }

  static String _toJsonList(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < items.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_toJson(items[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }

  static String _toJson(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in map.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":');
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is List) {
        buffer.write('[');
        for (var i = 0; i < (entry.value as List).length; i++) {
          if (i > 0) buffer.write(',');
          final item = (entry.value as List)[i];
          if (item is String) {
            buffer.write('"$item"');
          } else {
            buffer.write('$item');
          }
        }
        buffer.write(']');
      } else {
        buffer.write('${entry.value}');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Default test instances covering various scenarios.
  static List<Map<String, dynamic>> get defaultInstances => [
    {
      'domain': 'mastodon.social',
      'title': 'Mastodon Social',
      'description': 'The original Mastodon server',
      'platform': 'mastodon',
      'languages': ['en'],
      'region': 'Global',
      'activeUsers': 100000,
      'openRegistration': true,
      'moderationStyle': 'balanced',
      'loadScore': 20.0,
      'photoFocused': false,
      'maxMediaPerPost': 4,
    },
    {
      'domain': 'pixelfed.social',
      'title': 'Pixelfed Social',
      'description': 'Photo sharing for everyone',
      'platform': 'pixelfed',
      'languages': ['en'],
      'region': 'Global',
      'activeUsers': 50000,
      'openRegistration': true,
      'moderationStyle': 'balanced',
      'loadScore': 25.0,
      'photoFocused': true,
      'maxMediaPerPost': 20,
    },
    {
      'domain': 'fosstodon.org',
      'title': 'Fosstodon',
      'description': 'Open source focused community',
      'platform': 'mastodon',
      'languages': ['en'],
      'region': 'Global',
      'activeUsers': 30000,
      'openRegistration': true,
      'moderationStyle': 'stricter',
      'loadScore': 15.0,
      'photoFocused': false,
      'maxMediaPerPost': 4,
    },
    {
      'domain': 'german.instance',
      'title': 'German Instance',
      'description': 'German speaking community',
      'platform': 'mastodon',
      'languages': ['de'],
      'region': 'Europe',
      'activeUsers': 5000,
      'openRegistration': true,
      'moderationStyle': 'balanced',
      'loadScore': 10.0,
      'photoFocused': false,
      'maxMediaPerPost': 4,
    },
    {
      'domain': 'photo.focused',
      'title': 'Photo Focused',
      'description': 'For photographers',
      'platform': 'pixelfed',
      'languages': ['en', 'de', 'fr'],
      'region': 'Europe',
      'activeUsers': 8000,
      'openRegistration': true,
      'moderationStyle': 'stricter',
      'loadScore': 18.0,
      'photoFocused': true,
      'maxMediaPerPost': 20,
    },
    {
      'domain': 'freer.speech',
      'title': 'Free Speech Instance',
      'description': 'Minimal moderation',
      'platform': 'mastodon',
      'languages': ['en'],
      'region': 'North America',
      'activeUsers': 2000,
      'openRegistration': true,
      'moderationStyle': 'freer',
      'loadScore': 35.0,
      'photoFocused': false,
      'maxMediaPerPost': 4,
    },
    {
      'domain': 'closed.registration',
      'title': 'Invite Only',
      'description': 'Requires invitation',
      'platform': 'mastodon',
      'languages': ['en'],
      'region': 'Global',
      'activeUsers': 500,
      'openRegistration': false,
      'moderationStyle': 'stricter',
      'loadScore': 5.0,
      'photoFocused': false,
      'maxMediaPerPost': 4,
    },
  ];

  /// Create a single instance JSON map.
  static Map<String, dynamic> instance({
    String domain = 'test.instance',
    String title = 'Test Instance',
    String description = 'A test instance',
    String platform = 'mastodon',
    List<String> languages = const ['en'],
    String region = 'Global',
    int activeUsers = 1000,
    bool openRegistration = true,
    String moderationStyle = 'balanced',
    double loadScore = 20.0,
    bool photoFocused = false,
    int maxMediaPerPost = 4,
  }) => {
    'domain': domain,
    'title': title,
    'description': description,
    'platform': platform,
    'languages': languages,
    'region': region,
    'activeUsers': activeUsers,
    'openRegistration': openRegistration,
    'moderationStyle': moderationStyle,
    'loadScore': loadScore,
    'photoFocused': photoFocused,
    'maxMediaPerPost': maxMediaPerPost,
  };
}
