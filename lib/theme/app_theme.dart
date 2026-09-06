import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/theme/color_schemes.dart';

enum ThemePreference {
  system,
  light,
  dark,
  amoled;

  bool get isAmoled => this == ThemePreference.amoled;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return _buildTheme(AppColorSchemes.lightColorScheme);
  }

  static ThemeData get darkTheme {
    return _buildTheme(AppColorSchemes.darkColorScheme);
  }

  static ThemeData get amoledTheme {
    return _buildTheme(AppColorSchemes.amoledColorScheme, isAmoled: true);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    bool isAmoled = false,
  }) {
    final scaffoldBg = isAmoled ? Colors.black : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isAmoled
            ? const Color(0xFF101010)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isAmoled
              ? const BorderSide(color: Color(0xFF242424), width: 1)
              : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scaffoldBg,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isAmoled
            ? const Color(0xFF0D0D0D)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isAmoled
            ? const Color(0xFF0D0D0D)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: isAmoled ? const Color(0xFF222222) : colorScheme.outlineVariant,
        thickness: 0.8,
        space: 1,
      ),
    );
  }
}
