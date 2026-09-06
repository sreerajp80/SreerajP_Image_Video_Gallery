import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Resolves a [MediaType] from a MIME type and/or filename.
///
/// This is deliberately a pure, dependency-free helper so it can be used from a
/// background isolate and covered by plain unit tests. It never throws: unknown
/// input falls back to [MediaType.image].
class MediaTypeResolver {
  const MediaTypeResolver._();

  /// File extensions treated as camera RAW images.
  static const Set<String> rawExtensions = <String>{
    'dng',
    'cr2',
    'cr3',
    'nef',
    'nrw',
    'arw',
    'srf',
    'sr2',
    'orf',
    'rw2',
    'raf',
    'pef',
    'raw',
  };

  /// MIME types reported by MediaStore for RAW images.
  static const Set<String> _rawMimeTypes = <String>{
    'image/x-adobe-dng',
    'image/x-canon-cr2',
    'image/x-canon-cr3',
    'image/x-nikon-nef',
    'image/x-nikon-nrw',
    'image/x-sony-arw',
    'image/x-olympus-orf',
    'image/x-panasonic-rw2',
    'image/x-fuji-raf',
    'image/x-pentax-pef',
  };

  /// Returns the media category for the given [mimeType] and [fileName].
  ///
  /// Either argument may be null or empty. The MIME type wins when it is
  /// specific enough; otherwise the file extension decides.
  static MediaType resolve({String? mimeType, String? fileName}) {
    final mime = (mimeType ?? '').trim().toLowerCase();
    final extension = extensionOf(fileName);

    if (mime == 'image/gif' || extension == 'gif') {
      return MediaType.gif;
    }
    if (mime == 'image/svg+xml' || extension == 'svg') {
      return MediaType.svg;
    }
    if (_rawMimeTypes.contains(mime) || rawExtensions.contains(extension)) {
      return MediaType.rawImage;
    }
    if (mime.startsWith('video/') || _videoExtensions.contains(extension)) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  /// Lowercase extension without the dot, or an empty string when absent.
  static String extensionOf(String? fileName) {
    final name = (fileName ?? '').trim();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  static const Set<String> _videoExtensions = <String>{
    'mp4',
    'm4v',
    'mkv',
    'webm',
    'avi',
    'mov',
    '3gp',
    '3g2',
    'mpg',
    'mpeg',
    'ts',
    'flv',
    'wmv',
  };
}
