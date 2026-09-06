import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';

void main() {
  group('Album Domain Model', () {
    final now = DateTime(2026, 8, 29, 9, 0, 0);
    final testAlbum = Album(
      id: 'album_001',
      name: 'Kerala Trip',
      albumType: AlbumType.virtualAlbum,
      relativeFolderPath: null,
      coverMediaId: 'media_001',
      coverPath: '/storage/emulated/0/DCIM/Camera/IMG_001.jpg',
      itemCount: 42,
      dateCreated: now,
      dateModified: now,
      isPinned: true,
      sortOrder: 1,
    );

    test('supports value equality', () {
      final duplicate = Album(
        id: 'album_001',
        name: 'Kerala Trip',
        albumType: AlbumType.virtualAlbum,
        relativeFolderPath: null,
        coverMediaId: 'media_001',
        coverPath: '/storage/emulated/0/DCIM/Camera/IMG_001.jpg',
        itemCount: 42,
        dateCreated: now,
        dateModified: now,
        isPinned: true,
        sortOrder: 1,
      );

      expect(testAlbum, equals(duplicate));
    });

    test('copyWith creates modified instance correctly', () {
      final modified = testAlbum.copyWith(name: 'Kerala 2026', itemCount: 45);
      expect(modified.name, 'Kerala 2026');
      expect(modified.itemCount, 45);
      expect(modified.isPinned, isTrue);
    });

    test('serialization roundtrip via toMap and fromMap', () {
      final map = testAlbum.toMap();
      final fromMap = Album.fromMap(map);

      expect(fromMap.id, testAlbum.id);
      expect(fromMap.name, testAlbum.name);
      expect(fromMap.albumType, testAlbum.albumType);
      expect(fromMap.itemCount, testAlbum.itemCount);
      expect(fromMap.isPinned, testAlbum.isPinned);
    });

    test('isSmartAlbum identifies dynamic smart album types', () {
      expect(AlbumType.smartFavorites.isSmartAlbum, isTrue);
      expect(AlbumType.smartVideos.isSmartAlbum, isTrue);
      expect(AlbumType.virtualAlbum.isSmartAlbum, isFalse);
      expect(AlbumType.physicalFolder.isSmartAlbum, isFalse);
    });

    test('isSmartAlbum covers the panorama and recent types too', () {
      expect(AlbumType.smartPanoramas.isSmartAlbum, isTrue);
      expect(AlbumType.smartRecentlyAdded.isSmartAlbum, isTrue);
      expect(AlbumType.smartGifs.isSmartAlbum, isTrue);
      expect(AlbumType.smartRaw.isSmartAlbum, isTrue);
      expect(AlbumType.smartTrash.isSmartAlbum, isTrue);
    });

    test('fromString reads the new types back', () {
      expect(AlbumType.fromString('smartPanoramas'), AlbumType.smartPanoramas);
      expect(
        AlbumType.fromString('smartRecentlyAdded'),
        AlbumType.smartRecentlyAdded,
      );
    });

    test('fromString falls back rather than throwing on an unknown value', () {
      expect(AlbumType.fromString('somethingElse'), AlbumType.virtualAlbum);
      expect(AlbumType.fromString(''), AlbumType.virtualAlbum);
    });
  });
}
