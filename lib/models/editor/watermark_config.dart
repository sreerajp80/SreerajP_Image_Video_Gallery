import 'package:flutter/foundation.dart';

/// What the watermark shows.
enum WatermarkMode {
  /// No watermark.
  none,

  /// Free text the user typed.
  text,

  /// The photo's capture date and time.
  timestamp,

  /// A PNG logo the user picked from their device.
  logo;

  static WatermarkMode fromName(String value) {
    return WatermarkMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WatermarkMode.none,
    );
  }
}

/// Where on the photo the watermark sits.
enum WatermarkPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  static WatermarkPosition fromName(String value) {
    return WatermarkPosition.values.firstWhere(
      (position) => position.name == value,
      orElse: () => WatermarkPosition.bottomRight,
    );
  }
}

/// The watermark stamped onto a saved copy.
///
/// The logo is referenced by file path rather than by bytes, so a session
/// stays small and the image is only read when the render actually runs.
@immutable
class WatermarkConfig {
  final WatermarkMode mode;

  /// Text drawn for [WatermarkMode.text]. Ignored for the other modes.
  final String text;

  /// Date format pattern used for [WatermarkMode.timestamp].
  final String timestampPattern;

  /// Path of the PNG used for [WatermarkMode.logo], or null when unset.
  final String? logoPath;

  final WatermarkPosition position;

  /// How see-through the watermark is, 0 to 1.
  final double opacity;

  /// Size as a fraction of the image's shorter side.
  final double scale;

  /// Gap from the chosen edge, as a fraction of the image's shorter side.
  final double margin;

  /// Text or logo tint as a 32 bit ARGB value.
  final int colorArgb;

  const WatermarkConfig({
    this.mode = WatermarkMode.none,
    this.text = '',
    this.timestampPattern = 'yyyy-MM-dd HH:mm',
    this.logoPath,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.7,
    this.scale = 0.06,
    this.margin = 0.03,
    this.colorArgb = 0xFFFFFFFF,
  });

  /// No watermark at all.
  static const WatermarkConfig none = WatermarkConfig();

  /// Whether this configuration would actually draw something.
  ///
  /// A text mode with no text and a logo mode with no file both count as
  /// nothing to draw, so the renderer can skip the stage.
  bool get isNone {
    switch (mode) {
      case WatermarkMode.none:
        return true;
      case WatermarkMode.text:
        return text.trim().isEmpty || opacity <= 0;
      case WatermarkMode.timestamp:
        return opacity <= 0;
      case WatermarkMode.logo:
        return (logoPath == null || logoPath!.isEmpty) || opacity <= 0;
    }
  }

  WatermarkConfig copyWith({
    WatermarkMode? mode,
    String? text,
    String? timestampPattern,
    String? logoPath,
    bool clearLogoPath = false,
    WatermarkPosition? position,
    double? opacity,
    double? scale,
    double? margin,
    int? colorArgb,
  }) {
    return WatermarkConfig(
      mode: mode ?? this.mode,
      text: text ?? this.text,
      timestampPattern: timestampPattern ?? this.timestampPattern,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      margin: margin ?? this.margin,
      colorArgb: colorArgb ?? this.colorArgb,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'mode': mode.name,
    'text': text,
    'timestampPattern': timestampPattern,
    'logoPath': logoPath,
    'position': position.name,
    'opacity': opacity,
    'scale': scale,
    'margin': margin,
    'colorArgb': colorArgb,
  };

  factory WatermarkConfig.fromMap(Map<String, dynamic> map) {
    return WatermarkConfig(
      mode: WatermarkMode.fromName(map['mode'] as String? ?? ''),
      text: map['text'] as String? ?? '',
      timestampPattern:
          map['timestampPattern'] as String? ?? 'yyyy-MM-dd HH:mm',
      logoPath: map['logoPath'] as String?,
      position: WatermarkPosition.fromName(map['position'] as String? ?? ''),
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.7,
      scale: (map['scale'] as num?)?.toDouble() ?? 0.06,
      margin: (map['margin'] as num?)?.toDouble() ?? 0.03,
      colorArgb: (map['colorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatermarkConfig &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          text == other.text &&
          timestampPattern == other.timestampPattern &&
          logoPath == other.logoPath &&
          position == other.position &&
          opacity == other.opacity &&
          scale == other.scale &&
          margin == other.margin &&
          colorArgb == other.colorArgb;

  @override
  int get hashCode => Object.hash(
    mode,
    text,
    timestampPattern,
    logoPath,
    position,
    opacity,
    scale,
    margin,
    colorArgb,
  );

  // The watermark text can be personal, so it is left out of the description.
  @override
  String toString() =>
      'WatermarkConfig(${mode.name}, ${position.name}, opacity: $opacity)';
}
