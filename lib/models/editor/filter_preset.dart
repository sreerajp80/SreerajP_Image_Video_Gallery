import 'package:flutter/foundation.dart';

/// The one-tap looks offered on the filters strip.
///
/// Each one is only a name here. `FilterPresetService` holds what it actually
/// does, so the model stays free of maths and the look can be retuned without
/// touching stored sessions.
enum FilterPresetId {
  none,
  mono,
  sepia,
  vintage,
  vivid,
  cool,
  warm,
  fade;

  /// Reads a preset name back, falling back to [none] on anything unknown.
  static FilterPresetId fromName(String value) {
    return FilterPresetId.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => FilterPresetId.none,
    );
  }
}

/// A preset plus how strongly the user wants it applied.
///
/// [intensity] runs from 0 (original photo) to 1 (the full look), so the same
/// preset can be dialled back rather than being all or nothing.
@immutable
class FilterPreset {
  final FilterPresetId id;
  final double intensity;

  const FilterPreset({this.id = FilterPresetId.none, this.intensity = 1});

  /// No filter at all.
  static const FilterPreset none = FilterPreset();

  /// Whether this preset would change the image.
  bool get isNone => id == FilterPresetId.none || intensity <= 0;

  FilterPreset copyWith({FilterPresetId? id, double? intensity}) {
    return FilterPreset(
      id: id ?? this.id,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id.name,
    'intensity': intensity,
  };

  factory FilterPreset.fromMap(Map<String, dynamic> map) {
    return FilterPreset(
      id: FilterPresetId.fromName(map['id'] as String? ?? ''),
      intensity: (map['intensity'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          intensity == other.intensity;

  @override
  int get hashCode => Object.hash(id, intensity);

  @override
  String toString() => 'FilterPreset(${id.name}, intensity: $intensity)';
}
