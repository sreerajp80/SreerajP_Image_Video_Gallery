import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme has brightness light and non-black scaffold', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, isNot(Colors.black));
    });

    test('dark theme has brightness dark', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });

    test('amoled theme has brightness dark and pure black scaffold', () {
      final theme = AppTheme.amoledTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, Colors.black);
    });
  });
}
