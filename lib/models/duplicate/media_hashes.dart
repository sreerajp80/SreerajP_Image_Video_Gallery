import 'package:flutter/foundation.dart';

/// The fingerprints of one media item.
///
/// [sha256] answers "are these the same bytes". [pHash] and [dHash] answer
/// "do these look the same", which is a different and much softer question.
/// Videos only ever get a [sha256]; the perceptual pair is for pictures.
@immutable
class MediaHashes {
  /// Id of the media item these hashes belong to.
  final String mediaId;

  /// Lower-case hex SHA-256 of the whole file, or null when it was not read.
  final String? sha256;

  /// 64-bit DCT perceptual hash, or null for a video or an unreadable file.
  final int? pHash;

  /// 64-bit difference hash, or null for a video or an unreadable file.
  final int? dHash;

  const MediaHashes({
    required this.mediaId,
    this.sha256,
    this.pHash,
    this.dHash,
  });

  /// True when at least one fingerprint was worked out.
  bool get hasAny => sha256 != null || pHash != null;

  /// True when both perceptual hashes are present.
  bool get hasPerceptual => pHash != null && dHash != null;

  /// The two perceptual hashes as one storable string, or null when there is
  /// nothing to store.
  ///
  /// The database has a single `p_hash` column, so both hashes share it as
  /// `<phash>:<dhash>` in hex. Keeping them together avoids a schema change
  /// and means neither hash is lost.
  String? get encodedPerceptual {
    final perceptual = pHash;
    if (perceptual == null) return null;
    final difference = dHash;
    final head = toHex64(perceptual);
    if (difference == null) return head;
    return '$head:${toHex64(difference)}';
  }

  /// Reads back a value written by [encodedPerceptual].
  ///
  /// Returns a `(pHash, dHash)` pair, either of which may be null when the
  /// stored text is missing or malformed.
  static ({int? pHash, int? dHash}) decodePerceptual(String? stored) {
    if (stored == null || stored.isEmpty) {
      return (pHash: null, dHash: null);
    }
    final parts = stored.split(':');
    final head = fromHex64(parts.first);
    final tail = parts.length > 1 ? fromHex64(parts[1]) : null;
    return (pHash: head, dHash: tail);
  }

  /// A 64-bit hash as exactly 16 hex characters.
  ///
  /// The value is written as two 32-bit halves rather than in one go. A hash
  /// with its top bit set is a negative Dart integer, and asking such a value
  /// for its radix string would produce a minus sign instead of the bit
  /// pattern, which would not survive a round trip.
  static String toHex64(int value) {
    final high = (value >>> 32) & 0xFFFFFFFF;
    final low = value & 0xFFFFFFFF;
    return high.toRadixString(16).padLeft(8, '0') +
        low.toRadixString(16).padLeft(8, '0');
  }

  /// Reads 16 hex characters back into a 64-bit hash, or null when the text
  /// is not that.
  static int? fromHex64(String value) {
    final trimmed = value.trim();
    if (trimmed.length != 16) return null;
    final high = int.tryParse(trimmed.substring(0, 8), radix: 16);
    final low = int.tryParse(trimmed.substring(8), radix: 16);
    if (high == null || low == null) return null;
    return (high << 32) | low;
  }

  /// Builds hashes from the two database columns.
  factory MediaHashes.fromColumns({
    required String mediaId,
    String? sha256,
    String? storedPerceptual,
  }) {
    final decoded = decodePerceptual(storedPerceptual);
    return MediaHashes(
      mediaId: mediaId,
      sha256: (sha256 != null && sha256.isEmpty) ? null : sha256,
      pHash: decoded.pHash,
      dHash: decoded.dHash,
    );
  }

  MediaHashes copyWith({
    String? mediaId,
    String? sha256,
    int? pHash,
    int? dHash,
  }) {
    return MediaHashes(
      mediaId: mediaId ?? this.mediaId,
      sha256: sha256 ?? this.sha256,
      pHash: pHash ?? this.pHash,
      dHash: dHash ?? this.dHash,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaHashes &&
          runtimeType == other.runtimeType &&
          mediaId == other.mediaId &&
          sha256 == other.sha256 &&
          pHash == other.pHash &&
          dHash == other.dHash;

  @override
  int get hashCode => Object.hash(mediaId, sha256, pHash, dHash);
}
