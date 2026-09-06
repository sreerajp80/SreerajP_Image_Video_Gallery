import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_collector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_crypto_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_format.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// How far a backup has got.
enum BackupStage {
  /// Reading the database.
  collecting,

  /// Turning it into JSON and compressing it.
  packing,

  /// Waiting for the user to choose where it goes.
  choosingDestination,

  /// Encrypting into the chosen file.
  encrypting,

  /// Finished.
  done,
}

/// What a finished backup produced.
class BackupResult {
  /// Where it was written, or null if the user backed out of the picker.
  final String? destinationUri;

  /// Bytes of ciphertext written.
  final int bytesWritten;

  /// What went into it.
  final BackupPayload payload;

  const BackupResult({
    required this.destinationUri,
    required this.bytesWritten,
    required this.payload,
  });

  /// Whether the user chose not to save after all.
  bool get wasCancelled => destinationUri == null;
}

/// Thrown when a backup cannot be made.
class BackupException implements Exception {
  final String message;

  /// True when the archive holds nothing worth saving.
  final bool isEmpty;

  const BackupException(this.message, {this.isEmpty = false});

  @override
  String toString() => 'BackupException: $message';
}

/// Writes the whole `.gallerybak` archive.
///
/// The order of the steps matters, and it is the reverse of the obvious one.
/// The picker comes *after* the payload is built, so the user is not asked
/// where to put a file that then turns out to be empty or impossible. And the
/// staging file is app-private and deleted in a `finally`, so a crash half way
/// through does not leave a plaintext copy of somebody's library sitting in
/// the cache.
///
/// The password is used and dropped. It is never stored, never logged, and
/// there is no recovery: the dialog that asks for it says so.
class BackupService {
  final BackupCollectorService _collector;
  final BackupSerializer _serializer;
  final BackupCryptoChannel _crypto;
  final DocumentPickerChannel _picker;

  BackupService({
    required BackupCollectorService collector,
    required BackupCryptoChannel crypto,
    required DocumentPickerChannel picker,
    BackupSerializer serializer = const BackupSerializer(),
  }) : _collector = collector,
       _crypto = crypto,
       _picker = picker,
       _serializer = serializer;

  /// Makes a backup, asking the user where it should go.
  ///
  /// Returns a result whose [BackupResult.wasCancelled] is true if they backed
  /// out of the picker; that is a normal outcome, not an error.
  Future<BackupResult> createBackup({
    required String password,
    required String appVersion,
    void Function(BackupStage stage)? onStage,
    DateTime? now,
  }) async {
    if (password.length < AppConstants.backupPasswordMinLength) {
      throw const BackupException('The password is too short');
    }

    onStage?.call(BackupStage.collecting);
    final payload = await _collector.collect(appVersion: appVersion, now: now);

    if (payload.isEmpty) {
      throw const BackupException(
        'There are no tags, albums, notes or favourites to back up',
        isEmpty: true,
      );
    }

    onStage?.call(BackupStage.packing);
    final staging = await _writeStagingFile(payload);

    try {
      onStage?.call(BackupStage.choosingDestination);
      final destination = await _picker.createDocument(
        fileName: BackupFormat.suggestedFileName(now ?? DateTime.now()),
      );

      if (destination == null) {
        return BackupResult(
          destinationUri: null,
          bytesWritten: 0,
          payload: payload,
        );
      }

      onStage?.call(BackupStage.encrypting);
      final salt = await _crypto.randomBytes(AppConstants.backupSaltBytes);
      final iv = await _crypto.randomBytes(AppConstants.syncIvLengthBytes);

      final header = BackupFormat.encodeHeader(
        BackupHeader(
          formatVersion: AppConstants.backupFormatVersion,
          salt: salt,
          iterations: AppConstants.backupKdfIterations,
          iv: iv,
        ),
      );

      final written = await _crypto.encryptArchive(
        sourcePath: staging.path,
        destUri: destination,
        header: header,
        password: password,
        salt: salt,
        iv: iv,
        iterations: AppConstants.backupKdfIterations,
      );

      onStage?.call(BackupStage.done);
      return BackupResult(
        destinationUri: destination,
        bytesWritten: written,
        payload: payload,
      );
    } finally {
      // The staging file holds the whole library's metadata in the clear.
      // It goes whatever happened above.
      await _deleteQuietly(staging);
    }
  }

  /// Writes the compressed JSON to an app-private staging file.
  ///
  /// Gzip through `dart:io`, so no package is added for it. Metadata JSON is
  /// mostly repeated keys and paths, which compresses to a small fraction of
  /// its size — worth doing before it is encrypted, because ciphertext does
  /// not compress at all.
  Future<File> _writeStagingFile(BackupPayload payload) async {
    final directory = await getApplicationSupportDirectory();
    final file = File(
      p.join(directory.path, AppConstants.backupStagingFileName),
    );

    final json = _serializer.encode(payload);
    final gzipped = gzip.encode(utf8.encode(json));

    await file.parent.create(recursive: true);
    await file.writeAsBytes(Uint8List.fromList(gzipped), flush: true);
    return file;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nothing useful to do. It is app-private and will go with the cache.
    }
  }
}
