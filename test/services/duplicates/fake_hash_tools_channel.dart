import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/services/duplicates/hash_tools_channel.dart';

/// In-memory [HashToolsChannel] used by tests instead of a real device.
class FakeHashToolsChannel implements HashToolsChannel {
  /// Digest returned per uri. A missing uri stands for an unreadable file.
  final Map<String, String> digests;

  /// Grayscale grid returned per uri, keyed the same way.
  final Map<String, Uint8List> grids;

  /// Uris the fake should throw on, standing in for a platform failure.
  final Set<String> throwingUris;

  int sha256CallCount = 0;
  int grayscaleCallCount = 0;

  FakeHashToolsChannel({
    Map<String, String>? digests,
    Map<String, Uint8List>? grids,
    Set<String>? throwingUris,
  }) : digests = digests ?? <String, String>{},
       grids = grids ?? <String, Uint8List>{},
       throwingUris = throwingUris ?? <String>{};

  @override
  Future<String?> sha256(String uri) async {
    sha256CallCount++;
    if (throwingUris.contains(uri)) {
      throw StateError('platform failed for $uri');
    }
    return digests[uri];
  }

  @override
  Future<Uint8List?> grayscale(String uri, {required int size}) async {
    grayscaleCallCount++;
    if (throwingUris.contains(uri)) {
      throw StateError('platform failed for $uri');
    }
    final grid = grids[uri];
    if (grid == null) return null;
    if (grid.length != size * size) return null;
    return grid;
  }
}

/// A flat grayscale grid, handy when the exact hash does not matter.
Uint8List flatGrid(int shade, {int size = 32}) =>
    Uint8List.fromList(List<int>.filled(size * size, shade));

/// A grid with real detail, so its hash is not the all-zero flat one.
Uint8List texturedGrid(int seed, {int size = 32}) {
  final out = Uint8List(size * size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      out[y * size + x] = ((x * seed + y * y * 3) % 256);
    }
  }
  return out;
}
