import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isohedron/theme/app_theme.dart';

void main() {
  group('iOS Design Tokens - Color Constants', () {
    test('Light mode system color tokens match Apple HIG specifications', () {
      expect(AppTheme.systemBlue, const Color(0xFF007AFF));
      expect(AppTheme.systemBlueLight, const Color(0xFF007AFF));
      expect(AppTheme.systemRed, const Color(0xFFFF3B30));
      expect(AppTheme.systemRedLight, const Color(0xFFFF3B30));
      expect(AppTheme.systemGreen, const Color(0xFF34C759));
      expect(AppTheme.systemGreenLight, const Color(0xFF34C759));
      expect(AppTheme.systemGray, const Color(0xFF8E8E93));

      expect(AppTheme.groupedBackground, const Color(0xFFF2F2F7));
      expect(AppTheme.groupedBackgroundLight, const Color(0xFFF2F2F7));
      expect(AppTheme.secondaryGroupedBackground, const Color(0xFFFFFFFF));
      expect(AppTheme.secondaryGroupedBackgroundLight, const Color(0xFFFFFFFF));
      expect(AppTheme.hairlineDivider, const Color(0xFFC6C6C8));
      expect(AppTheme.hairlineDividerLight, const Color(0xFFC6C6C8));

      expect(AppTheme.primaryLabelLight, const Color(0xFF000000));
      expect(AppTheme.secondaryLabelLight, const Color(0xFF8E8E93));
    });

    test('Dark mode system color tokens match Apple HIG specifications', () {
      expect(AppTheme.systemBlueDark, const Color(0xFF0A84FF));
      expect(AppTheme.systemRedDark, const Color(0xFFFF453A));
      expect(AppTheme.systemGreenDark, const Color(0xFF30D158));
      expect(AppTheme.systemGrayDark, const Color(0xFF8E8E93));

      expect(AppTheme.backgroundDark, const Color(0xFF000000));
      expect(AppTheme.groupedBackgroundDark, const Color(0xFF1C1C1E));
      expect(AppTheme.secondaryGroupedBackgroundDark, const Color(0xFF2C2C2E));
      expect(AppTheme.hairlineDividerDark, const Color(0xFF38383A));

      expect(AppTheme.primaryLabelDark, const Color(0xFFFFFFFF));
      expect(AppTheme.secondaryLabelDark, const Color(0xFF8E8E93));
    });

    test('Legacy tokens preserve backward compatibility with iOS mappings', () {
      expect(AppTheme.primary, AppTheme.systemBlueLight);
      expect(AppTheme.canvas, AppTheme.groupedBackgroundLight);
      expect(AppTheme.accent, AppTheme.systemRedLight);
      expect(AppTheme.lightSurface, AppTheme.secondaryGroupedBackgroundLight);
      expect(AppTheme.lightTextPrimary, AppTheme.primaryLabelLight);
      expect(AppTheme.lightTextSecondary, AppTheme.secondaryLabelLight);
      expect(AppTheme.lightOutline, AppTheme.hairlineDividerLight);

      expect(AppTheme.darkCanvas, AppTheme.backgroundDark);
      expect(AppTheme.darkSurface, AppTheme.groupedBackgroundDark);
      expect(AppTheme.darkSurfaceContainer,
          AppTheme.secondaryGroupedBackgroundDark);
      expect(AppTheme.darkPrimary, AppTheme.systemBlueDark);
      expect(AppTheme.darkAccent, AppTheme.systemRedDark);
      expect(AppTheme.darkTextPrimary, AppTheme.primaryLabelDark);
      expect(AppTheme.darkTextSecondary, AppTheme.secondaryLabelDark);
      expect(AppTheme.darkOutline, AppTheme.hairlineDividerDark);
    });
  });

  group('iOS Light Theme', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.iosLightTheme;
    });

    test('has correct brightness and scaffold background', () {
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF2F2F7));
    });

    test('card theme has 0 elevation and 12pt corner radius', () {
      expect(theme.cardTheme.elevation, 0.0);
      expect(theme.cardTheme.color, const Color(0xFFFFFFFF));
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });

    test('dialog theme has clean iOS styling with 14pt radius', () {
      expect(theme.dialogTheme.backgroundColor, const Color(0xFFFFFFFF));
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(14));
    });

    test('divider theme uses 0.5pt hairline separator', () {
      expect(theme.dividerTheme.color, const Color(0xFFC6C6C8));
      expect(theme.dividerTheme.thickness, 0.5);
    });

    test('typography has SF Pro letter spacing', () {
      expect(theme.appBarTheme.titleTextStyle?.letterSpacing, -0.4);
      expect(theme.textTheme.headlineLarge?.letterSpacing, -0.4);
      expect(theme.textTheme.titleLarge?.letterSpacing, -0.4);
      expect(theme.textTheme.bodyLarge?.letterSpacing, -0.4);
    });

    test('integrates CupertinoThemeData override', () {
      expect(theme.cupertinoOverrideTheme, isNotNull);
      expect(
          theme.cupertinoOverrideTheme?.primaryColor, const Color(0xFF007AFF));
      expect(theme.cupertinoOverrideTheme?.scaffoldBackgroundColor,
          const Color(0xFFF2F2F7));
    });

    test('legacy lightTheme getter routes to iosLightTheme', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          theme.scaffoldBackgroundColor);
      expect(
          AppTheme.lightTheme.colorScheme.primary, theme.colorScheme.primary);
    });
  });

  group('iOS Dark Theme', () {
    late ThemeData theme;

    setUp(() {
      theme = AppTheme.iosDarkTheme;
    });

    test('has correct brightness and scaffold background (true black)', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('card theme has 0 elevation and secondary grouped background', () {
      expect(theme.cardTheme.elevation, 0.0);
      expect(theme.cardTheme.color, const Color(0xFF2C2C2E));
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });

    test('dialog theme has dark secondary grouped surface with 14pt radius',
        () {
      expect(theme.dialogTheme.backgroundColor, const Color(0xFF2C2C2E));
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(14));
    });

    test('divider theme uses dark hairline separator', () {
      expect(theme.dividerTheme.color, const Color(0xFF38383A));
      expect(theme.dividerTheme.thickness, 0.5);
    });

    test('color scheme uses dark system blue and system red', () {
      expect(theme.colorScheme.primary, const Color(0xFF0A84FF));
      expect(theme.colorScheme.error, const Color(0xFFFF453A));
    });

    test('integrates CupertinoThemeData dark override', () {
      expect(theme.cupertinoOverrideTheme, isNotNull);
      expect(
          theme.cupertinoOverrideTheme?.primaryColor, const Color(0xFF0A84FF));
      expect(theme.cupertinoOverrideTheme?.scaffoldBackgroundColor,
          const Color(0xFF000000));
    });

    test('legacy darkTheme getter routes to iosDarkTheme', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          theme.scaffoldBackgroundColor);
      expect(AppTheme.darkTheme.colorScheme.primary, theme.colorScheme.primary);
    });
  });

  group('CupertinoThemeData Standalone', () {
    test('cupertinoLightTheme provides authentic iOS Cupertino properties', () {
      final cupertino = AppTheme.cupertinoLightTheme;
      expect(cupertino.primaryColor, const Color(0xFF007AFF));
      expect(cupertino.scaffoldBackgroundColor, const Color(0xFFF2F2F7));
    });

    test('cupertinoDarkTheme provides authentic iOS dark Cupertino properties',
        () {
      final cupertino = AppTheme.cupertinoDarkTheme;
      expect(cupertino.primaryColor, const Color(0xFF0A84FF));
      expect(cupertino.scaffoldBackgroundColor, const Color(0xFF000000));
    });
  });
}
