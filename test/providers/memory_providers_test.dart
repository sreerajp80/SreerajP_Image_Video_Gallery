import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/memory_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_service.dart';

void main() {
  final item = MediaItem(
    id: 'm1',
    path: '/storage/DCIM/Camera/M1.jpg',
    displayName: 'M1.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 1000,
    dateAdded: DateTime(2026, 9),
    dateModified: DateTime(2026, 9),
  );

  test('drops cached thumbnails so they are built again', () async {
    var galleryBuilds = 0;
    var vaultBuilds = 0;
    final container = ProviderContainer(
      overrides: <Override>[
        // Still loading: the relief must cope with no service yet.
        thumbnailServiceProvider.overrideWith(
          (ref) => Completer<ThumbnailService>().future,
        ),
        thumbnailProvider.overrideWith((ref, item) async {
          galleryBuilds++;
          return Uint8List(0);
        }),
        vaultThumbnailProvider.overrideWith((ref, id) async {
          vaultBuilds++;
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(thumbnailProvider(item), (_, _) {});
    container.listen(vaultThumbnailProvider('v1'), (_, _) {});
    await container.read(thumbnailProvider(item).future);
    await container.read(vaultThumbnailProvider('v1').future);

    container.read(memoryReliefProvider)();
    await container.read(thumbnailProvider(item).future);
    await container.read(vaultThumbnailProvider('v1').future);

    expect(galleryBuilds, 2);
    expect(vaultBuilds, 2);
  });
}
