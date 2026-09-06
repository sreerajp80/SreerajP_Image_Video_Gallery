import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';

/// One whole conversion, as the user set it up on the screen.
///
/// The object is plain data so it can be turned into JSON and handed to a
/// background isolate, the same way an edit session is.
@immutable
class ConversionRequest {
  final ImageOutputFormat format;

  /// Quality for a lossy format, 10 to 100. Ignored by PNG and BMP.
  final int quality;

  final ResizeSpec resize;

  /// Whether camera metadata is dropped from the copy.
  ///
  /// Re-encoding through the `image` package already leaves EXIF behind, so
  /// this flag only records what the user chose and is what the screen shows
  /// them. It defaults to on, because a shared copy carrying a home GPS
  /// position is a privacy problem.
  final bool stripMetadata;

  const ConversionRequest({
    this.format = ImageOutputFormat.jpeg,
    this.quality = AppConstants.convertDefaultQuality,
    this.resize = ResizeSpec.original,
    this.stripMetadata = true,
  });

  /// The quality actually used, pulled into the allowed range.
  int get effectiveQuality => quality.clamp(
    AppConstants.convertMinQuality,
    AppConstants.convertMaxQuality,
  );

  ConversionRequest copyWith({
    ImageOutputFormat? format,
    int? quality,
    ResizeSpec? resize,
    bool? stripMetadata,
  }) {
    return ConversionRequest(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      resize: resize ?? this.resize,
      stripMetadata: stripMetadata ?? this.stripMetadata,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'format': format.name,
    'quality': quality,
    'resize': resize.toMap(),
    'stripMetadata': stripMetadata,
  };

  factory ConversionRequest.fromMap(Map<String, dynamic> map) {
    final resize = map['resize'];
    return ConversionRequest(
      format: ImageOutputFormat.fromName(map['format'] as String? ?? ''),
      quality:
          (map['quality'] as num?)?.toInt() ??
          AppConstants.convertDefaultQuality,
      resize: resize is Map
          ? ResizeSpec.fromMap(Map<String, dynamic>.from(resize))
          : ResizeSpec.original,
      stripMetadata: map['stripMetadata'] as bool? ?? true,
    );
  }

  /// The request as a JSON string, for crossing an isolate boundary.
  String toJson() => jsonEncode(toMap());

  factory ConversionRequest.fromJson(String source) =>
      ConversionRequest.fromMap(
        Map<String, dynamic>.from(jsonDecode(source) as Map),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversionRequest &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          quality == other.quality &&
          resize == other.resize &&
          stripMetadata == other.stripMetadata;

  @override
  int get hashCode => Object.hash(format, quality, resize, stripMetadata);

  @override
  String toString() =>
      'ConversionRequest(${format.name}, quality: $quality, $resize)';
}
