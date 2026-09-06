import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

MediaItem _cover(String id) {
  final now = DateTime(2026, 8, 30);
  return MediaItem(
    id: id,
    path: '/DCIM/Camera/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: now,
    dateModified: now,
  );
}

void main() {
  const base = AlbumSummary(
    id: 'a1',
    name: 'Holiday',
    albumType: AlbumType.virtualAlbum,
    itemCount: 3,
  );

  group('defaults', () {
    test('an album with no items reports itself empty', () {
      const summary = AlbumSummary(
        id: 'a1',
        name: 'Holiday',
        albumType: AlbumType.virtualAlbum,
      );
      expect(summary.itemCount, 0);
      expect(summary.isEmpty, isTrue);
      expect(summary.coverItem, isNull);
      expect(summary.folderPath, isNull);
    });

    test('an album with items is not empty', () {
      expect(base.isEmpty, isFalse);
    });
  });

  group('needsLocalizedName', () {
    test('is true for a smart album', () {
      for (final type in <AlbumType>[
        AlbumType.smartFavorites,
        AlbumType.smartVideos,
        AlbumType.smartGifs,
        AlbumType.smartRaw,
        AlbumType.smartPanoramas,
        AlbumType.smartRecentlyAdded,
      ]) {
        final summary = AlbumSummary(id: 'x', name: 'x', albumType: type);
        expect(summary.needsLocalizedName, isTrue, reason: type.name);
      }
    });

    test('is false for a user album and a device folder', () {
      expect(base.needsLocalizedName, isFalse);
      const folder = AlbumSummary(
        id: '/DCIM/Camera',
        name: 'Camera',
        albumType: AlbumType.physicalFolder,
      );
      expect(folder.needsLocalizedName, isFalse);
    });
  });

  group('copyWith', () {
    test('changes only what it is given', () {
      final changed = base.copyWith(name: 'Vacation');
      expect(changed.name, 'Vacation');
      expect(changed.id, base.id);
      expect(changed.itemCount, base.itemCount);
    });

    test('keeps the existing cover when none is passed', () {
      final withCover = base.copyWith(coverItem: _cover('m1'));
      expect(withCover.copyWith(itemCount: 9).coverItem?.id, 'm1');
    });

    test('clears the cover on request', () {
      final withCover = base.copyWith(coverItem: _cover('m1'));
      expect(withCover.copyWith(clearCover: true).coverItem, isNull);
    });
  });

  group('equality', () {
    test('two summaries with the same values are equal', () {
      const other = AlbumSummary(
        id: 'a1',
        name: 'Holiday',
        albumType: AlbumType.virtualAlbum,
        itemCount: 3,
      );
      expect(base, other);
      expect(base.hashCode, other.hashCode);
    });

    test('a different count makes them unequal', () {
      expect(base, isNot(base.copyWith(itemCount: 4)));
    });

    test('a different cover makes them unequal', () {
      expect(base, isNot(base.copyWith(coverItem: _cover('m1'))));
    });
  });
}
