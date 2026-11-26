import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:path/path.dart' as p;

import '../media/fake_media_store_channel.dart';
import '../video/fake_video_tools_channel.dart';

MediaItem _item({
  String? uri,
  String path = '',
  MediaType type = MediaType.image,
  int size = 100,
}) => MediaItem(
  id: 'm',
  path: path,
  uri: uri,
  displayName: 'a.jpg',
  mediaType: type,
  mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
  size: size,
  dateAdded: DateTime(2026, 11, 2),
  dateModified: DateTime(2026, 11, 2),
);

void main() {
  late FakeMediaStoreChannel mediaStore;
  late FakeVideoToolsChannel videoTools;
  late VaultPreviewService service;

  setUp(() {
    mediaStore = FakeMediaStoreChannel(
      nativeThumbnail: Uint8List.fromList(<int>[0xFF, 0xD8, 1]),
    );
    videoTools = FakeVideoToolsChannel(
      frameBytes: Uint8List.fromList(<int>[9, 9]),
    );
    service = VaultPreviewService(
      videoTools: videoTools,
      mediaStore: mediaStore,
    );
  });

  test('a gallery photo gets its preview from MediaStore, by URI', () async {
    // The path is one Android 10 would refuse; it must not be needed.
    final bytes = await service.buildPreview(
      _item(
        uri: 'content://media/external/images/media/7',
        path: '/storage/emulated/0/DCIM/a.jpg',
      ),
    );

    expect(bytes, <int>[0xFF, 0xD8, 1]);
    expect(mediaStore.thumbnailUris, <String>[
      'content://media/external/images/media/7',
    ]);
  });

  test('a gallery video does too, without reading the file', () async {
    final bytes = await service.buildPreview(
      _item(
        uri: 'content://media/external/video/media/8',
        path: '/storage/emulated/0/DCIM/v.mp4',
        type: MediaType.video,
      ),
    );

    expect(bytes, <int>[0xFF, 0xD8, 1]);
    expect(videoTools.requestedPositions, isEmpty);
  });

  test('no MediaStore thumbnail falls back to the path route', () async {
    mediaStore.nativeThumbnail = null;

    final bytes = await service.buildPreview(
      _item(
        uri: 'content://media/external/video/media/8',
        path: '/data/staged/v.mp4',
        type: MediaType.video,
      ),
    );

    expect(bytes, <int>[9, 9]);
  });

  test('a staged file with no URI is decoded from its path, shrunk', () async {
    final dir = await Directory.systemTemp.createTemp('preview_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File(p.join(dir.path, 'big.jpg'));
    await file.writeAsBytes(img.encodeJpg(img.Image(width: 1000, height: 500)));

    final bytes = await service.buildPreview(
      _item(path: file.path, size: await file.length()),
    );

    final decoded = img.decodeJpg(bytes!)!;
    expect(decoded.width, AppConstants.vaultThumbnailSize);
    expect(mediaStore.thumbnailUris, isEmpty);
  });

  test('a failure gives null, never an error', () async {
    mediaStore.throwOnThumbnail = true;

    final bytes = await service.buildPreview(
      _item(uri: 'content://media/external/images/media/7', path: '/nope.jpg'),
    );

    expect(bytes, isNull);
  });
}
