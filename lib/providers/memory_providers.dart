import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';

/// What to free when the device is low on memory.
///
/// Thumbnail bytes are held in the thumbnail service's own RAM cache and in
/// the `thumbnailProvider` entries of tiles now on screen (the provider is
/// auto-disposed, so off-screen tiles hold nothing). Both are dropped; tiles
/// still on screen load again from the disk cache. Decrypted vault previews
/// are dropped too.
final memoryReliefProvider = Provider<VoidCallback>((ref) {
  return () {
    ref.read(thumbnailServiceProvider).value?.clearMemoryCache();
    ref.invalidate(thumbnailProvider);
    ref.invalidate(vaultThumbnailProvider);
  };
});
