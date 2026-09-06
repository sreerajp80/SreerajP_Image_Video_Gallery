import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

void main() {
  group('MediaItem Domain Model', () {
    final itemDate = DateTime(2026, 8, 29, 9, 30, 0);
    final testItem = MediaItem(
      id: 'media_001',
      path: '/storage/emulated/0/DCIM/Camera/IMG_20260829_093000.jpg',
      uri: 'content://media/external/images/media/101',
      displayName: 'IMG_20260829_093000.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 4194304,
      dateAdded: itemDate,
      dateModified: itemDate,
      dateTaken: itemDate,
      durationMs: null,
      width: 4000,
      height: 3000,
      orientation: 0,
      isFavorite: true,
      isVaulted: false,
      isTrash: false,
      exifData: const ExifData(make: 'Google', model: 'Pixel 8 Pro'),
      tags: const ['Nature', 'Vacation'],
      userNotes: 'Morning hike photograph',
      sha256Hash: 'a1b2c3d4e5',
      pHash: '0x1234567890abcdef',
      latitude: 10.0261,
      longitude: 76.3125,
      address: 'Kochi, Kerala',
    );

    test('supports value equality', () {
      final duplicate = MediaItem(
        id: 'media_001',
        path: '/storage/emulated/0/DCIM/Camera/IMG_20260829_093000.jpg',
        uri: 'content://media/external/images/media/101',
        displayName: 'IMG_20260829_093000.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 4194304,
        dateAdded: itemDate,
        dateModified: itemDate,
        dateTaken: itemDate,
        durationMs: null,
        width: 4000,
        height: 3000,
        orientation: 0,
        isFavorite: true,
        isVaulted: false,
        isTrash: false,
        exifData: const ExifData(make: 'Google', model: 'Pixel 8 Pro'),
        tags: const ['Nature', 'Vacation'],
        userNotes: 'Morning hike photograph',
        sha256Hash: 'a1b2c3d4e5',
        pHash: '0x1234567890abcdef',
        latitude: 10.0261,
        longitude: 76.3125,
        address: 'Kochi, Kerala',
      );

      expect(testItem, equals(duplicate));
    });

    test('copyWith works properly', () {
      final modified = testItem.copyWith(isFavorite: false, isTrash: true);
      expect(modified.isFavorite, isFalse);
      expect(modified.isTrash, isTrue);
      expect(modified.id, testItem.id);
    });

    test('serialization roundtrip via toMap and fromMap', () {
      final map = testItem.toMap();
      final fromMap = MediaItem.fromMap(map, tags: testItem.tags);

      expect(fromMap.id, testItem.id);
      expect(fromMap.displayName, testItem.displayName);
      expect(fromMap.mediaType, testItem.mediaType);
      expect(fromMap.mimeType, testItem.mimeType);
      expect(fromMap.size, testItem.size);
      expect(fromMap.isFavorite, testItem.isFavorite);
      expect(fromMap.tags, equals(testItem.tags));
      expect(fromMap.exifData?.model, 'Pixel 8 Pro');
    });

    test('effectiveDate prioritizes dateTaken over dateModified', () {
      final modifiedDate = DateTime(2026, 8, 28);
      final itemWithoutTaken = MediaItem(
        id: 'media_002',
        path: '/storage/emulated/0/DCIM/Camera/IMG_002.jpg',
        displayName: 'IMG_002.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 1000,
        dateAdded: modifiedDate,
        dateModified: modifiedDate,
        dateTaken: null,
      );
      expect(itemWithoutTaken.effectiveDate, equals(modifiedDate));
      expect(testItem.effectiveDate, equals(itemDate));
    });
  });
}
