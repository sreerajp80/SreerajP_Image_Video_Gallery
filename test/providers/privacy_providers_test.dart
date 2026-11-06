import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/privacy_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/privacy_export_service.dart';

/// Answers only the one call these providers make, and counts it.
class _FakeRepository implements MediaRepository {
  int reads = 0;

  @override
  Future<Uint8List?> readOriginalBytes(
    MediaItem item, {
    int maxBytes = 0,
  }) async {
    reads++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item(MediaType type) => MediaItem(
  id: 'p1',
  path: '/storage/DCIM/Camera/P1.jpg',
  displayName: 'P1.jpg',
  mediaType: type,
  mimeType: type == MediaType.image ? 'image/jpeg' : 'video/mp4',
  size: 1000,
  dateAdded: DateTime(2026, 9),
  dateModified: DateTime(2026, 9),
);

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: <Override>[
        mediaRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('the export service is built from the other providers', () {
    expect(
      container.read(privacyExportServiceProvider),
      isA<PrivacyExportService>(),
    );
  });

  test('a video gets empty forensic data without reading the file', () async {
    final item = _item(MediaType.video);
    container.listen(mediaForensicProvider(item), (_, _) {});

    final metadata = await container.read(mediaForensicProvider(item).future);

    expect(metadata.cropFactor, isNull);
    expect(repository.reads, 0);
  });

  test('an image that cannot be read gets empty forensic data', () async {
    final item = _item(MediaType.image);
    container.listen(mediaForensicProvider(item), (_, _) {});

    final metadata = await container.read(mediaForensicProvider(item).future);

    expect(metadata.cropFactor, isNull);
    expect(repository.reads, 1);
  });
}
