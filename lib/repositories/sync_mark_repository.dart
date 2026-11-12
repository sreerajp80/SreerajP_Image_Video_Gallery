import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/sync_mark_dao.dart';

/// The only way the app reads or writes "sent to that phone" marks.
class SyncMarkRepository {
  final SyncMarkDao _dao;

  SyncMarkRepository({SyncMarkDao? dao}) : _dao = dao ?? SyncMarkDao();

  /// Records that one file now sits on the phone [peerId].
  Future<void> markSent({
    required String peerId,
    required String mediaId,
    required String sha256,
    required int sizeBytes,
    DateTime? now,
  }) {
    return _dao.saveMark(
      SyncMark(
        mediaId: mediaId,
        peerId: peerId,
        sha256: sha256,
        sizeBytes: sizeBytes,
        sentAt: now ?? DateTime.now(),
      ),
    );
  }

  /// Every mark for one phone, by media id.
  Future<Map<String, SyncMark>> marksForPeer(String peerId) =>
      _dao.marksForPeer(peerId);

  /// Forgets every mark for one phone, so everything is offered again.
  Future<void> clearPeer(String peerId) => _dao.clearPeer(peerId);
}
