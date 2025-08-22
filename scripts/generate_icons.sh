#!/usr/bin/env bash
set -euo pipefail

# Generate app icons for Android, iOS, Web, macOS, Windows, and Linux from assets/images/logo.png
# Requirements: Flutter SDK installed and available in PATH

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
cd "$REPO_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[generate_icons] ERROR: Flutter SDK not found in PATH. Install Flutter and try again." >&2
  exit 1
fi

# Ensure dependencies are fetched
flutter pub get

# Run the launcher icons generator (reads config from pubspec.yaml -> flutter_launcher_icons)
flutter pub run flutter_launcher_icons

echo "[generate_icons] Done. Icons have been generated for supported platforms as configured in pubspec.yaml."
