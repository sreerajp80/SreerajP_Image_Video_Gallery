import 'package:flutter/foundation.dart';

/// The header of a backup archive: what it is and where it came from.
///
/// Read and shown to the user before anything is merged, so they can see the
/// date and the counts and decide whether this is the file they meant. It is
/// inside the encrypted body rather than in the plaintext container header,
/// because how many photos someone has is itself something worth not leaking.
@immutable
class BackupManifest {
  /// Layout version of the JSON body.
  ///
  /// Separate from the container's format version: the envelope and its
  /// contents can move independently, and usually will.
  final int payloadVersion;

  /// Database schema version the backup was taken from.
  ///
  /// Restoring a newer schema into an older build is refused rather than
  /// guessed at.
  final int schemaVersion;

  /// App version string that wrote the archive, for the detail line.
  final String appVersion;

  /// When the archive was written, in milliseconds since the epoch.
  final int createdAtMs;

  final int tagCount;
  final int albumCount;
  final int mediaRecordCount;

  const BackupManifest({
    required this.payloadVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAtMs,
    this.tagCount = 0,
    this.albumCount = 0,
    this.mediaRecordCount = 0,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'payloadVersion': payloadVersion,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'createdAtMs': createdAtMs,
    'tagCount': tagCount,
    'albumCount': albumCount,
    'mediaRecordCount': mediaRecordCount,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      payloadVersion: (json['payloadVersion'] as num?)?.toInt() ?? 1,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      appVersion: json['appVersion'] as String? ?? '',
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      tagCount: (json['tagCount'] as num?)?.toInt() ?? 0,
      albumCount: (json['albumCount'] as num?)?.toInt() ?? 0,
      mediaRecordCount: (json['mediaRecordCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupManifest &&
          runtimeType == other.runtimeType &&
          payloadVersion == other.payloadVersion &&
          schemaVersion == other.schemaVersion &&
          appVersion == other.appVersion &&
          createdAtMs == other.createdAtMs &&
          tagCount == other.tagCount &&
          albumCount == other.albumCount &&
          mediaRecordCount == other.mediaRecordCount;

  @override
  int get hashCode => Object.hash(
    payloadVersion,
    schemaVersion,
    appVersion,
    createdAtMs,
    tagCount,
    albumCount,
    mediaRecordCount,
  );
}
