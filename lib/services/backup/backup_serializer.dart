import 'dart:convert';

import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';

/// Thrown when an archive body is not something this build can read.
class BackupSerializerException implements Exception {
  final String message;
  const BackupSerializerException(this.message);

  @override
  String toString() => 'BackupSerializerException: $message';
}

/// Turns a [BackupPayload] into the JSON that goes inside an archive, and
/// back out again.
///
/// Pure, so the round trip is testable without a device, a password or a file.
///
/// The read direction is forgiving in one specific way and strict in every
/// other. It ignores keys it does not recognise, so an archive written by a
/// later version still restores what this build understands instead of
/// throwing. It refuses a payload version it does not know, because guessing
/// at a layout that changed is how a restore quietly writes the wrong thing.
class BackupSerializer {
  const BackupSerializer();

  /// Layout version of the JSON body this build writes.
  static const int payloadVersion = 1;

  /// Writes a payload as a compact JSON string.
  String encode(BackupPayload payload) {
    return jsonEncode(<String, dynamic>{
      'manifest': payload.manifest.toJson(),
      'tags': payload.tags.map((t) => t.toJson()).toList(growable: false),
      'albums': payload.albums.map((a) => a.toJson()).toList(growable: false),
      'tagLinks': payload.tagLinks
          .map((l) => l.toJson())
          .toList(growable: false),
      'albumLinks': payload.albumLinks
          .map((l) => l.toJson())
          .toList(growable: false),
      'mediaRecords': payload.mediaRecords
          .map((r) => r.toJson())
          .toList(growable: false),
    });
  }

  /// Reads a payload back.
  ///
  /// Throws [BackupSerializerException] when the text is not JSON, is not an
  /// object, or announces a payload version this build does not know.
  BackupPayload decode(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      throw BackupSerializerException('Archive body is not valid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupSerializerException(
        'Archive body is not a JSON object',
      );
    }

    final manifestJson = decoded['manifest'];
    if (manifestJson is! Map<String, dynamic>) {
      throw const BackupSerializerException('Archive body has no manifest');
    }
    final manifest = BackupManifest.fromJson(manifestJson);

    if (manifest.payloadVersion > payloadVersion) {
      throw BackupSerializerException(
        'Archive body version ${manifest.payloadVersion} is newer than this '
        'app understands ($payloadVersion)',
      );
    }

    return BackupPayload(
      manifest: manifest,
      tags: _list(decoded['tags'], BackupTag.fromJson),
      albums: _list(decoded['albums'], BackupAlbum.fromJson),
      tagLinks: _list(decoded['tagLinks'], BackupTagLink.fromJson),
      albumLinks: _list(decoded['albumLinks'], BackupAlbumLink.fromJson),
      mediaRecords: _list(decoded['mediaRecords'], BackupMediaRecord.fromJson),
    );
  }

  /// Reads one list, skipping any entry that is not an object.
  ///
  /// A single malformed row loses that row, not the whole archive. Somebody
  /// restoring after a device failure is not helped by an all-or-nothing
  /// parser.
  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return <T>[];
    final out = <T>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        out.add(fromJson(entry));
      } else if (entry is Map) {
        out.add(fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return List<T>.unmodifiable(out);
  }
}
