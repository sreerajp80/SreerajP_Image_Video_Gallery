import 'package:flutter/foundation.dart';

/// The 8 colour ranges the HSL tuner exposes.
///
/// Each range covers a band of hues. The bands overlap slightly so colours
/// near a boundary transition smoothly instead of snapping.
enum HslColorRange {
  red,
  orange,
  yellow,
  green,
  cyan,
  blue,
  purple,
  magenta;

  /// Tries to parse a range name, falling back to [red].
  static HslColorRange fromName(String value) {
    return HslColorRange.values.firstWhere(
      (range) => range.name == value,
      orElse: () => HslColorRange.red,
    );
  }
}

/// One colour range's hue, saturation, and luminance shifts.
///
/// All three run from -1 to 1 with 0 meaning "leave it alone". Hue maps
/// to ±30° in the service; saturation and luminance are proportional.
@immutable
class HslChannelAdjustment {
  /// Hue shift, -1 (−30°) to 1 (+30°).
  final double hue;

  /// Saturation change, -1 (desaturate) to 1 (saturate).
  final double saturation;

  /// Luminance change, -1 (darken) to 1 (brighten).
  final double luminance;

  const HslChannelAdjustment({
    this.hue = 0,
    this.saturation = 0,
    this.luminance = 0,
  });

  static const HslChannelAdjustment neutral = HslChannelAdjustment();

  bool get isNeutral => hue == 0 && saturation == 0 && luminance == 0;

  HslChannelAdjustment copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return HslChannelAdjustment(
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'hue': hue,
    'saturation': saturation,
    'luminance': luminance,
  };

  factory HslChannelAdjustment.fromMap(Map<String, dynamic> map) {
    return HslChannelAdjustment(
      hue: (map['hue'] as num?)?.toDouble() ?? 0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 0,
      luminance: (map['luminance'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HslChannelAdjustment &&
          runtimeType == other.runtimeType &&
          hue == other.hue &&
          saturation == other.saturation &&
          luminance == other.luminance;

  @override
  int get hashCode => Object.hash(hue, saturation, luminance);

  @override
  String toString() =>
      'HslChannelAdjustment(hue: $hue, sat: $saturation, lum: $luminance)';
}

/// All eight colour-range adjustments, as one immutable value.
///
/// Ranges that were never touched are absent from the map, which makes
/// [isNeutral] a cheap check and keeps serialised sessions small.
@immutable
class HslAdjustments {
  /// Only ranges the user actually moved appear here.
  final Map<HslColorRange, HslChannelAdjustment> channels;

  const HslAdjustments({
    this.channels = const <HslColorRange, HslChannelAdjustment>{},
  });

  static const HslAdjustments neutral = HslAdjustments();

  /// Whether every range is still at its default.
  bool get isNeutral {
    if (channels.isEmpty) return true;
    return channels.values.every((adj) => adj.isNeutral);
  }

  /// Returns the adjustment for [range], or neutral if the user never
  /// touched it.
  HslChannelAdjustment adjustmentFor(HslColorRange range) {
    return channels[range] ?? HslChannelAdjustment.neutral;
  }

  /// Returns a copy with one range replaced.
  HslAdjustments copyWithChannel(
    HslColorRange range,
    HslChannelAdjustment adjustment,
  ) {
    final next = Map<HslColorRange, HslChannelAdjustment>.from(channels);
    if (adjustment.isNeutral) {
      next.remove(range);
    } else {
      next[range] = adjustment;
    }
    return HslAdjustments(channels: next);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    for (final entry in channels.entries) {
      if (!entry.value.isNeutral) {
        map[entry.key.name] = entry.value.toMap();
      }
    }
    return map;
  }

  factory HslAdjustments.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return HslAdjustments.neutral;

    final channels = <HslColorRange, HslChannelAdjustment>{};
    for (final range in HslColorRange.values) {
      final raw = map[range.name];
      if (raw is Map) {
        final adj = HslChannelAdjustment.fromMap(
          Map<String, dynamic>.from(raw),
        );
        if (!adj.isNeutral) {
          channels[range] = adj;
        }
      }
    }
    return HslAdjustments(channels: channels);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HslAdjustments &&
          runtimeType == other.runtimeType &&
          mapEquals(channels, other.channels);

  @override
  int get hashCode => Object.hashAll(
    HslColorRange.values.map(
      (r) => channels[r] ?? HslChannelAdjustment.neutral,
    ),
  );

  @override
  String toString() => 'HslAdjustments(${channels.length} ranges changed)';
}
