import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    group('Constants', () {
      test('should have correct font family', () {
        expect(AppTheme.fontFamily, 'Inter');
      });

      test('should have correct color constants', () {
        expect(AppTheme.primaryColor, const Color(0xFF2C8AD7));
        expect(AppTheme.secondaryColor, const Color(0xFF2C8AD7));
        expect(AppTheme.errorColor, const Color(0xFFE53935));
        expect(AppTheme.warningColor, const Color(0xFFFFB74D));
        expect(AppTheme.successColor, const Color(0xFF66BB6A));
      });
    });

    group('ThemeType Enum', () {
      test('should have all theme types', () {
        expect(ThemeType.values.length, 3);
        expect(ThemeType.values.contains(ThemeType.light), isTrue);
        expect(ThemeType.values.contains(ThemeType.dark), isTrue);
        expect(ThemeType.values.contains(ThemeType.amoled), isTrue);
      });
    });

    group('Light Theme', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = AppTheme.getLightTheme();
      });

      test('should have light brightness', () {
        expect(lightTheme.brightness, Brightness.light);
        expect(lightTheme.colorScheme.brightness, Brightness.light);
      });

      test('should use Material 3', () {
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('should have correct font family in text theme', () {
        expect(lightTheme.textTheme.bodyLarge?.fontFamily, AppTheme.fontFamily);
      });

      test('should have correct primary colors', () {
        expect(lightTheme.primaryColor, AppTheme.primaryColor);
        expect(lightTheme.colorScheme.primary, AppTheme.primaryColor);
        expect(lightTheme.colorScheme.onPrimary, Colors.white);
      });

      test('should have correct secondary colors', () {
        expect(lightTheme.colorScheme.secondary, AppTheme.secondaryColor);
        expect(lightTheme.colorScheme.onSecondary, Colors.white);
      });

      test('should have correct error colors', () {
        expect(lightTheme.colorScheme.error, AppTheme.errorColor);
        expect(lightTheme.colorScheme.onError, Colors.white);
      });

      test('should have correct background and surface colors', () {
        expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
        expect(lightTheme.cardColor, Colors.white);
        expect(lightTheme.colorScheme.surface, Colors.white);
        expect(lightTheme.colorScheme.onSurface, const Color(0xFF212121));
      });

      test('should have correct divider color', () {
        expect(lightTheme.dividerColor, const Color(0xFFE0E0E0));
      });

      test('should have correct app bar theme', () {
        final appBarTheme = lightTheme.appBarTheme;
        expect(appBarTheme.backgroundColor, Colors.white);
        expect(appBarTheme.foregroundColor, const Color(0xFF212121));
        expect(appBarTheme.elevation, 0);
        expect(appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.dark);
      });

      test('should have correct text theme colors', () {
        final textTheme = lightTheme.textTheme;
        expect(textTheme.bodyLarge?.color, const Color(0xFF212121));
        expect(textTheme.bodyMedium?.color, const Color(0xFF212121));
        expect(textTheme.bodySmall?.color, const Color(0xFF757575));
        expect(textTheme.labelMedium?.color, const Color(0xFF757575));
        expect(textTheme.labelSmall?.color, const Color(0xFF757575));
      });
    });

    group('Dark Theme', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = AppTheme.getDarkTheme();
      });

      test('should have dark brightness', () {
        expect(darkTheme.brightness, Brightness.dark);
        expect(darkTheme.colorScheme.brightness, Brightness.dark);
      });

      test('should have correct background and surface colors', () {
        expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF121212));
        expect(darkTheme.cardColor, const Color(0xFF1E1E1E));
        expect(darkTheme.colorScheme.surface, const Color(0xFF1E1E1E));
        expect(darkTheme.colorScheme.onSurface, const Color(0xFFEEEEEE));
      });

      test('should have correct divider color', () {
        expect(darkTheme.dividerColor, const Color(0xFF424242));
      });

      test('should have correct app bar theme', () {
        final appBarTheme = darkTheme.appBarTheme;
        expect(appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
        expect(appBarTheme.foregroundColor, const Color(0xFFEEEEEE));
        expect(appBarTheme.elevation, 0);
        expect(appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.light);
      });

      test('should have correct snack bar theme', () {
        final snackBarTheme = darkTheme.snackBarTheme;
        expect(snackBarTheme.backgroundColor, const Color(0xFF1E1E1E));
        expect(snackBarTheme.contentTextStyle?.color, const Color(0xFFEEEEEE));
        expect(snackBarTheme.behavior, SnackBarBehavior.floating);
      });
    });

    group('AMOLED Theme', () {
      late ThemeData amoledTheme;

      setUp(() {
        amoledTheme = AppTheme.getAmoledTheme();
      });

      test('should have dark brightness', () {
        expect(amoledTheme.brightness, Brightness.dark);
        expect(amoledTheme.colorScheme.brightness, Brightness.dark);
      });

      test('should have correct background and surface colors', () {
        expect(amoledTheme.scaffoldBackgroundColor, Colors.black);
        expect(amoledTheme.cardColor, const Color(0xFF121212));
        expect(amoledTheme.colorScheme.surface, const Color(0xFF121212));
        expect(amoledTheme.colorScheme.onSurface, Colors.white);
      });

      test('should have correct divider color', () {
        expect(amoledTheme.dividerColor, const Color(0xFF323232));
      });

      test('should have correct app bar theme', () {
        final appBarTheme = amoledTheme.appBarTheme;
        expect(appBarTheme.backgroundColor, const Color(0xFF121212));
        expect(appBarTheme.foregroundColor, Colors.white);
        expect(appBarTheme.elevation, 0);
        expect(appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.light);
      });
    });

    group('Button Themes', () {
      test('should have correct elevated button theme', () {
        final theme = AppTheme.getLightTheme();
        final elevatedButtonTheme = theme.elevatedButtonTheme;
        final style = elevatedButtonTheme.style!;
        
        expect(style.backgroundColor?.resolve({}), AppTheme.primaryColor);
        expect(style.foregroundColor?.resolve({}), Colors.white);
        expect(style.padding?.resolve({}), const EdgeInsets.symmetric(vertical: 16, horizontal: 24));
      });

      test('should have correct text button theme', () {
        final theme = AppTheme.getLightTheme();
        final textButtonTheme = theme.textButtonTheme;
        final style = textButtonTheme.style!;
        
        expect(style.foregroundColor?.resolve({}), AppTheme.primaryColor);
        expect(style.padding?.resolve({}), const EdgeInsets.symmetric(vertical: 16, horizontal: 24));
      });

      test('should have correct outlined button theme', () {
        final theme = AppTheme.getLightTheme();
        final outlinedButtonTheme = theme.outlinedButtonTheme;
        final style = outlinedButtonTheme.style!;
        
        expect(style.foregroundColor?.resolve({}), AppTheme.primaryColor);
        expect(style.side?.resolve({}), const BorderSide(color: AppTheme.primaryColor));
        expect(style.padding?.resolve({}), const EdgeInsets.symmetric(vertical: 16, horizontal: 24));
      });
    });

    group('Input Decoration Theme', () {
      test('should have correct input decoration theme', () {
        final theme = AppTheme.getLightTheme();
        final inputDecorationTheme = theme.inputDecorationTheme;
        
        expect(inputDecorationTheme.filled, isTrue);
        expect(inputDecorationTheme.fillColor, Colors.white);
        expect(inputDecorationTheme.border, isA<OutlineInputBorder>());
        expect(inputDecorationTheme.enabledBorder, isA<OutlineInputBorder>());
        expect(inputDecorationTheme.focusedBorder, isA<OutlineInputBorder>());
        expect(inputDecorationTheme.errorBorder, isA<OutlineInputBorder>());
      });

      test('should have correct border radius', () {
        final theme = AppTheme.getLightTheme();
        final inputDecorationTheme = theme.inputDecorationTheme;
        
        final border = inputDecorationTheme.border as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(12));
      });
    });

    group('Card Theme', () {
      test('should have correct card theme', () {
        final theme = AppTheme.getLightTheme();
        final cardTheme = theme.cardTheme;
        
        expect(cardTheme.color, Colors.white);
        expect(cardTheme.elevation, 1);
        expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('Dialog Theme', () {
      test('should have correct dialog theme', () {
        final theme = AppTheme.getLightTheme();
        final dialogTheme = theme.dialogTheme;
        
        expect(dialogTheme.backgroundColor, Colors.white);
        expect(dialogTheme.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('Bottom Navigation Theme', () {
      test('should have correct bottom navigation theme', () {
        final theme = AppTheme.getLightTheme();
        final bottomNavTheme = theme.bottomNavigationBarTheme;
        
        expect(bottomNavTheme.backgroundColor, Colors.white);
        expect(bottomNavTheme.selectedItemColor, AppTheme.primaryColor);
        expect(bottomNavTheme.unselectedItemColor, const Color(0xFF757575));
      });
    });
  });
}
