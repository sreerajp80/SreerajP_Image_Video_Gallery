import 'package:flutter/foundation.dart';

/// How the user asked for the picture to be resized.
enum ResizeMode {
  /// Keep the original pixel size.
  none,

  /// Fit inside a chosen longest side, keeping the shape.
  longestSide,

  /// Use an exact width and height.
  exact,

  /// Scale by a percentage of the original.
  percent;

  static ResizeMode fromName(String value) {
    return ResizeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ResizeMode.none,
    );
  }
}

/// The resize the user asked for, before it is turned into real pixels.
///
/// This holds only what was typed or dragged. Working out the final size for
/// a given source picture is `ImageResizeService`'s job, so the maths can be
/// tested on its own.
@immutable
class ResizeSpec {
  final ResizeMode mode;

  /// Longest side in pixels, used by [ResizeMode.longestSide].
  final int longestSide;

  /// Width in pixels, used by [ResizeMode.exact].
  final int width;

  /// Height in pixels, used by [ResizeMode.exact].
  final int height;

  /// Scale percentage, used by [ResizeMode.percent]. 100 means no change.
  final int percent;

  /// Whether an exact resize keeps the original shape.
  ///
  /// When true, the picture is fitted inside the width and height instead of
  /// being stretched to fill them.
  final bool keepAspect;

  const ResizeSpec({
    this.mode = ResizeMode.none,
    this.longestSide = 1920,
    this.width = 1920,
    this.height = 1080,
    this.percent = 100,
    this.keepAspect = true,
  });

  /// Keep the picture exactly as it is.
  static const ResizeSpec original = ResizeSpec();

  /// Whether this spec would leave the picture untouched.
  bool get isIdentity =>
      mode == ResizeMode.none || (mode == ResizeMode.percent && percent == 100);

  ResizeSpec copyWith({
    ResizeMode? mode,
    int? longestSide,
    int? width,
    int? height,
    int? percent,
    bool? keepAspect,
  }) {
    return ResizeSpec(
      mode: mode ?? this.mode,
      longestSide: longestSide ?? this.longestSide,
      width: width ?? this.width,
      height: height ?? this.height,
      percent: percent ?? this.percent,
      keepAspect: keepAspect ?? this.keepAspect,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'mode': mode.name,
    'longestSide': longestSide,
    'width': width,
    'height': height,
    'percent': percent,
    'keepAspect': keepAspect,
  };

  factory ResizeSpec.fromMap(Map<String, dynamic> map) {
    return ResizeSpec(
      mode: ResizeMode.fromName(map['mode'] as String? ?? ''),
      longestSide: (map['longestSide'] as num?)?.toInt() ?? 1920,
      width: (map['width'] as num?)?.toInt() ?? 1920,
      height: (map['height'] as num?)?.toInt() ?? 1080,
      percent: (map['percent'] as num?)?.toInt() ?? 100,
      keepAspect: map['keepAspect'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResizeSpec &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          longestSide == other.longestSide &&
          width == other.width &&
          height == other.height &&
          percent == other.percent &&
          keepAspect == other.keepAspect;

  @override
  int get hashCode =>
      Object.hash(mode, longestSide, width, height, percent, keepAspect);

  @override
  String toString() =>
      'ResizeSpec(${mode.name}, longestSide: $longestSide, '
      '${width}x$height, percent: $percent, keepAspect: $keepAspect)';
}
