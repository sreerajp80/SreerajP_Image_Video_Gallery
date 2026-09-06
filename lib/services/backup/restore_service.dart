import 'dart:convert';
import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_apply_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_crypto_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_format.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_merge_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// An archive that has been opened and understood, but not yet applied.
///
/// The user sees the plan built from this and decides. Keeping the payload
/// alongside it is what lets "Restore" happen without asking for the password
/// a second time.
class OpenedArchive {
  final BackupPayload payload;
  final RestorePlan plan;

  /// The local media the plan was worked out against.
  ///
  /// Held so applying uses exactly what the preview was computed from, rather
  /// than a library that may have been rescanned in between.
  final List<MediaItem> localMedia;

  const OpenedArchive({
    required this.payload,
    required this.plan,
    required this.localMedia,
  });
}

/// Why a restore could not go ahead.
enum RestoreFailure {
  /// The user backed out of the file picker. Not really a failure.
  cancelled,

  /// The chosen file is not one of ours.
  notAnArchive,

  /// The password did not open it, or the file is damaged.
  wrongPasswordOrDamaged,

  /// The file is larger than any real archive would be.
  tooLarge,

  /// The archive was written by a newer build.
  tooNew,

  /// Something else went wrong.
  failed,
}

/// Thrown when a restore cannot go ahead.
class RestoreException implements Exception {
  final RestoreFailure failure;
  final String message;

  const RestoreException(this.failure, this.message);

  @override
  String toString() => 'RestoreException(${failure.name}): $message';
}

/// Opens an archive and, once the user agrees, applies it.
///
/// Split into two calls on purpose. [openArchive] does everything that can be
/// undone by walking away — pick, decrypt, parse, plan — and writes nothing.
/// [applyPlan] is the only part that touches the database, and it only runs
/// after the user has seen the counts and said yes.
class RestoreService {
  /// How much of the file to fetch to find the header in.
  ///
  /// The header is well under a hundred bytes for the current layout. Reading
  /// a comfortable 256 leaves room for a future one to grow without another
  /// round trip, and is still nothing next to the archive itself.
  static const int _headerPrefixBytes = 256;

  final BackupCryptoChannel _crypto;
  final DocumentPickerChannel _picker;
  final BackupSerializer _serializer;
  final BackupMergeService _merge;
  final BackupApplyService _apply;
  final MediaRepository _mediaRepository;
  final TagRepository _tagRepository;
  final AlbumRepository _albumRepository;

  RestoreService({
    required BackupCryptoChannel crypto,
    required DocumentPickerChannel picker,
    required BackupApplyService apply,
    required MediaRepository mediaRepository,
    required TagRepository tagRepository,
    required AlbumRepository albumRepository,
    BackupSerializer serializer = const BackupSerializer(),
    BackupMergeService merge = const BackupMergeService(),
  }) : _crypto = crypto,
       _picker = picker,
       _apply = apply,
       _mediaRepository = mediaRepository,
       _tagRepository = tagRepository,
       _albumRepository = albumRepository,
       _serializer = serializer,
       _merge = merge;

  /// Asks the user for a file and reads it, without writing anything.
  ///
  /// Returns null if they backed out of the picker.
  Future<OpenedArchive?> openArchive({required String password}) async {
    final uri = await _picker.openDocument();
    if (uri == null) return null;

    // Refuse an absurd file before asking the cipher to stream it. A metadata
    // archive is at most a few tens of megabytes; a gigabyte file is not one
    // of ours whatever its name says.
    final info = await _picker.documentInfo(uri);
    if (info != null &&
        info.hasSize &&
        info.sizeBytes > AppConstants.backupMaxArchiveBytes) {
      throw const RestoreException(
        RestoreFailure.tooLarge,
        'That file is too large to be a gallery backup',
      );
    }
    if (info != null &&
        info.hasSize &&
        info.sizeBytes < BackupFormat.minimumFileBytes) {
      throw const RestoreException(
        RestoreFailure.notAnArchive,
        'That file is too small to be a gallery backup',
      );
    }

    final staging = await _stagingFile();

    try {
      final header = await _readHeader(uri);
      final headerBytes = BackupFormat.encodeHeader(header);

      await _crypto.decryptArchive(
        sourceUri: uri,
        destPath: staging.path,
        header: headerBytes,
        password: password,
        salt: header.salt,
        iv: header.iv,
        iterations: header.iterations,
      );

      final payload = _serializer.decode(
        utf8.decode(gzip.decode(await staging.readAsBytes())),
      );

      final localMedia = await _mediaRepository.getMediaItems();
      final plan = _merge.buildPlan(
        payload: payload,
        localMedia: localMedia,
        localTags: await _tagRepository.getAllTags(),
        localAlbums: await _albumRepository.getVirtualAlbums(),
        newId: _newId,
      );

      return OpenedArchive(
        payload: payload,
        plan: plan,
        localMedia: localMedia,
      );
    } on BackupCryptoException catch (error) {
      if (error.isWrongPassword) {
        throw const RestoreException(
          RestoreFailure.wrongPasswordOrDamaged,
          'Wrong password, or the file is damaged',
        );
      }
      throw RestoreException(RestoreFailure.failed, error.message);
    } on BackupFormatException catch (error) {
      throw RestoreException(
        error.message.contains('newer')
            ? RestoreFailure.tooNew
            : RestoreFailure.notAnArchive,
        error.message,
      );
    } on BackupSerializerException catch (error) {
      throw RestoreException(
        error.message.contains('newer')
            ? RestoreFailure.tooNew
            : RestoreFailure.notAnArchive,
        error.message,
      );
    } finally {
      // The staging file is the archive in the clear. It goes either way.
      await _deleteQuietly(staging);
    }
  }

  /// Writes an opened archive into the database.
  ///
  /// The only call here that changes anything, and it runs after the user has
  /// seen the plan.
  Future<RestoreSummary> applyPlan(
    OpenedArchive archive, {
    void Function(int done, int total)? onProgress,
  }) {
    return _apply.apply(
      plan: archive.plan,
      payload: archive.payload,
      localMedia: archive.localMedia,
      onProgress: onProgress,
    );
  }

  /// Reads and parses the plaintext header off the front of the file.
  ///
  /// The header is not encrypted, only authenticated, so it can be read and
  /// understood before a password is involved at all. That is what lets the
  /// app say "this is not a backup file" without first making somebody type
  /// a password for a file that was never going to open.
  Future<BackupHeader> _readHeader(String uri) async {
    final prefix = await _picker.readPrefix(uri, _headerPrefixBytes);

    if (!BackupFormat.looksLikeArchive(prefix)) {
      throw const RestoreException(
        RestoreFailure.notAnArchive,
        'That file is not a gallery backup',
      );
    }
    return BackupFormat.decodeHeader(prefix);
  }

  Future<File> _stagingFile({String suffix = ''}) async {
    final directory = await getApplicationSupportDirectory();
    return File(
      p.join(directory.path, '${AppConstants.restoreStagingFileName}$suffix'),
    );
  }

  /// Mints an id for a tag or album a restore has to create.
  ///
  /// Same shape as the repositories use: a readable slug plus the clock, so a
  /// restored tag looks no different from a typed one.
  static String _newId(String seed) {
    final slug = seed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return slug.isEmpty ? 'restored_$stamp' : '${slug}_$stamp';
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // App-private; it goes with the cache.
    }
  }
}
