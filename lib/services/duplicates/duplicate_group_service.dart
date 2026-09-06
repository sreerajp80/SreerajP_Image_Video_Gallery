import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/media_hashes.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/best_photo_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/perceptual_hash_service.dart';

/// Sorts a pile of fingerprints into groups of copies.
///
/// Pure: it is handed the items and their hashes and hands back the groups,
/// with no database, no files, and no platform anywhere in between.
class DuplicateGroupService {
  /// Largest pHash distance still counted as the same picture.
  final int pHashThreshold;

  /// Largest dHash distance allowed alongside the pHash match.
  final int dHashThreshold;

  /// How many bit slices a hash is bucketed by.
  final int bandCount;

  /// Picks which copy to keep in each group.
  final BestPhotoService bestPhotoService;

  const DuplicateGroupService({
    this.pHashThreshold = AppConstants.duplicatePHashThreshold,
    this.dHashThreshold = AppConstants.duplicateDHashThreshold,
    this.bandCount = AppConstants.duplicateHashBandCount,
    this.bestPhotoService = const BestPhotoService(),
  });

  /// Builds every duplicate group from [items] and their [hashes].
  ///
  /// Exact groups come first, because they are certain, and their members are
  /// then left out of the similarity pass so one photo never turns up in two
  /// groups. Groups are ordered by how much space they would free, so the
  /// biggest win is at the top of the cleaner.
  List<DuplicateGroup> buildGroups({
    required List<MediaItem> items,
    required Map<String, MediaHashes> hashes,
  }) {
    final byId = <String, MediaItem>{for (final item in items) item.id: item};

    final exact = _buildExactGroups(items, hashes, byId);

    final claimed = <String>{
      for (final group in exact)
        for (final item in group.items) item.id,
    };

    final similar = _buildSimilarGroups(items, hashes, byId, claimed);

    final all = <DuplicateGroup>[...exact, ...similar]
      ..sort((a, b) => b.reclaimableBytes.compareTo(a.reclaimableBytes));
    return all;
  }

  /// Groups files whose bytes are identical.
  ///
  /// A shared SHA-256 is proof, not a guess, so this needs no threshold and
  /// no comparison: same digest, same group.
  List<DuplicateGroup> _buildExactGroups(
    List<MediaItem> items,
    Map<String, MediaHashes> hashes,
    Map<String, MediaItem> byId,
  ) {
    final buckets = <String, List<String>>{};
    for (final item in items) {
      final digest = hashes[item.id]?.sha256;
      if (digest == null || digest.isEmpty) continue;
      buckets.putIfAbsent(digest, () => <String>[]).add(item.id);
    }

    final groups = <DuplicateGroup>[];
    for (final entry in buckets.entries) {
      if (entry.value.length < 2) continue;
      groups.add(
        _makeGroup(
          id: 'exact_${entry.key}',
          kind: DuplicateGroupKind.exact,
          memberIds: entry.value,
          byId: byId,
        ),
      );
    }
    return groups;
  }

