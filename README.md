# Federated Client (Flutter)

A high-performance, privacy-respecting Fediverse client for Mastodon and Pixelfed. Built with Flutter, Riverpod, Dio, and Hive. Modular adapters for ActivityPub-compatible services.

## Contents
- Quick Start
- Environment & OAuth
- Project Layout
- Codegen & Development
- Running & Testing
- Lints & Formatting
- Troubleshooting

## Quick Start

Prerequisites:
- Flutter 3.22+ (Dart 3.4+)
- Android Studio/Xcode for mobile targets
- CocoaPods for iOS (`sudo gem install cocoapods`)

Commands:
```bash
# From project root
flutter pub get

# Generate Freezed & JSON code
dart run build_runner build -d

# Create platform folders if missing
flutter create . --platforms=android,ios

# List devices and run
flutter devices
flutter run -d <DEVICE_ID>
```

You should land on the login screen; tap Continue to view the stubbed timeline. Real API can be enabled once OAuth is configured.

## Environment & OAuth

This scaffold defaults to mock/stubbed navigation. To talk to real instances:

1) Fill `.env` using the provided template:
```bash
cp .env.sample .env
# Edit values for your instances
```

`.env.sample` fields:
```
APP_NAME=FederatedClient
USER_AGENT=FederatedClient/0.1 (+https://example.org)
ENABLE_REAL_APIS=false

# OAuth per-instance (create an Application on the server)
MASTODON_BASE_URL=https://mastodon.social
MASTODON_CLIENT_ID=
MASTODON_CLIENT_SECRET=

PIXELFED_BASE_URL=https://pixelfed.social
PIXELFED_CLIENT_ID=
PIXELFED_CLIENT_SECRET=

# Deep link (redirect URI) configuration used during OAuth
REDIRECT_SCHEME=fedclient
REDIRECT_HOST=auth
```

2) Create OAuth apps on your instances:
- Mastodon: Settings → Development → New application
- Pixelfed: Settings → Developer → New application

Use redirect URI: `fedclient://auth` (or your chosen scheme/host). Add required scopes:
- Mastodon: `read write follow push`
- Pixelfed: similar to Mastodon (read/write), plus any story/media scopes if available

3) Configure deep links:
- Android: add intent-filter for `fedclient://auth`
- iOS: add URL Types with scheme `fedclient`

Note: The current scaffold hardcodes env defaults in `lib/core/env.dart`. Wire your `.env` or flavor defines as you progress (e.g., using `flutter_dotenv` or `--dart-define`), then propagate values into DI.

## Project Layout

```
/lib
  /app            # App root, DI, themes, router
  /core           # Result, error, env, domain models (Freezed)
  /features
    /auth         # OAuth2 UI stubs (instance input)
    /accounts     # Multi-account switcher stub
    /timeline     # Timeline page (list)
    /compose      # (to be implemented)
    /media        # (to be implemented)
    /profile      # (to be implemented)
    /search       # (to be implemented)
    /notifications# (to be implemented)
    /explore      # (to be implemented)
    /settings     # (to be implemented)
  /infra
    /api          # Protocol adapters
      /mastodon   # MastodonApi
      /pixelfed   # PixelfedApi
    /storage      # Hive boxes (to be added)
    /push         # FCM abstraction (to be added)
    /sync         # Background sync (to be added)
```

Key differences handled in adapters:
- Mastodon: statuses with up to 4 `media_attachments` → `Post.kind` text/photo/album
- Pixelfed: albums (up to 20), EXIF, stories (if supported) → mapped to `Post`/`Story`
- Both preserve raw JSON in domain models for forward-compatibility

## Codegen & Development

Generate models whenever you change files under `lib/core/models`:
```bash
dart run build_runner build -d
# or watch for changes
dart run build_runner watch -d
```

Run with hot reload:
```bash
flutter run -d <DEVICE_ID>
```

## Running & Testing

Unit tests and golden tests (samples to be added as features progress):
```bash
flutter test
```

## Lints & Formatting

This project uses `very_good_analysis`.
```bash
flutter format .
flutter analyze
```

## Troubleshooting

- Flutter not found: ensure `flutter --version` works and PATH is set.
- iOS CocoaPods errors: `cd ios && pod install && cd ..`
- Android Gradle errors: open Android module in Android Studio and sync.
- Codegen not found: run `dart run build_runner build -d`.
- Deep link not handled: add platform-specific URL handlers for your redirect scheme.

## License

MIT (or your preferred license).