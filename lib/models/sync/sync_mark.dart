import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// A note that one file was sent to one other phone over Wi-Fi.
///
/// Decides what the next send *offers*, not what really moves: the receiver
/// still checks each file's SHA-256 and refuses ones it already has.
@immutable
class SyncMark {
  final String mediaId;

  /// The other phone's random install id.
  final String peerId;

  /// The file's SHA-256 when it was sent.
  final String sha256;

  /// The file's size when it was sent.
  final int sizeBytes;

  final DateTime sentAt;

  const SyncMark({
    required this.mediaId,
    required this.peerId,
    required this.sha256,
    required this.sizeBytes,
    required this.sentAt,
  });

  /// Whether this mark still describes [item] as it is now.
  ///
  /// A file edited since it was sent has a different size, or a different
  /// digest once one is known, so it is offered again.
  bool stillMatches(MediaItem item) {
    if (item.id != mediaId) return false;
    if (item.size != sizeBytes) return false;
    final known = item.sha256Hash;
    return known == null || known.isEmpty || known == sha256;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMark &&
          mediaId == other.mediaId &&
          peerId == other.peerId &&
          sha256 == other.sha256 &&
          sizeBytes == other.sizeBytes &&
          sentAt == other.sentAt;

  @override
  int get hashCode => Object.hash(mediaId, peerId, sha256, sizeBytes, sentAt);
}
