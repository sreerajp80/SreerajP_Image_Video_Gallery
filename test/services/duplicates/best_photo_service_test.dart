import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/best_photo_service.dart';

MediaItem item({
  required String id,
  int size = 1000,
  int? width = 100,
  int? height = 100,
  DateTime? dateTaken,
  ExifData? exif,
  bool favorite = false,
  DateTime? added,
}) {
  final when = added ?? DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: when,
    dateModified: when,
    dateTaken: dateTaken,
    width: width,
    height: height,
    exifData: exif,
    isFavorite: favorite,
  );
}

void main() {
  const service = BestPhotoService();

  group('BestPhotoService scoring', () {
    test('prefers the copy with more pixels', () {
      final small = item(id: 'small', width: 100, height: 100);
      final large = item(id: 'large', width: 400, height: 300);

      expect(service.pickBest(<MediaItem>[small, large])?.id, 'large');
    });

    test('at equal pixels, prefers the bigger file', () {
      // Same dimensions means the larger file was saved at higher quality.
      final light = item(id: 'light', size: 500);
      final heavy = item(id: 'heavy', size: 900);

      expect(service.pickBest(<MediaItem>[light, heavy])?.id, 'heavy');
    });

    test('prefers a copy that kept its capture date', () {
      final stripped = item(id: 'stripped');
      final dated = item(id: 'dated', dateTaken: DateTime(2025, 6, 1));

      expect(service.pickBest(<MediaItem>[stripped, dated])?.id, 'dated');
    });

    test('prefers a copy that kept its EXIF', () {
      final taken = DateTime(2025, 6, 1);
      final bare = item(id: 'bare', dateTaken: taken);
      final withExif = item(
        id: 'withExif',
        dateTaken: taken,
        exif: const ExifData(make: 'Nikon'),
      );

      expect(service.pickBest(<MediaItem>[bare, withExif])?.id, 'withExif');
    });

    test('prefers a favourite when nothing else separates them', () {
      final plain = item(id: 'plain');
      final starred = item(id: 'starred', favorite: true);

      expect(service.pickBest(<MediaItem>[plain, starred])?.id, 'starred');
    });

    test('falls back to the older file', () {
      // The first copy made is most likely the original.
      final older = item(id: 'older', added: DateTime(2024, 1, 1));
      final newer = item(id: 'newer', added: DateTime(2026, 1, 1));

      expect(service.pickBest(<MediaItem>[newer, older])?.id, 'older');
    });

    test('pixels beat a bigger file, in that order', () {
      // Resolution is checked before file size, so a large low-resolution
      // file does not win over a smaller high-resolution one.
      final bigFileSmallImage = item(
        id: 'bigFile',
        size: 9000,
        width: 100,
        height: 100,
      );
      final smallFileBigImage = item(
        id: 'bigImage',
        size: 1000,
        width: 800,
        height: 600,
      );

      expect(
        service.pickBest(<MediaItem>[bigFileSmallImage, smallFileBigImage])?.id,
        'bigImage',
      );
    });

    test('an unknown size counts as no pixels rather than winning', () {
      final unknown = item(id: 'unknown', width: null, height: null);
      final known = item(id: 'known', width: 50, height: 50);

      expect(service.pickBest(<MediaItem>[unknown, known])?.id, 'known');
    });

    test('ranking is stable and complete', () {
      final items = <MediaItem>[
        item(id: 'c', width: 100, height: 100),
        item(id: 'a', width: 300, height: 300),
        item(id: 'b', width: 200, height: 200),
      ];

      final ranked = service.rank(items);

      expect(ranked.map((i) => i.id).toList(), <String>['a', 'b', 'c']);
      // Ranking must not lose or duplicate a candidate.
      expect(ranked.length, items.length);
    });

    test('two copies alike in every way order by id, not at random', () {
      final first = service.rank(<MediaItem>[item(id: 'z'), item(id: 'a')]);
      final second = service.rank(<MediaItem>[item(id: 'a'), item(id: 'z')]);

      expect(first.map((i) => i.id).toList(), <String>['a', 'z']);
      expect(second.map((i) => i.id).toList(), first.map((i) => i.id).toList());
    });

    test('an empty group has no best copy', () {
      expect(service.pickBest(const <MediaItem>[]), isNull);
    });
  });
}
