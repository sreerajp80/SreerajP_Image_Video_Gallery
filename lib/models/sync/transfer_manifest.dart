import 'package:flutter/foundation.dart';

/// One file being offered to the peer.
///
/// Sent ahead of the bytes so the receiving side knows what is coming, can
/// refuse a file that is too large, and can check afterwards that what
/// arrived is what was promised. That check is what lets an incoming file be
/// moved into the gallery at all: nothing is put in place until its length
/// and digest match this entry.
@immutable
class TransferEntry {
  /// Media id on the sending device. Used to line up progress, not stored.
  final String sourceId;

  /// Base filename with extension, as the receiver should name it.
  ///
  /// Sanitised by the sender and again by the receiver: a peer that offers
  /// `../../etc/passwd` gets its name replaced, not honoured.
  final String displayName;

  /// MIME type of the file.
  final String mimeType;

  /// Media type name, matching [MediaType].
  final String mediaTypeName;

  /// Exact byte length.
  final int sizeBytes;

  /// SHA-256 of the file contents, lower-case hex.
  final String sha256;

  /// Capture time in milliseconds since the epoch, if known.
  final int? dateTakenMs;

  /// Tag names travelling with the file.
  ///
  /// Names, not ids: the receiver's tag ids mean nothing to the sender, so
  /// the receiver finds or creates a tag of the same name.
  final List<String> tagNames;

  /// The user's note text, if any.
  final String? userNotes;

  /// Whether the file was a favourite on the sending device.
  final bool isFavorite;

  const TransferEntry({
    required this.sourceId,
    required this.displayName,
    required this.mimeType,
    required this.mediaTypeName,
    required this.sizeBytes,
    required this.sha256,
    this.dateTakenMs,
    this.tagNames = const <String>[],
    this.userNotes,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceId': sourceId,
    'displayName': displayName,
    'mimeType': mimeType,
    'mediaTypeName': mediaTypeName,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    if (dateTakenMs != null) 'dateTakenMs': dateTakenMs,
    if (tagNames.isNotEmpty) 'tagNames': tagNames,
    if (userNotes != null) 'userNotes': userNotes,
    'isFavorite': isFavorite,
  };

  factory TransferEntry.fromJson(Map<String, dynamic> json) => TransferEntry(
    sourceId: json['sourceId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
    mediaTypeName: json['mediaTypeName'] as String? ?? 'image',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
    dateTakenMs: (json['dateTakenMs'] as num?)?.toInt(),
    tagNames:
        (json['tagNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[],
    userNotes: json['userNotes'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferEntry &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          displayName == other.displayName &&
          mimeType == other.mimeType &&
          mediaTypeName == other.mediaTypeName &&
          sizeBytes == other.sizeBytes &&
          sha256 == other.sha256 &&
          dateTakenMs == other.dateTakenMs &&
          listEquals(tagNames, other.tagNames) &&
          userNotes == other.userNotes &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hash(
    sourceId,
    displayName,
    mimeType,
    mediaTypeName,
    sizeBytes,
    sha256,
    dateTakenMs,
    Object.hashAll(tagNames),
    userNotes,
    isFavorite,
  );
}

/// The full list of files one transfer will carry.
@immutable
class TransferManifest {
  final List<TransferEntry> entries;

  const TransferManifest({this.entries = const <TransferEntry>[]});

  /// An empty offer.
  static const TransferManifest empty = TransferManifest();

  int get fileCount => entries.length;

  /// Total bytes the transfer will move.
  int get totalBytes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entries': entries.map((e) => e.toJson()).toList(growable: false),
  };

  factory TransferManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List<dynamic>? ?? const <dynamic>[];
    return TransferManifest(
      entries: raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => TransferEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferManifest &&
          runtimeType == other.runtimeType &&
          listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hashAll(entries);
}
