/// The picture formats the converter can write.
///
/// JPEG, PNG, and BMP are written in pure Dart by the `image` package. WEBP
/// has no Dart encoder, so it is written by Android through a platform
/// channel. Everything else about the two paths is the same.
enum ImageOutputFormat {
  jpeg,
  png,
  webp,
  bmp;

  /// File extension for this format, without the dot.
  String get extension {
    switch (this) {
      case ImageOutputFormat.jpeg:
        return 'jpg';
      case ImageOutputFormat.png:
        return 'png';
      case ImageOutputFormat.webp:
        return 'webp';
      case ImageOutputFormat.bmp:
        return 'bmp';
    }
  }

  /// MIME type recorded for a file of this format.
  String get mimeType {
    switch (this) {
      case ImageOutputFormat.jpeg:
        return 'image/jpeg';
      case ImageOutputFormat.png:
        return 'image/png';
      case ImageOutputFormat.webp:
        return 'image/webp';
      case ImageOutputFormat.bmp:
        return 'image/bmp';
    }
  }

  /// Whether a quality value changes the result.
  ///
  /// PNG and BMP are lossless, so their quality slider is hidden.
  bool get supportsQuality =>
      this == ImageOutputFormat.jpeg || this == ImageOutputFormat.webp;

  /// Whether see-through pixels survive the conversion.
  ///
  /// When they do not, the picture is flattened onto white first, so a
  /// transparent PNG does not turn into a black rectangle.
  bool get supportsTransparency =>
      this == ImageOutputFormat.png || this == ImageOutputFormat.webp;

  /// Whether Android has to do the encoding instead of Dart.
  bool get needsPlatformEncoder => this == ImageOutputFormat.webp;

  /// The label shown on the format chip.
  String get displayName {
    switch (this) {
      case ImageOutputFormat.jpeg:
        return 'JPEG';
      case ImageOutputFormat.png:
        return 'PNG';
      case ImageOutputFormat.webp:
        return 'WEBP';
      case ImageOutputFormat.bmp:
        return 'BMP';
    }
  }

  static ImageOutputFormat fromName(String value) {
    return ImageOutputFormat.values.firstWhere(
      (format) => format.name == value,
      orElse: () => ImageOutputFormat.jpeg,
    );
  }

  /// The format that matches the file called [fileName].
  ///
  /// Used to preselect the chip for the file the user opened, so the screen
  /// starts on the format they already have.
  static ImageOutputFormat forFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return ImageOutputFormat.png;
    if (lower.endsWith('.webp')) return ImageOutputFormat.webp;
    if (lower.endsWith('.bmp')) return ImageOutputFormat.bmp;
    return ImageOutputFormat.jpeg;
  }
}
