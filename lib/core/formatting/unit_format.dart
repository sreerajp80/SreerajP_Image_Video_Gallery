import 'dart:ui' show Locale;

import 'package:in_sreerajp_imgvidgal/core/l10n/formatting_locale.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Formats sizes, lengths and camera values for the current language.
///
/// The number goes through `intl` with [formattingLocale], and the unit comes
/// from the ARB files, so no widget builds `'... MB'` itself (engineering
/// standard §8.2). Build one per `build`:
///
/// ```dart
/// final units = UnitFormat(l10n, Localizations.localeOf(context));
/// Text(units.bytes(item.size));
/// ```
class UnitFormat {
  final AppLocalizations _l10n;
  final String _locale;

  UnitFormat(this._l10n, Locale locale) : _locale = formattingLocale(locale);

  /// A byte count such as `245 KB` or `1.4 MB`.
  ///
  /// One decimal place below 10 keeps "1.4 MB" readable, while "245 KB" stays
  /// free of a pointless ".0". A negative count shows as `0 B`.
  String bytes(int count) {
    if (count < 1024) return _l10n.bodyUnitBytes(_whole(count < 0 ? 0 : count));

    final units = <String Function(String)>[
      _l10n.bodyUnitKilobytes,
      _l10n.bodyUnitMegabytes,
      _l10n.bodyUnitGigabytes,
      _l10n.bodyUnitTerabytes,
    ];
    var value = count / 1024;
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final text = value >= 10 ? _whole(value.round()) : _decimal(value, 1);
    return units[index](text);
  }

  /// A length in millimetres, such as a lens focal length.
  String millimetres(double value, {int decimals = 0}) =>
      _l10n.bodyUnitMillimetres(_decimal(value, decimals));

  /// A distance in metres.
  String metres(double value, {int decimals = 1}) =>
      _l10n.bodyUnitMetres(_decimal(value, decimals));

  /// A camera ISO value, such as `ISO 400`.
  String iso(int value) => _l10n.bodyUnitIsoValue(_whole(value));

  /// A crop factor, such as `1.53x`.
  String cropFactor(double value) =>
      _l10n.bodyUnitCropFactor(_decimal(value, 2));

  String _whole(int value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  String _decimal(double value, int decimals) {
    final format = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return format.format(value);
  }
}
