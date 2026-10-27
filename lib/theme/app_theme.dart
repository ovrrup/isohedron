import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Isohedron iOS Minimal Design System & Theme.
///
/// Implements authentic Apple Human Interface Guidelines (HIG) design tokens,
/// SF Pro typography styles, grouped inset surfaces, hairline separators,
/// and CupertinoThemeData integration.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Apple iOS System Colors (Light & Dark)
  // ---------------------------------------------------------------------------

  // System Blue
  static const Color systemBlueLight = Color(0xFF007AFF);
  static const Color systemBlueDark = Color(0xFF0A84FF);
  static const Color systemBlue = systemBlueLight;

  // System Red
  static const Color systemRedLight = Color(0xFFFF3B30);
  static const Color systemRedDark = Color(0xFFFF453A);
  static const Color systemRed = systemRedLight;

  // System Green
  static const Color systemGreenLight = Color(0xFF34C759);
  static const Color systemGreenDark = Color(0xFF30D158);
  static const Color systemGreen = systemGreenLight;

  // System Orange
  static const Color systemOrangeLight = Color(0xFFFF9500);
  static const Color systemOrangeDark = Color(0xFFFF9F0A);
  static const Color systemOrange = systemOrangeLight;

  // System Yellow
  static const Color systemYellowLight = Color(0xFFFFCC00);
  static const Color systemYellowDark = Color(0xFFFFD60A);
  static const Color systemYellow = systemYellowLight;

  // System Gray Scale
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGrayDark = Color(0xFF8E8E93);
  static const Color systemGray2Light = Color(0xFFAEAEB2);
  static const Color systemGray2Dark = Color(0xFF636366);
  static const Color systemGray3Light = Color(0xFFC7C7CC);
  static const Color systemGray3Dark = Color(0xFF48484A);
  static const Color systemGray4Light = Color(0xFFD1D1D6);
  static const Color systemGray4Dark = Color(0xFF3A3A3C);
  static const Color systemGray5Light = Color(0xFFE5E5EA);
  static const Color systemGray5Dark = Color(0xFF2C2C2E);
  static const Color systemGray6Light = Color(0xFFF2F2F7);
  static const Color systemGray6Dark = Color(0xFF1C1C1E);

  // ---------------------------------------------------------------------------
  // iOS Grouped & Background Surfaces
  // ---------------------------------------------------------------------------

  // Light Surfaces
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color groupedBackgroundLight = Color(0xFFF2F2F7);
  static const Color secondaryGroupedBackgroundLight = Color(0xFFFFFFFF);
  static const Color tertiaryGroupedBackgroundLight = Color(0xFFF2F2F7);

  // Dark Surfaces (OLED True Black Background + Grouped Grays)
  static const Color backgroundDark = Color(0xFF000000);
  static const Color groupedBackgroundDark = Color(0xFF1C1C1E);
  static const Color secondaryGroupedBackgroundDark = Color(0xFF2C2C2E);
  static const Color tertiaryGroupedBackgroundDark = Color(0xFF3A3A3C);

  // Common Aliases
  static const Color groupedBackground = groupedBackgroundLight;
  static const Color secondaryGroupedBackground =
      secondaryGroupedBackgroundLight;
  static const Color lightSystemGroupedBackground = groupedBackgroundLight;
  static const Color darkSystemGroupedBackground = groupedBackgroundDark;
  static const Color lightSecondaryGroupedBackground =
      secondaryGroupedBackgroundLight;
  static const Color darkSecondaryGroupedBackground =
      secondaryGroupedBackgroundDark;
  static const Color darkTertiaryGroupedBackground =
      tertiaryGroupedBackgroundDark;

  // ---------------------------------------------------------------------------
  // Hairline Dividers & Separators
  // ---------------------------------------------------------------------------
  static const Color hairlineDividerLight = Color(0xFFC6C6C8);
  static const Color hairlineDividerDark = Color(0xFF38383A);
  static const Color hairlineDivider = hairlineDividerLight;
  static const Color lightSeparator = hairlineDividerLight;
  static const Color darkSeparator = hairlineDividerDark;

  // ---------------------------------------------------------------------------
  // iOS Typography Labels
  // ---------------------------------------------------------------------------
  static const Color primaryLabelLight = Color(0xFF000000);
  static const Color secondaryLabelLight = Color(0xFF8E8E93);
  static const Color tertiaryLabelLight = Color(0x7C3C3C43);
  static const Color quaternaryLabelLight = Color(0x2E3C3C43);

  static const Color primaryLabelDark = Color(0xFFFFFFFF);
  static const Color secondaryLabelDark = Color(0xFF8E8E93);
  static const Color tertiaryLabelDark = Color(0x7CEBEBF5);
  static const Color quaternaryLabelDark = Color(0x2EEBEBF5);

  static const Color lightLabelPrimary = primaryLabelLight;
  static const Color darkLabelPrimary = primaryLabelDark;
  static const Color lightLabelSecondary = secondaryLabelLight;
  static const Color darkLabelSecondary = secondaryLabelDark;

  // Accent Dark Aliases
  static const Color darkSystemBlue = systemBlueDark;
  static const Color darkSystemGreen = systemGreenDark;
  static const Color darkSystemOrange = systemOrangeDark;
  static const Color darkSystemRed = systemRedDark;

  // ---------------------------------------------------------------------------
  // Backward Compatibility Tokens
  // ---------------------------------------------------------------------------
  static const Color primary = systemBlueLight;
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryLight = systemBlueDark;
  static const Color canvas = groupedBackgroundLight;
  static const Color accent = systemRedLight;
  static const Color accentLight = Color(0xFFFFECEB);

  static const Color lightSurface = secondaryGroupedBackgroundLight;
  static const Color lightSurfaceContainer = systemGray5Light;
  static const Color lightTextPrimary = primaryLabelLight;
  static const Color lightTextSecondary = secondaryLabelLight;
  static const Color lightOutline = hairlineDividerLight;

  static const Color darkCanvas = backgroundDark;
  static const Color darkSurface = groupedBackgroundDark;
  static const Color darkSurfaceContainer = secondaryGroupedBackgroundDark;
  static const Color darkPrimary = systemBlueDark;
  static const Color darkAccent = systemRedDark;
  static const Color darkTextPrimary = primaryLabelDark;
  static const Color darkTextSecondary = secondaryLabelDark;
  static const Color darkOutline = hairlineDividerDark;

  // ---------------------------------------------------------------------------
  // iOS Light Theme
  // ---------------------------------------------------------------------------
  static ThemeData get iosLightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: systemBlueLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4F7),
      onPrimaryContainer: Color(0xFF0056B3),
      secondary: systemBlueLight,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE5E5EA),
      onSecondaryContainer: Color(0xFF1C1C1E),
      tertiary: systemRedLight,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFECEB),
      onTertiaryContainer: Color(0xFF5E0B12),
      error: systemRedLight,
      onError: Colors.white,
      surface: secondaryGroupedBackgroundLight,
      onSurface: primaryLabelLight,
      surfaceContainerHighest: systemGray5Light,
      outline: hairlineDividerLight,
      outlineVariant: Color(0xFFE5E5EA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: groupedBackgroundLight,
      cupertinoOverrideTheme: cupertinoLightTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: groupedBackgroundLight,
        foregroundColor: primaryLabelLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryLabelLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: secondaryGroupedBackgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: secondaryGroupedBackgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineDividerLight,
        thickness: 0.5,
        space: 1.0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: systemGray5Light,
        selectedColor: systemBlueLight,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondaryLabelLight,
          letterSpacing: -0.2,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: systemBlueLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: systemBlueLight,
          side: const BorderSide(color: systemBlueLight, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: systemBlueLight,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryGroupedBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDividerLight, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDividerLight, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: systemBlueLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primaryLabelLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primaryLabelLight,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: primaryLabelLight,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: primaryLabelLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          color: primaryLabelLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: primaryLabelLight,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: secondaryLabelLight,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: secondaryLabelLight,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // iOS Dark Theme (Pure OLED Black Background + Dark Grouped Cards)
  // ---------------------------------------------------------------------------
  static ThemeData get iosDarkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: systemBlueDark,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF173F68),
      onPrimaryContainer: Color(0xFFCEE3FA),
      secondary: systemBlueDark,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF2C2C2E),
      onSecondaryContainer: primaryLabelDark,
      tertiary: systemRedDark,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF4A181A),
      onTertiaryContainer: Color(0xFFFFDAD8),
      error: systemRedDark,
      onError: Colors.white,
      surface: secondaryGroupedBackgroundDark,
      onSurface: primaryLabelDark,
      surfaceContainerHighest: systemGray4Dark,
      outline: hairlineDividerDark,
      outlineVariant: Color(0xFF253344),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      cupertinoOverrideTheme: cupertinoDarkTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: primaryLabelDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryLabelDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: secondaryGroupedBackgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: secondaryGroupedBackgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineDividerDark,
        thickness: 0.5,
        space: 1.0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryGroupedBackgroundDark,
        selectedColor: systemBlueDark,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondaryLabelDark,
          letterSpacing: -0.2,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: systemBlueDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: systemBlueDark,
          side: const BorderSide(color: systemBlueDark, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: systemBlueDark,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryGroupedBackgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDividerDark, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDividerDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: systemBlueDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primaryLabelDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primaryLabelDark,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: primaryLabelDark,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: primaryLabelDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          color: primaryLabelDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: primaryLabelDark,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: secondaryLabelDark,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: secondaryLabelDark,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CupertinoThemeData Standalone
  // ---------------------------------------------------------------------------
  static CupertinoThemeData get cupertinoLightTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: systemBlueLight,
      primaryContrastingColor: Colors.white,
      barBackgroundColor: groupedBackgroundLight.withValues(alpha: 0.9),
      scaffoldBackgroundColor: groupedBackgroundLight,
      textTheme: const CupertinoTextThemeData(
        primaryColor: primaryLabelLight,
        textStyle: TextStyle(
          color: primaryLabelLight,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        navTitleTextStyle: TextStyle(
          color: primaryLabelLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: primaryLabelLight,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertinoDarkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: systemBlueDark,
      primaryContrastingColor: Colors.white,
      barBackgroundColor: backgroundDark.withValues(alpha: 0.9),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: const CupertinoTextThemeData(
        primaryColor: primaryLabelDark,
        textStyle: TextStyle(
          color: primaryLabelDark,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        navTitleTextStyle: TextStyle(
          color: primaryLabelDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: primaryLabelDark,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy Theme Getters (routing to iOS themes)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme => iosLightTheme;
  static ThemeData get darkTheme => iosDarkTheme;
}
