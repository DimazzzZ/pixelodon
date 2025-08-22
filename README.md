# Pixelodon

A modern, privacy‑respecting Fediverse client for Mastodon and Pixelfed, built with Flutter. Pixelodon focuses on a smooth cross‑platform experience (Android, iOS, Web, macOS, Windows, Linux) with secure authentication, clean UI, and a foundation for rich media features.

## Table of Contents
- [What is Pixelodon](#what-is-pixelodon)
- [Features](#features)
- [Tech stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
  - [1) Clone and install](#1-clone-and-install)
  - [2) Code generation (Freezed/JSON/Riverpod)](#2-code-generation-freezedjsonriverpod)
  - [3) Platform setup notes (Android, iOS, Web, Desktop)](#3-platform-setup-notes)
- [Running the app](#running-the-app)
- [OAuth, deep linking, and callbacks](#oauth-deep-linking-and-callbacks)
- [Building for release](#building-for-release)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## What is Pixelodon
Pixelodon is a Flutter application that lets you explore and interact with the Fediverse, supporting both Mastodon and Pixelfed instances. It uses secure OAuth flows per instance, stores tokens safely on device, and aims to provide a fast and delightful media‑forward experience.

## Features
- Login with any Mastodon or Pixelfed instance (per‑instance OAuth)
- Instance discovery with capability detection
- Secure token storage and refresh
- Riverpod‑based state management and GoRouter navigation
- Theming (light/dark) and responsive UI
- Multi‑platform support: Android, iOS, Web, macOS, Windows, Linux
- Foundations for media‑rich feeds, explore, notifications, and profiles

Note: Some screens are placeholders and under active development (Home, Explore, Profile, Compose).

## Tech stack
- Flutter (Dart 3)
- Riverpod for state management
- GoRouter for navigation
- Dio for networking
- Hive + Flutter Secure Storage for local/secure persistence
- Firebase Messaging (optional, for push notifications)
- App Links (deep links) and custom URL scheme for OAuth callbacks

## Prerequisites
- Flutter SDK 3.22+ (recommended 3.24.x) and Dart 3.5+ (pubspec uses sdk: ^3.5.2)
- Android Studio or VS Code with Flutter/Dart extensions
- Xcode (for iOS), CocoaPods installed (`sudo gem install cocoapods`)
- Web: Chrome (or another supported browser)
- macOS/Windows/Linux desktop: ensure Flutter desktop is enabled

Check your environment:

```bash
flutter --version
dart --version
flutter doctor
```

## Getting started
### 1) Clone and install

```bash
git clone https://github.com/DimazzzZ/pixelodon.git
cd pixelodon
flutter pub get
```

### 2) Code generation (Freezed/JSON/Riverpod)
This project uses build_runner for code generation.

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

You can re‑run this after making model/provider changes.

### 3) Platform setup notes
The repository already contains sane defaults for deep links and configuration. Review and adjust as needed for your app id, domains, and signing.

Android
- App id: android/app/build.gradle (applicationId) — adjust for your package name
- Deep links: android/app/src/main/AndroidManifest.xml includes an intent filter for the custom scheme pixelodon and some host examples. You may tailor hosts or remove host restrictions to allow any instance domain.
- Minimum setup to run: no additional secrets required. OAuth occurs against the user‑selected instance.

iOS
- URL scheme configured in ios/Runner/Info.plist as pixelodon (CFBundleURLTypes). Update bundle id and signing in Xcode.
- After first install:

```bash
cd ios && pod install
```

Web
- OAuth callback helper page at web/oauth_callback.html bridges the browser back into the app via pixelodon://oauth/callback. This is used when OAuth providers return parameters via fragment or query.
- Base HTML is in web/index.html — ensure correct hosting path (base href) when deploying.

Desktop (macOS/Windows/Linux)
- Enable desktop if not already:

```bash
# macOS
flutter config --enable-macos-desktop
# Windows
flutter config --enable-windows-desktop
# Linux
flutter config --enable-linux-desktop
```

## Technical Mastodon account (optional)
If you want the app to optionally use a technical Mastodon account for requests to a specific Mastodon instance (e.g., when a user opens a Mastodon profile while they are currently authenticated on a Pixelfed instance), you can provide a token via environment variables.

1) Create your local .env from the example:

```bash
cp .env.example .env
```

2) Fill in the variables in .env:

```
TECH_MASTODON_DOMAIN=your-mastodon-instance.tld
TECH_MASTODON_ACCESS_TOKEN=YOUR_LONG_ACCESS_TOKEN
```

Notes:
- The token is only used for Mastodon-powered instances/profiles.
- .env is already git-ignored; never commit your secrets.
- The app loads .env at startup. If no .env is present, it proceeds without the technical account.
- This does not “proxy” to arbitrary Mastodon instances: a token from one instance cannot authorize requests to another instance.

Behavior in app:
- When any API request targets https://TECH_MASTODON_DOMAIN/ and there is no user token for that domain, the app will attach TECH_MASTODON_ACCESS_TOKEN automatically. This enables fetching public or authorized data on that instance without asking the user to log in there.

## Running the app
General

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Run on a target device or simulator/emulator:

```bash
# Android
flutter run -d android
# iOS
flutter run -d ios
# Web (Chrome)
flutter run -d chrome
# macOS
flutter run -d macos
# Windows
flutter run -d windows
# Linux
flutter run -d linux
```

At first launch you’ll be redirected to the login screen.

## OAuth, deep linking, and callbacks
- Pixelodon uses a custom URL scheme: `pixelodon://oauth/callback` (see `lib/services/auth_service.dart`)
- During login, you enter your instance domain (e.g., mastodon.social or a Pixelfed instance). The app:
  1. Discovers the instance and registers the app if needed
  2. Opens the authorization URL in an in‑app web view
  3. Receives the callback via deep link (mobile/desktop) or via `web/oauth_callback.html` (web)

Mobile deep link setup (already configured):
- Android: Intent filter in AndroidManifest.xml handles pixelodon scheme and https with certain hosts and pathPattern `/oauth/.*`. Adjust hosts as desired for your target instances.
- iOS: CFBundleURLTypes in Info.plist includes the scheme `pixelodon`.

Token storage and security:
- Access/refresh tokens are stored using Flutter Secure Storage and Hive.
- Sensitive client credentials are not persisted in request bodies during token refresh and revoke flows (see tests in `test/auth_fix_test.dart`).

## Building for release

```bash
# Android App Bundle (Play Store)
flutter build appbundle
# Android APK
flutter build apk
# iOS (archive from Xcode)
flutter build ipa
# Web (deployable assets in build/web)
flutter build web --release
# macOS
flutter build macos --release
# Windows
flutter build windows --release
# Linux
flutter build linux --release
```

## Testing
Run all tests:

```bash
flutter test
```

Relevant tests include:
- `test/services/deep_link_service_test.dart` — deep link handling and OAuth callback parsing/validation
- `test/core/network/api_service_test.dart` — networking layer behavior
- `test/widget_test.dart` — basic widget smoke test

## Troubleshooting
- Deep link not returning to app on Android: verify the intent filter and that your device/emulator can resolve the `pixelodon` scheme. Consider loosening host restrictions if you authenticate against various instance domains.
- iOS callback not triggered: ensure the URL scheme `pixelodon` is present in Info.plist and the app is installed.
- Web OAuth stuck on callback page: ensure `web/oauth_callback.html` is accessible in your hosting environment and that the browser isn’t blocking the custom scheme redirect.
- build_runner errors:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- CocoaPods issues:

```bash
cd ios && pod repo update && pod install
```

## Contributing
Issues and pull requests are welcome. Please run tests and keep changes minimal, focused, and well‑documented. For larger contributions, consider opening an issue first to discuss scope and design.

## License
This project is licensed under the MIT License. See LICENSE for details.


## App icon generation
You can generate all mandatory icons for Android, iOS, Web, macOS, Windows, and Linux from a single source image at `assets/images/logo.png`.

Requirements:
- Flutter SDK installed and available in your PATH
- Source icon at `assets/images/logo.png` (512x512 or larger PNG with transparent background recommended)

Using the provided scripts:
- macOS/Linux:
  
  ```bash
  ./scripts/generate_icons.sh
  ```

- Windows (PowerShell):
  
  ```powershell
  ./scripts/generate_icons.ps1
  ```

What this does:
- Runs `flutter pub get`
- Runs `flutter pub run flutter_launcher_icons`
- Uses the configuration in `pubspec.yaml` under `flutter_launcher_icons` to generate the icons for all supported platforms.

Notes:
- Android: Generates all required mipmap densities. We use a single image for both legacy and adaptive icons with a white background by default (customize via `web.background_color` etc. in `pubspec.yaml`). If you want a distinct adaptive foreground/background, replace `image_path` with `adaptive_icon_foreground` and `adaptive_icon_background` under the Android config.
- iOS: `remove_alpha_ios: true` is set to avoid App Store warnings. Make sure your logo looks correct without the alpha channel if needed.
- Web: Favicon and manifest icons are updated under `web/`.
- Desktop: macOS, Windows, and Linux icons are generated into their respective platform directories.

Changing the source image:
- Replace `assets/images/logo.png` with your new image (ideally square, >=1024x1024 for best quality), then re-run the script.
