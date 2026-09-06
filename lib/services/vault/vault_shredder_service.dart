import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';

/// Overwrites a file's bytes before deleting it.
///
/// An ordinary delete only unlinks the name. The bytes stay on the device
/// until something else happens to reuse that space, which is what makes
/// undelete tools work. This writes over the payload first — a zero pass, then
/// alternating random and zero passes — syncing each one so the writes reach
/// the device rather than sitting in a buffer that is discarded when the file
/// is unlinked.
///
/// **What this does not promise.** On flash storage the controller may put
/// each pass in a fresh block and leave the earlier contents in an area no
/// file API can reach. This defeats undelete tools and casual recovery. It is
/// not a guarantee against someone with the hardware in a laboratory, and the
/// UI does not claim otherwise.
class VaultShredderService {
  final VaultChannel _channel;
  final Random _random;

  /// Whether to fall back to a Dart overwrite when Android has nothing to say.
  ///
  /// True in tests and on a host machine, where there is no native side. On a
  /// real device the native pass is the one that runs.
  final bool allowDartFallback;

  VaultShredderService({
    required VaultChannel channel,
    Random? random,
    this.allowDartFallback = true,
  }) : _channel = channel,
       _random = random ?? Random.secure();

  /// Shreds the file at [path], returning whether it is gone afterwards.
  ///
  /// A file that was never there counts as shredded: the caller wanted it
  /// gone, and it is.
  Future<bool> shred(String path, {int? passes}) async {
    if (path.isEmpty) return true;

    final file = File(path);
    if (!await file.exists()) return true;

    final passCount = (passes ?? AppConstants.vaultDefaultShredPasses).clamp(
      AppConstants.vaultMinShredPasses,
      AppConstants.vaultMaxShredPasses,
    );

    final shredded = await _channel.shredFile(path: path, passes: passCount);
    if (shredded) return true;

    if (!allowDartFallback) return false;
    return _shredInDart(file, passCount);
  }

  /// Shreds several files, returning how many are gone afterwards.
  Future<int> shredAll(Iterable<String> paths, {int? passes}) async {
    var count = 0;
    for (final path in paths) {
      // One unshreddable file must not stop the rest; a partly swept vault
      // directory is worse than a fully swept one.
      if (await shred(path, passes: passes)) count++;
    }
    return count;
  }

  /// The Dart overwrite, used when the native side is unavailable.
  ///
  /// Weaker than the native one, because Dart cannot force a sync down to the
  /// device. It still beats a plain delete, and it is what makes the shredder
  /// testable on a host machine.
  Future<bool> _shredInDart(File file, int passes) async {
    try {
      final length = await file.length();
      if (length > 0) {
        final handle = await file.open(mode: FileMode.writeOnlyAppend);
        try {
          final block = Uint8List(AppConstants.vaultShredBlockBytes);
          for (var pass = 0; pass < passes; pass++) {
            if (pass.isEven) {
              block.fillRange(0, block.length, 0);
            } else {
              for (var i = 0; i < block.length; i++) {
                block[i] = _random.nextInt(256);
              }
            }
            await handle.setPosition(0);
            var remaining = length;
            while (remaining > 0) {
              final chunk = remaining < block.length ? remaining : block.length;
              await handle.writeFrom(block, 0, chunk);
              remaining -= chunk;
            }
            await handle.flush();
          }
          await handle.truncate(0);
          await handle.flush();
        } finally {
          await handle.close();
        }
      }
    } catch (_) {
      // An overwrite that failed part way still leaves a file that has to go.
      // Deleting it is strictly better than keeping it.
    }

    try {
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
