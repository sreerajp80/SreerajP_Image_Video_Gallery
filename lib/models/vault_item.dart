import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Immutable domain model representing an encrypted media record inside the Private Vault.
@immutable
class VaultItem {
  /// Unique identifier (UUID).
  final String id;

  /// Original storage path before being vaulted and shredded.
  final String originalPath;

  /// Original human-readable filename (e.g. "secret_document.jpg").
  final String originalFilename;

  /// Obfuscated filename on disk inside the vault directory (e.g. "a1b2c3.enc").
  final String encryptedFilename;

  /// Obfuscated filename of the encrypted thumbnail preview.
  final String? encryptedThumbnailFilename;

  /// Media type (image, video, etc.).
  final MediaType mediaType;

  /// Original MIME type.
  final String mimeType;

  /// Encrypted payload size in bytes.
  final int sizeBytes;

  /// Base64-encoded Initialization Vector (IV) for AES-GCM.
  final String iv;

  /// Base64-encoded IV of the encrypted thumbnail, when there is one.
  ///
  /// Separate from [iv] because every file is encrypted under a fresh IV, so
  /// the payload's cannot decrypt the preview stored beside it. Null on a
  /// record that has no preview, and on a record written before this field
  /// existed — the reader treats both the same way and simply shows an icon,
  /// rather than handing the wrong IV to the cipher.
  final String? thumbnailIv;

  /// Base64-encoded authentication tag for AES-GCM integrity.
  final String? authTag;

  /// Timestamp when the item was imported into the vault.
  final DateTime dateVaulted;

  /// Original capture date/time.
  final DateTime? dateTaken;

  /// Pixel width.
  final int? width;

  /// Pixel height.
  final int? height;

  /// Video duration in milliseconds.
  final int? durationMs;

  /// Attached tags.
  final List<String> tags;

  /// Private user notes.
  final String? notes;

  const VaultItem({
    required this.id,
    required this.originalPath,
    required this.originalFilename,
    required this.encryptedFilename,
    this.encryptedThumbnailFilename,
    required this.mediaType,
    required this.mimeType,
    required this.sizeBytes,
    required this.iv,
    this.thumbnailIv,
    this.authTag,
    required this.dateVaulted,
    this.dateTaken,
    this.width,
    this.height,
    this.durationMs,
    this.tags = const <String>[],
    this.notes,
  });

  /// Creates a copy of [VaultItem] with updated properties.
  VaultItem copyWith({
    String? id,
    String? originalPath,
    String? originalFilename,
    String? encryptedFilename,
    String? encryptedThumbnailFilename,
    MediaType? mediaType,
    String? mimeType,
    int? sizeBytes,
    String? iv,
    String? thumbnailIv,
    String? authTag,
    DateTime? dateVaulted,
    DateTime? dateTaken,
    int? width,
    int? height,
    int? durationMs,
    List<String>? tags,
    String? notes,
  }) {
    return VaultItem(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      originalFilename: originalFilename ?? this.originalFilename,
      encryptedFilename: encryptedFilename ?? this.encryptedFilename,
      encryptedThumbnailFilename:
          encryptedThumbnailFilename ?? this.encryptedThumbnailFilename,
      mediaType: mediaType ?? this.mediaType,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      iv: iv ?? this.iv,
      thumbnailIv: thumbnailIv ?? this.thumbnailIv,
      authTag: authTag ?? this.authTag,
      dateVaulted: dateVaulted ?? this.dateVaulted,
      dateTaken: dateTaken ?? this.dateTaken,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  /// Converts this [VaultItem] to a database-ready map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_path': originalPath,
      'original_filename': originalFilename,
      'encrypted_filename': encryptedFilename,
      'encrypted_thumbnail_filename': encryptedThumbnailFilename,
      'media_type': mediaType.name,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'iv': iv,
      'thumbnail_iv': thumbnailIv,
      'auth_tag': authTag,
      'date_vaulted': dateVaulted.millisecondsSinceEpoch,
      'date_taken': dateTaken?.millisecondsSinceEpoch,
      'width': width,
      'height': height,
      'duration_ms': durationMs,
      'tags_json': jsonEncode(tags),
      'notes': notes,
    };
  }

  /// Constructs a [VaultItem] from a database row or map.
  factory VaultItem.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = const [];
    final rawTags = map['tags_json'] ?? map['tags'];
    if (rawTags is String && rawTags.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    return VaultItem(
      id: map['id'] as String,
      originalPath: (map['original_path'] ?? map['originalPath']) as String,
      originalFilename:
          (map['original_filename'] ?? map['originalFilename']) as String,
      encryptedFilename:
          (map['encrypted_filename'] ?? map['encryptedFilename']) as String,
      encryptedThumbnailFilename:
          (map['encrypted_thumbnail_filename'] ??
                  map['encryptedThumbnailFilename'])
              as String?,
      mediaType: MediaType.fromString(
        (map['media_type'] ?? map['mediaType'] ?? 'image') as String,
      ),
      mimeType: (map['mime_type'] ?? map['mimeType']) as String,
      sizeBytes: (map['size_bytes'] ?? map['sizeBytes']) as int,
      iv: map['iv'] as String,
      thumbnailIv: (map['thumbnail_iv'] ?? map['thumbnailIv']) as String?,
      authTag: (map['auth_tag'] ?? map['authTag']) as String?,
      dateVaulted: map['date_vaulted'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_vaulted'] as int)
          : DateTime.parse(map['date_vaulted'].toString()),
      dateTaken: map['date_taken'] != null
          ? (map['date_taken'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['date_taken'] as int)
                : DateTime.tryParse(map['date_taken'].toString()))
          : null,
      width: map['width'] as int?,
      height: map['height'] as int?,
      durationMs: (map['duration_ms'] ?? map['durationMs']) as int?,
      tags: parsedTags,
      notes: map['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          originalPath == other.originalPath &&
          originalFilename == other.originalFilename &&
          encryptedFilename == other.encryptedFilename &&
          encryptedThumbnailFilename == other.encryptedThumbnailFilename &&
          mediaType == other.mediaType &&
          mimeType == other.mimeType &&
          sizeBytes == other.sizeBytes &&
          iv == other.iv &&
          thumbnailIv == other.thumbnailIv &&
          authTag == other.authTag &&
          dateVaulted == other.dateVaulted &&
          dateTaken == other.dateTaken &&
          width == other.width &&
          height == other.height &&
          durationMs == other.durationMs &&
          listEquals(tags, other.tags) &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    id,
    originalPath,
    originalFilename,
    encryptedFilename,
    encryptedThumbnailFilename,
    mediaType,
    mimeType,
    sizeBytes,
    iv,
    thumbnailIv,
    authTag,
    dateVaulted,
    dateTaken,
    width,
    height,
    durationMs,
    Object.hashAll(tags),
    notes,
  );
}
