import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/smart_album_service.dart';

MediaItem _item({
  String id = 'm1',
  MediaType mediaType = MediaType.image,
  int? width,
  int? height,
  DateTime? dateAdded,
}) {
  final stamp = dateAdded ?? DateTime(2026, 8, 30);
  return MediaItem(
    id: id,
    path: '/DCIM/Camera/$id.jpg',
    displayName: '$id.jpg',
    mediaType: mediaType,
    mimeType: 'image/jpeg',
    size: 1024,
    dateAdded: stamp,
    dateModified: stamp,
    width: width,
    height: height,
  );
}

void main() {
  group('all', () {
    test('builds the seven smart albums in a stable order', () {
      final albums = SmartAlbumService.all();
      expect(albums.length, 7);
      expect(albums.map((a) => a.albumType).toList(), <AlbumType>[
        AlbumType.smartFavorites,
        AlbumType.smartVideos,
        AlbumType.smartGifs,
        AlbumType.smartRaw,
        AlbumType.smartPanoramas,
        AlbumType.smartRecentlyAdded,
        AlbumType.smartTrash,
      ]);
    });

    test('gives every album a distinct route key', () {
      final keys = SmartAlbumService.all().map((a) => a.key).toSet();
      expect(keys.length, 7);
    });
  });

  group('route keys', () {
    test('round trips every smart album', () {
      for (final album in SmartAlbumService.all()) {
        final resolved = SmartAlbumService.fromKey(album.key);
        expect(resolved, isNotNull);
        expect(resolved!.albumType, album.albumType);
      }
    });

    test('keyFor agrees with the built album', () {
      for (final album in SmartAlbumService.all()) {
        expect(SmartAlbumService.keyFor(album.albumType), album.key);
      }
    });

    test('returns null for an unknown key rather than throwing', () {
      expect(SmartAlbumService.fromKey('nonsense'), isNull);
      expect(SmartAlbumService.fromKey(''), isNull);
    });

    test('returns null for a type that is not a smart album', () {
      expect(SmartAlbumService.keyFor(AlbumType.virtualAlbum), isNull);
      expect(SmartAlbumService.keyFor(AlbumType.physicalFolder), isNull);
    });
  });

  group('filters', () {
    test('favorites asks only for starred items', () {
      final album = SmartAlbumService.forType(AlbumType.smartFavorites);
      expect(album.filter.isFavoriteOnly, isTrue);
      expect(album.needsPostFilter, isFalse);
    });

    test('videos asks only for the video type', () {
      final album = SmartAlbumService.forType(AlbumType.smartVideos);
      expect(album.filter.mediaTypes, <MediaType>{MediaType.video});
    });

    test('gifs asks only for the gif type', () {
      final album = SmartAlbumService.forType(AlbumType.smartGifs);
      expect(album.filter.mediaTypes, <MediaType>{MediaType.gif});
    });

    test('raw asks only for the raw type', () {
      final album = SmartAlbumService.forType(AlbumType.smartRaw);
      expect(album.filter.mediaTypes, <MediaType>{MediaType.rawImage});
    });

    test('panoramas narrows to stills and needs a second pass', () {
      final album = SmartAlbumService.forType(AlbumType.smartPanoramas);
      expect(album.filter.mediaTypes, <MediaType>{
        MediaType.image,
        MediaType.rawImage,
      });
      expect(album.needsPostFilter, isTrue);
    });

    test(
      'recently added sorts by when it was added and needs a second pass',
      () {
        final album = SmartAlbumService.forType(AlbumType.smartRecentlyAdded);
        expect(album.needsPostFilter, isTrue);
      },
    );

    test('throws for a type that is not a smart album', () {
      expect(
        () => SmartAlbumService.forType(AlbumType.virtualAlbum),
        throwsArgumentError,
      );
    });
  });

  group('isPanorama', () {
    test('accepts a wide photo past both thresholds', () {
      expect(
        SmartAlbumService.isPanorama(_item(width: 8000, height: 2000)),
        isTrue,
      );
    });

    test('accepts a tall photo too', () {
      expect(
        SmartAlbumService.isPanorama(_item(width: 2000, height: 8000)),
        isTrue,
      );
    });

    test('accepts exactly the ratio and pixel floor', () {
      // 2000 wide is the floor, and 2000 / 800 is exactly 2.5.
      expect(
        SmartAlbumService.isPanorama(_item(width: 2000, height: 800)),
        isTrue,
      );
    });

    test('refuses a wide photo that is too small', () {
      // The ratio passes but the longest side is one pixel short.
      expect(
        SmartAlbumService.isPanorama(_item(width: 1999, height: 700)),
        isFalse,
      );
    });

    test('refuses a big photo that is not wide enough', () {
      expect(
        SmartAlbumService.isPanorama(_item(width: 4000, height: 3000)),
        isFalse,
      );
    });

    test('refuses an item with no recorded dimensions', () {
      expect(SmartAlbumService.isPanorama(_item()), isFalse);
      expect(SmartAlbumService.isPanorama(_item(width: 4000)), isFalse);
      expect(SmartAlbumService.isPanorama(_item(height: 4000)), isFalse);
    });

    test('refuses zero or negative dimensions instead of dividing by zero', () {
      expect(
        SmartAlbumService.isPanorama(_item(width: 4000, height: 0)),
        isFalse,
      );
      expect(
        SmartAlbumService.isPanorama(_item(width: -4000, height: 100)),
        isFalse,
      );
    });
  });

  group('isRecentlyAdded', () {
    final now = DateTime(2026, 8, 30, 12);

    test('accepts something added today', () {
      expect(
        SmartAlbumService.isRecentlyAdded(_item(dateAdded: now), now: now),
        isTrue,
      );
    });

    test('accepts the oldest moment still inside the window', () {
      final edge = now.subtract(SmartAlbumService.recentWindow);
      expect(
        SmartAlbumService.isRecentlyAdded(_item(dateAdded: edge), now: now),
        isTrue,
      );
    });

    test('refuses one second before the window opens', () {
      final outside = now
          .subtract(SmartAlbumService.recentWindow)
          .subtract(const Duration(seconds: 1));
      expect(
        SmartAlbumService.isRecentlyAdded(_item(dateAdded: outside), now: now),
        isFalse,
      );
    });
  });

  group('matches', () {
    final now = DateTime(2026, 8, 30, 12);

    test('applies the panorama rule', () {
      final album = SmartAlbumService.forType(AlbumType.smartPanoramas);
      expect(
        SmartAlbumService.matches(
          album,
          _item(width: 8000, height: 2000),
          now: now,
        ),
        isTrue,
      );
      expect(
        SmartAlbumService.matches(
          album,
          _item(width: 4000, height: 3000),
          now: now,
        ),
        isFalse,
      );
    });

    test('applies the recently added rule', () {
      final album = SmartAlbumService.forType(AlbumType.smartRecentlyAdded);
      expect(
        SmartAlbumService.matches(album, _item(dateAdded: now), now: now),
        isTrue,
      );
      expect(
        SmartAlbumService.matches(
          album,
          _item(dateAdded: DateTime(2020)),
          now: now,
        ),
        isFalse,
      );
    });

    test(
      'passes everything for rules the database already applied in full',
      () {
        final album = SmartAlbumService.forType(AlbumType.smartFavorites);
        expect(SmartAlbumService.matches(album, _item(), now: now), isTrue);
      },
    );
  });
}
