import 'package:flutter/widgets.dart';
import 'package:in_sreerajp_imgvidgal/core/formatting/unit_format.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// Gives widgets a [UnitFormat] for the current language: `context.units`.
extension UnitFormatContext on BuildContext {
  /// Sizes, lengths and camera values formatted for the current language.
  UnitFormat get units =>
      UnitFormat(AppLocalizations.of(this)!, Localizations.localeOf(this));
}
