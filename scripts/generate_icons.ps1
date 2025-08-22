<#
Generate app icons for Android, iOS, Web, macOS, Windows, and Linux from assets/images/logo.png
Requirements: Flutter SDK installed and available in PATH
#>

$ErrorActionPreference = "Stop"

# Move to repo root (current script directory/..)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Join-Path $scriptDir ".."
Set-Location $repoRoot

# Check Flutter is available
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "[generate_icons] ERROR: Flutter SDK not found in PATH. Install Flutter and try again."
}

# Ensure dependencies are fetched
flutter pub get

# Run the launcher icons generator (reads config from pubspec.yaml -> flutter_launcher_icons)
flutter pub run flutter_launcher_icons

Write-Host "[generate_icons] Done. Icons have been generated for supported platforms as configured in pubspec.yaml."
