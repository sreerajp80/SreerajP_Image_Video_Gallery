import 'package:flutter/foundation.dart';

/// Where a converted copy landed and how big it turned out.
@immutable
class ConversionResult {
  /// Full path of the new file.
  final String path;

  /// Size of the new file in bytes.
  final int bytes;

  /// Pixel width of the new file.
  final int width;

  /// Pixel height of the new file.
  final int height;

  /// Size of the original file in bytes.
  final int originalBytes;

  const ConversionResult({
    required this.path,
    required this.bytes,
    required this.width,
    required this.height,
    required this.originalBytes,
  });

  /// Bytes saved against the original. Negative when the copy is bigger.
  int get savedBytes => originalBytes - bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversionResult &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          bytes == other.bytes &&
          width == other.width &&
          height == other.height &&
          originalBytes == other.originalBytes;

  @override
  int get hashCode => Object.hash(path, bytes, width, height, originalBytes);

  @override
  String toString() => 'ConversionResult($bytes bytes, ${width}x$height)';
}
