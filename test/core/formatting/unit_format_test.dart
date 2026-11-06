import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/formatting/unit_format.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // The app's localization delegates load this data; a plain unit test must.
  setUpAll(initializeDateFormatting);

  Future<UnitFormat> unitsFor(String code) async {
    final locale = Locale(code);
    final l10n = await AppLocalizations.delegate.load(locale);
    return UnitFormat(l10n, locale);
  }

  group('bytes', () {
    late UnitFormat units;
    setUp(() async => units = await unitsFor('en'));

    test('small sizes stay in bytes', () {
      expect(units.bytes(0), '0 B');
      expect(units.bytes(512), '512 B');
    });

    test('a kilobyte range gets one decimal place', () {
      expect(units.bytes(1536), '1.5 KB');
    });

    test('above ten the decimal place is dropped', () {
      expect(units.bytes(1024 * 250), '250 KB');
    });

    test('megabytes and gigabytes are used when they fit', () {
      expect(units.bytes(1024 * 1024 * 3), '3.0 MB');
      expect(units.bytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('a negative size never leaks out as a negative label', () {
      expect(units.bytes(-5), '0 B');
    });

    test('large numbers use the locale grouping', () {
      expect(units.bytes(1024 * 1024 * 1024 * 1024 * 1500), '1,500 TB');
    });
  });

  test('camera values', () async {
    final units = await unitsFor('en');
    expect(units.millimetres(35), '35 mm');
    expect(units.millimetres(4.25, decimals: 1), '4.3 mm');
    expect(units.metres(2.5), '2.5 m');
    expect(units.iso(1600), 'ISO 1,600');
    expect(units.cropFactor(1.5), '1.50x');
  });

  for (final code in <String>['ml', 'sa']) {
    test('formats in $code without throwing', () async {
      final units = await unitsFor(code);
      expect(units.bytes(1024 * 1024 * 3), '3.0 MB');
      expect(units.millimetres(35), '35 mm');
    });
  }

  test('shutter count uses plural forms', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.bodyForensicShutterCount(1), '1 release');
    expect(en.bodyForensicShutterCount(5200), '5200 releases');
  });
}
