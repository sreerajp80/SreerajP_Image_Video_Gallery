import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/viewer/wallpaper_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

MediaItem item({
  MediaType type = MediaType.image,
  String? uri = 'content://media/external/images/media/42',
  bool isTrash = false,
  bool isVaulted = false,
}) {
  return MediaItem(
    id: '42',
    path: '/storage/emulated/0/DCIM/a.jpg',
    uri: uri,
    displayName: 'a.jpg',
    mediaType: type,
    mimeType: 'image/jpeg',
    size: 10,
    dateAdded: DateTime(2026),
    dateModified: DateTime(2026),
    isTrash: isTrash,
    isVaulted: isVaulted,
  );
}

void main() {
  test('an ordinary photo or GIF in MediaStore can be set', () {
    expect(canSetAsWallpaper(item()), isTrue);
    expect(canSetAsWallpaper(item(type: MediaType.gif)), isTrue);
  });

  test('videos, RAW and SVG files cannot', () {
    expect(canSetAsWallpaper(item(type: MediaType.video)), isFalse);
    expect(canSetAsWallpaper(item(type: MediaType.rawImage)), isFalse);
    expect(canSetAsWallpaper(item(type: MediaType.svg)), isFalse);
  });

  test('trashed or vaulted items cannot', () {
    expect(canSetAsWallpaper(item(isTrash: true)), isFalse);
    expect(canSetAsWallpaper(item(isVaulted: true)), isFalse);
  });

  test('only a MediaStore address is accepted', () {
    expect(canSetAsWallpaper(item(uri: null)), isFalse);
    expect(canSetAsWallpaper(item(uri: '')), isFalse);
    expect(
      canSetAsWallpaper(item(uri: 'file:///storage/emulated/0/a.jpg')),
      isFalse,
    );
    // Another app's provider, or this app's own file provider.
    expect(
      canSetAsWallpaper(item(uri: 'content://com.other.app/photos/1')),
      isFalse,
    );
    expect(
      canSetAsWallpaper(
        item(uri: 'content://in.sreerajp.imgvidgal.fileprovider/x.jpg'),
      ),
      isFalse,
    );
  });
}
