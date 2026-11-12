import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';

/// Everything the send picker shows for one paired phone.
class SyncSources {
  /// The selection first (when there is one), then folders, then albums.
  final List<SyncSource> sources;

  /// The marks for the paired phone, by media id.
  final Map<String, SyncMark> marks;

  const SyncSources({required this.sources, required this.marks});

  static const SyncSources empty = SyncSources(
    sources: <SyncSource>[],
    marks: <String, SyncMark>{},
  );
}
