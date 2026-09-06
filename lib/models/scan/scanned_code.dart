import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';

/// One code found inside a picture.
///
/// [rawValue] is exactly what the decoder read, untouched. Everything else is
/// the app's reading of it. The two are kept apart on purpose: the sheet shows
/// the app's reading, but a copy always gives back the raw text, so nothing
/// the user pastes elsewhere was quietly rewritten here.
class ScannedCode {
  /// The payload exactly as decoded.
  final String rawValue;

  /// What the payload appears to be.
  final ScannedCodeKind kind;

  /// A short, readable form for the card title.
  ///
  /// For a `tel:` code this is the bare number; for Wi-Fi it is the network
  /// name. Never a secret: a Wi-Fi password is not put here.
  final String displayValue;

  /// The symbology the decoder named, such as `qrCode` or `ean13`.
  final String format;

  /// Wi-Fi details, when [kind] is [ScannedCodeKind.wifi].
  final WifiCredentials? wifi;

  const ScannedCode({
    required this.rawValue,
    required this.kind,
    required this.displayValue,
    this.format = '',
    this.wifi,
  });

  ScannedCode copyWith({
    String? rawValue,
    ScannedCodeKind? kind,
    String? displayValue,
    String? format,
    WifiCredentials? wifi,
  }) {
    return ScannedCode(
      rawValue: rawValue ?? this.rawValue,
      kind: kind ?? this.kind,
      displayValue: displayValue ?? this.displayValue,
      format: format ?? this.format,
      wifi: wifi ?? this.wifi,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ScannedCode &&
        other.rawValue == rawValue &&
        other.kind == kind &&
        other.displayValue == displayValue &&
        other.format == format &&
        other.wifi == wifi;
  }

  @override
  int get hashCode => Object.hash(rawValue, kind, displayValue, format, wifi);

  /// Names the kind and format only, never the payload.
  ///
  /// A code can hold a password or a private address, and this string is the
  /// one most likely to end up in a log by accident.
  @override
  String toString() => 'ScannedCode(${kind.name}, $format)';
}
