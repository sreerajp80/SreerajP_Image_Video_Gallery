import 'package:flutter/foundation.dart';

/// What a trial encode would produce, without writing anything to disk.
///
/// This is what the size preview shows while the user drags the quality and
/// size sliders. The numbers come from a real encode, so they are exact
/// rather than guessed.
@immutable
class SizeEstimate {
  /// Size of the encoded result in bytes.
  final int bytes;

  /// Pixel width of the result.
  final int width;

  /// Pixel height of the result.
  final int height;

  /// Size of the original file in bytes, for comparison.
  final int originalBytes;

  const SizeEstimate({
    required this.bytes,
    required this.width,
    required this.height,
    required this.originalBytes,
  });

  /// Bytes saved against the original. Negative when the copy is bigger.
  int get savedBytes => originalBytes - bytes;

  /// Share of the original size that is saved, 0 to 1.
  ///
  /// Returns 0 when the original size is unknown or the copy grew, so the
  /// screen never shows a negative saving.
  double get savedFraction {
    if (originalBytes <= 0 || savedBytes <= 0) return 0;
    return savedBytes / originalBytes;
  }

  /// Whether the copy came out larger than the original.
  ///
  /// Worth telling the user about: converting a small JPEG to PNG usually
  /// makes the file bigger, not smaller.
  bool get isLarger => originalBytes > 0 && bytes > originalBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SizeEstimate &&
          runtimeType == other.runtimeType &&
          bytes == other.bytes &&
          width == other.width &&
          height == other.height &&
          originalBytes == other.originalBytes;

  @override
  int get hashCode => Object.hash(bytes, width, height, originalBytes);

  @override
  String toString() =>
      'SizeEstimate($bytes bytes, ${width}x$height, was $originalBytes)';
}
