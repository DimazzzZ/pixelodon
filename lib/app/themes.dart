import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTheme {
  const AppTheme({
    required this.light,
    required this.dark,
    required this.mode,
  });

  final ThemeData light;
  final ThemeData dark;
  final ThemeMode mode;
}

final appThemeProvider = StateProvider<AppTheme>((ref) {
  final baseLight = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    brightness: Brightness.light,
  );
  final baseDark = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
    useMaterial3: true,
    brightness: Brightness.dark,
  );
  return AppTheme(light: baseLight, dark: baseDark, mode: ThemeMode.system);
});

