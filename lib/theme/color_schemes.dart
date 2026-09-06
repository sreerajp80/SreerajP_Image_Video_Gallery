import 'package:flutter/material.dart';

class AppColorSchemes {
  AppColorSchemes._();

  // Primary brand seed: Deep Cyan / Sapphire Blue
  static const Color primarySeed = Color(0xFF006688);

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006688),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC2E8FF),
    onPrimaryContainer: Color(0xFF001E2B),
    secondary: Color(0xFF4E616D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1E5F3),
    onSecondaryContainer: Color(0xFF0A1E28),
    tertiary: Color(0xFF605A7D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6DEFF),
    onTertiaryContainer: Color(0xFF1C1736),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFBFCFE),
    onSurface: Color(0xFF191C1E),
    surfaceContainerHighest: Color(0xFFDFE3E7),
    onSurfaceVariant: Color(0xFF41484D),
    outline: Color(0xFF71787E),
    outlineVariant: Color(0xFFC1C7CE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E3133),
    onInverseSurface: Color(0xFFF0F1F3),
    inversePrimary: Color(0xFF76D1FF),
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF76D1FF),
    onPrimary: Color(0xFF003548),
    primaryContainer: Color(0xFF004D67),
    onPrimaryContainer: Color(0xFFC2E8FF),
    secondary: Color(0xFFB5C9D7),
    onSecondary: Color(0xFF20333D),
    secondaryContainer: Color(0xFF364954),
    onSecondaryContainer: Color(0xFFD1E5F3),
    tertiary: Color(0xFFC9C1EA),
    onTertiary: Color(0xFF312C4C),
    tertiaryContainer: Color(0xFF484264),
    onTertiaryContainer: Color(0xFFE6DEFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF111416),
    onSurface: Color(0xFFE1E2E5),
    surfaceContainerHighest: Color(0xFF2B3135),
    onSurfaceVariant: Color(0xFFC1C7CE),
    outline: Color(0xFF8B9297),
    outlineVariant: Color(0xFF41484D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E2E5),
    onInverseSurface: Color(0xFF191C1E),
    inversePrimary: Color(0xFF006688),
  );

  // AMOLED True Black Color Scheme (#000000 pure black)
  static const ColorScheme amoledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF76D1FF),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF003548),
    onPrimaryContainer: Color(0xFFC2E8FF),
    secondary: Color(0xFFB5C9D7),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1D262C),
    onSecondaryContainer: Color(0xFFD1E5F3),
    tertiary: Color(0xFFC9C1EA),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF2D263E),
    onTertiaryContainer: Color(0xFFE6DEFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFF141414),
    onSurfaceVariant: Color(0xFFB0B5BA),
    outline: Color(0xFF6A7075),
    outlineVariant: Color(0xFF222426),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF006688),
  );
}