  /// Groups pictures that merely look the same.
  ///
  /// Comparing every picture with every other would be quadratic, so each
  /// hash is first bucketed by its bit slices and only pictures sharing a
  /// slice are compared properly. Matches are then merged with a union-find,
  /// which is what turns a burst of five near-identical shots into one group
  /// of five rather than ten separate pairs.
  List<DuplicateGroup> _buildSimilarGroups(
    List<MediaItem> items,
    Map<String, MediaHashes> hashes,
    Map<String, MediaItem> byId,
    Set<String> claimed,
  ) {
    final candidates = <String, MediaHashes>{};
    for (final item in items) {
      if (claimed.contains(item.id)) continue;
      final hash = hashes[item.id];
      if (hash == null || !hash.hasPerceptual) continue;
      candidates[item.id] = hash;
    }
    if (candidates.length < 2) return const <DuplicateGroup>[];

    // Bucket by bit slice. The band index is part of the key so a slice value
    // only ever collides with the same slice of another hash.
    final buckets = <String, List<String>>{};
    for (final entry in candidates.entries) {
      final bands = PerceptualHashService.bands(
        entry.value.pHash!,
        bandCount: bandCount,
      );
      for (var i = 0; i < bands.length; i++) {
        buckets.putIfAbsent('$i:${bands[i]}', () => <String>[]).add(entry.key);
      }
    }

    final union = _UnionFind();
    final compared = <String>{};
    for (final bucket in buckets.values) {
      if (bucket.length < 2) continue;
      for (var i = 0; i < bucket.length; i++) {
        for (var j = i + 1; j < bucket.length; j++) {
          final a = bucket[i];
          final b = bucket[j];
          // A pair can share more than one slice; compare it only once.
          final key = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
          if (!compared.add(key)) continue;
          if (areSimilar(candidates[a]!, candidates[b]!)) {
            union.union(a, b);
          }
        }
      }
    }

    final clusters = <String, List<String>>{};
    for (final id in candidates.keys) {
      final root = union.find(id);
      clusters.putIfAbsent(root, () => <String>[]).add(id);
    }

    final groups = <DuplicateGroup>[];
    for (final entry in clusters.entries) {
      if (entry.value.length < 2) continue;
      groups.add(
        _makeGroup(
          id: 'similar_${entry.key}',
          kind: DuplicateGroupKind.similar,
          memberIds: entry.value,
          byId: byId,
        ),
      );
    }
    return groups;
  }

  /// True when two pictures should be called the same.
  ///
  /// Both hashes have to agree. The DCT hash alone pairs photos that merely
  /// share a layout; the difference hash alone is fooled by a contrast
  /// change. Requiring both cuts nearly all of the false pairs each makes on
  /// its own, at the cost of missing a few genuinely heavy edits, which is
  /// the right way round for a screen that offers to bin photos.
  bool areSimilar(MediaHashes a, MediaHashes b) {
    if (!a.hasPerceptual || !b.hasPerceptual) return false;
    final perceptualDistance = PerceptualHashService.hammingDistance(
      a.pHash!,
      b.pHash!,
    );
    if (perceptualDistance > pHashThreshold) return false;
    final differenceDistance = PerceptualHashService.hammingDistance(
      a.dHash!,
      b.dHash!,
    );
    return differenceDistance <= dHashThreshold;
  }

  DuplicateGroup _makeGroup({
    required String id,
    required DuplicateGroupKind kind,
    required List<String> memberIds,
    required Map<String, MediaItem> byId,
  }) {
    final members = <MediaItem>[
      for (final memberId in memberIds)
        if (byId[memberId] != null) byId[memberId]!,
    ];
    final ordered = bestPhotoService.rank(members);
    return DuplicateGroup(
      id: id,
      kind: kind,
      items: ordered,
      suggestedKeeperId: ordered.first.id,
    );
  }
}

/// The smallest union-find that does the job.
///
/// Merging pairs into clusters is exactly what this structure is for: it is
/// what stops five photos of the same moment becoming ten overlapping pairs.
class _UnionFind {
  final Map<String, String> _parent = <String, String>{};

  String find(String id) {
    var current = id;
    while (_parent[current] != null && _parent[current] != current) {
      // Path halving, so repeated lookups stay flat.
      final grandparent = _parent[_parent[current]!] ?? _parent[current]!;
      _parent[current] = grandparent;
      current = grandparent;
    }
    _parent.putIfAbsent(current, () => current);
    return current;
  }

  void union(String a, String b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA == rootB) return;
    // Smaller id wins, purely so the resulting group ids are stable between
    // runs and a route to a group keeps working.
    if (rootA.compareTo(rootB) <= 0) {
      _parent[rootB] = rootA;
    } else {
      _parent[rootA] = rootB;
    }
  }
}
