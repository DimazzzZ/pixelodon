import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ThemeType { light, dark, amoled }

class AppTheme {
  static const String fontFamily = 'Inter';
  
  // Common colors
  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color successColor = Color(0xFF66BB6A);
  
  // Light theme colors
  static const Color _lightBackgroundColor = Color(0xFFFAFAFA);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightTextColor = Color(0xFF212121);
  static const Color _lightSecondaryTextColor = Color(0xFF757575);
  static const Color _lightDividerColor = Color(0xFFE0E0E0);
  
  // Dark theme colors
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color _darkTextColor = Color(0xFFEEEEEE);
  static const Color _darkSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color _darkDividerColor = Color(0xFF424242);
  
  // AMOLED theme colors
  static const Color _amoledBackgroundColor = Colors.black;
  static const Color _amoledSurfaceColor = Color(0xFF121212);
  static const Color _amoledTextColor = Colors.white;
  static const Color _amoledSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color _amoledDividerColor = Color(0xFF323232);

  static ThemeData getLightTheme() {
    return _getTheme(
      brightness: Brightness.light,
      backgroundColor: _lightBackgroundColor,
      surfaceColor: _lightSurfaceColor,
      textColor: _lightTextColor,
      secondaryTextColor: _lightSecondaryTextColor,
      dividerColor: _lightDividerColor,
    );
  }

  static ThemeData getDarkTheme() {
    return _getTheme(
      brightness: Brightness.dark,
      backgroundColor: _darkBackgroundColor,
      surfaceColor: _darkSurfaceColor,
      textColor: _darkTextColor,
      secondaryTextColor: _darkSecondaryTextColor,
      dividerColor: _darkDividerColor,
    );
  }

  static ThemeData getAmoledTheme() {
    return _getTheme(
      brightness: Brightness.dark,
      backgroundColor: _amoledBackgroundColor,
      surfaceColor: _amoledSurfaceColor,
      textColor: _amoledTextColor,
      secondaryTextColor: _amoledSecondaryTextColor,
      dividerColor: _amoledDividerColor,
    );
  }

  static ThemeData _getTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color dividerColor,
  }) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dividerColor: dividerColor,
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: secondaryTextColor),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: secondaryTextColor),
        labelSmall: TextStyle(color: secondaryTextColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _darkSurfaceColor : _lightTextColor,
        contentTextStyle: TextStyle(
          color: isDark ? _darkTextColor : _lightSurfaceColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
