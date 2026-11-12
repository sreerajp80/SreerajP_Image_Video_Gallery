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

  /// Album names travelling with the file, by the same rule as tags.
  final List<String> albumNames;

  /// The user's note text, if any.
  final String? userNotes;

  /// Whether the file was a favourite on the sending device.
  final bool isFavorite;

  /// Place name the sender had for the file, if any.
  final String? address;

  final double? latitude;
  final double? longitude;

  /// Name of the folder the file sits in on the sending device.
  ///
  /// The receiver puts the file in a subfolder of this name, inside its own
  /// receive folder. Untrusted: cleaned by `FolderNameRules` before use.
  final String? sourceFolder;

  /// True when the file comes from the sender's private vault.
  ///
  /// The receiver puts such a file into its own vault, encrypted with its own
  /// key, and never into the public gallery or MediaStore.
  final bool vault;

  const TransferEntry({
    required this.sourceId,
    required this.displayName,
    required this.mimeType,
    required this.mediaTypeName,
    required this.sizeBytes,
    required this.sha256,
    this.dateTakenMs,
    this.tagNames = const <String>[],
    this.albumNames = const <String>[],
    this.userNotes,
    this.isFavorite = false,
    this.address,
    this.latitude,
    this.longitude,
    this.sourceFolder,
    this.vault = false,
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
    if (albumNames.isNotEmpty) 'albumNames': albumNames,
    if (userNotes != null) 'userNotes': userNotes,
    'isFavorite': isFavorite,
    if (address != null) 'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (sourceFolder != null) 'sourceFolder': sourceFolder,
    if (vault) 'vault': true,
  };

  factory TransferEntry.fromJson(Map<String, dynamic> json) => TransferEntry(
    sourceId: json['sourceId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
    mediaTypeName: json['mediaTypeName'] as String? ?? 'image',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
    dateTakenMs: (json['dateTakenMs'] as num?)?.toInt(),
    tagNames: _stringList(json['tagNames']),
    albumNames: _stringList(json['albumNames']),
    userNotes: json['userNotes'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    address: json['address'] as String?,
    latitude: _finiteOrNull(json['latitude']),
    longitude: _finiteOrNull(json['longitude']),
    sourceFolder: json['sourceFolder'] as String?,
    vault: json['vault'] == true,
  );

  /// Reads a list of names, ignoring anything that is not a list.
  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  /// A number from the peer, or null when it is missing, not a number, or
  /// not finite. A NaN latitude must never reach the database.
  static double? _finiteOrNull(Object? raw) {
    if (raw is! num) return null;
    final value = raw.toDouble();
    return value.isFinite ? value : null;
  }

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
          listEquals(albumNames, other.albumNames) &&
          userNotes == other.userNotes &&
          isFavorite == other.isFavorite &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          sourceFolder == other.sourceFolder &&
          vault == other.vault;

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
    Object.hashAll(albumNames),
    userNotes,
    isFavorite,
    address,
    latitude,
    longitude,
    sourceFolder,
    vault,
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
