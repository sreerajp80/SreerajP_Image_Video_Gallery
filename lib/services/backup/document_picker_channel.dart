import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// What the picker said about a chosen file.
class PickedDocument {
  /// The content URI. Good for this one file, and not persisted.
  final String uri;

  /// The name the user sees, or an empty string if the provider gave none.
  final String name;

  /// Size in bytes, or -1 when the provider would not say.
  final int sizeBytes;

  const PickedDocument({
    required this.uri,
    this.name = '',
    this.sizeBytes = -1,
  });

  /// Whether the size is known.
  bool get hasSize => sizeBytes >= 0;
}

/// Thrown when the picker could not be shown.
///
/// Backing out of the picker is *not* this: choosing nothing is a normal
/// thing to do, and comes back as null rather than as an error.
class DocumentPickerException implements Exception {
  final String code;
  final String message;

  const DocumentPickerException(this.code, this.message);

  /// Whether the device has no document provider at all.
  bool get hasNoPicker => code == 'no_picker';

  @override
  String toString() => 'DocumentPickerException($code): $message';
}

/// Dart side of the Storage Access Framework picker.
///
/// Using the system picker is what lets the backup feature exist without a
/// storage permission: the user points at a place, and the app gets a URI for
/// that one document and nothing else. See the Kotlin handler for why the
/// read grant is deliberately not persisted.
class DocumentPickerChannel {
  final MethodChannel _channel;

  DocumentPickerChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.documentsChannelName);

  /// Asks the user where to save a new file.
  ///
  /// Returns the chosen URI, or null if they backed out.
  Future<String?> createDocument({
    required String fileName,
    String mimeType = AppConstants.backupMimeType,
  }) {
    return _invoke<String>('createDocument', <String, dynamic>{
      'fileName': fileName,
      'mimeType': mimeType,
    });
  }

  /// Asks the user to point at an existing file.
  ///
  /// Returns the chosen URI, or null if they backed out.
  Future<String?> openDocument({String mimeType = '*/*'}) {
    return _invoke<String>('openDocument', <String, dynamic>{
      'mimeType': mimeType,
    });
  }

  /// Reads a document's name and size without opening it.
  ///
  /// The restore screen uses this to refuse an absurdly large file before it
  /// asks for a password, so nobody types one for a file that was never going
  /// to be read.
  Future<PickedDocument?> documentInfo(String uri) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'documentInfo',
      <String, dynamic>{'uri': uri},
    );
    if (result == null) return null;

    return PickedDocument(
      uri: uri,
      name: result['name'] as String? ?? '',
      sizeBytes: (result['sizeBytes'] as num?)?.toInt() ?? -1,
    );
  }

  /// Reads the first [length] bytes of a document.
  ///
  /// The archive's header sits in the clear at the front of the file and must
  /// be parsed before anything can be decrypted, because it carries the salt
  /// and iteration count the password is stretched with. A content URI cannot
  /// be opened at an offset from Dart, so the prefix comes across the channel
  /// and the pure Dart format class parses it.
  ///
  /// Returns fewer bytes than asked for a shorter file, which is how a
  /// truncated archive is caught before a password is typed.
  Future<Uint8List> readPrefix(String uri, int length) async {
    final bytes = await _invoke<Uint8List>('readPrefix', <String, dynamic>{
      'uri': uri,
      'length': length,
    });
    return bytes ?? Uint8List(0);
  }

  /// Copies a chosen document into app-private cache and returns its path.
  ///
  /// The PDF image extractor needs the whole file as bytes, and a content URI
  /// cannot be opened as a `File` from Dart. The copy is the caller's to
  /// delete once it is finished with it.
  ///
  /// Throws [DocumentPickerException] with `too_large` when the file is bigger
  /// than [maxBytes], which is checked while copying rather than after.
  Future<String?> copyToCache(String uri, {int? maxBytes}) {
    return _invoke<String>('copyToCache', <String, dynamic>{
      'uri': uri,
      if (maxBytes != null) 'maxBytes': maxBytes,
    });
  }

  Future<T?> _invoke<T>(String method, Map<String, dynamic> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw DocumentPickerException(error.code, error.message ?? error.code);
    } on MissingPluginException {
      throw const DocumentPickerException(
        'no_picker',
        'The file picker is not available on this device',
      );
    }
  }
}
