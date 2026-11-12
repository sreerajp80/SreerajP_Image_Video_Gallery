import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/phone_move_data.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_collector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';

// The UI reads this type from models, never from a service (G46).
export 'package:in_sreerajp_imgvidgal/models/sync/phone_move_data.dart';

/// Thrown when phone-move data cannot be built or read.
final class PhoneMoveDataException extends FeatureException {
  const PhoneMoveDataException(super.message, {super.cause});
}

/// Packs and unpacks the app data and settings of a phone move.
///
/// The app data is exactly what a backup file or a QR sync carries (tags,
/// albums, favourites, notes, places and each photo's fingerprint), so the
/// receiving phone matches it with the same restore rules. Settings ride
/// alongside in their own field, outside the backup format, so backup files
/// are not changed by this feature.
///
/// The bytes travel inside the already-encrypted transfer link. This class
/// only compresses them and refuses anything too large or malformed.
///
/// Never in the settings: the vault PIN and biometric setup (they live in
/// secure storage, not in `AppSettings`), Android permissions, this
/// install's id, and the "sent to that phone" marks. Those belong to one
/// phone.
class PhoneMoveDataService {
  final BackupCollectorService _collector;
  final BackupSerializer _serializer;

  PhoneMoveDataService({
    required BackupCollectorService collector,
    BackupSerializer serializer = const BackupSerializer(),
  }) : _collector = collector,
       _serializer = serializer;

  /// Format of the envelope. Changes only with the transfer protocol version.
  static const int formatVersion = 1;

  /// Builds the compressed bytes to send.
  Future<Uint8List> build({
    required String appVersion,
    required AppSettings settings,
    void Function(int done, int total)? onProgress,
  }) async {
    final payload = await _collector.collectFingerprinted(
      appVersion: appVersion,
      onProgress: onProgress,
    );
    return encode(backupJson: _serializer.encode(payload), settings: settings);
  }

  /// Packs already-encoded backup JSON and settings. Pure; used by tests.
  static Uint8List encode({required String backupJson, AppSettings? settings}) {
    final envelope = <String, dynamic>{
      'format': formatVersion,
      'backup': backupJson,
      if (settings != null) 'settings': settings.toJson(),
    };
    final packed = gzip.encode(utf8.encode(jsonEncode(envelope)));
    if (packed.length > AppConstants.syncMaxAppDataBytes) {
      throw const PhoneMoveDataException('The app data is too large to send');
    }
    return Uint8List.fromList(packed);
  }

  /// Reads bytes that arrived from the other phone.
  ///
  /// Untrusted input. Too large, not gzip, not JSON, the wrong format, or a
  /// backup that does not parse: each is refused with
  /// [PhoneMoveDataException]. Settings are read field by field, so a bad
  /// field falls back to its default rather than failing the rest.
  PhoneMoveData decode(List<int> bytes) {
    if (bytes.length > AppConstants.syncMaxAppDataBytes) {
      throw const PhoneMoveDataException('The app data is too large');
    }

    final Object? envelope;
    try {
      envelope = jsonDecode(utf8.decode(_inflate(bytes)));
    } on PhoneMoveDataException {
      rethrow;
    } catch (error) {
      throw PhoneMoveDataException(
        'The app data could not be read',
        cause: error,
      );
    }

    if (envelope is! Map<String, dynamic> ||
        envelope['format'] != formatVersion ||
        envelope['backup'] is! String) {
      throw const PhoneMoveDataException('The app data has an unknown shape');
    }

    try {
      final payload = _serializer.decode(envelope['backup'] as String);
      final rawSettings = envelope['settings'];
      return PhoneMoveData(
        payload: payload,
        settings: rawSettings is Map ? AppSettings.fromJson(rawSettings) : null,
      );
    } on BackupSerializerException catch (error) {
      throw PhoneMoveDataException('The app data did not parse', cause: error);
    }
  }

  /// Decompresses with a ceiling, so a small packet cannot unpack into a
  /// size that would run the phone out of memory.
  static List<int> _inflate(List<int> bytes) {
    final collector = _CappedCollector(
      AppConstants.syncMaxAppDataInflatedBytes,
    );
    try {
      final inflater = gzip.decoder.startChunkedConversion(collector);
      inflater.add(bytes);
      inflater.close();
    } on PhoneMoveDataException {
      rethrow;
    } catch (error) {
      throw PhoneMoveDataException(
        'The app data is not compressed data',
        cause: error,
      );
    }
    return collector.takeBytes();
  }
}

/// Collects decompressed bytes until [limit], then refuses.
class _CappedCollector implements Sink<List<int>> {
  final int limit;
  final BytesBuilder _out = BytesBuilder(copy: false);

  _CappedCollector(this.limit);

  @override
  void add(List<int> data) {
    if (_out.length + data.length > limit) {
      throw const PhoneMoveDataException('The app data unpacks too large');
    }
    _out.add(data);
  }

  @override
  void close() {}

  Uint8List takeBytes() => _out.takeBytes();
}
