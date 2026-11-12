import 'dart:math' as math;

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/send_plan.dart';

/// Works out how much one Wi-Fi send may carry.
///
/// Pure, so every limit can be tested without a phone. Three limits apply,
/// and the first one reached stops the send:
///
/// 1. **The send cap** ([AppConstants.syncSendCapBytes]), which keeps each
///    send short so an interruption costs little.
/// 2. **The receiver's free space**, minus a reserve that is never used.
/// 3. **The file count** ([AppConstants.syncMaxManifestEntries]).
///
/// The receiving phone needs room for two copies of the file in flight: the
/// checked staging copy and the one written into the gallery. The staging
/// copy is deleted straight after, so only one file's worth is extra.
class SendLimitRules {
  const SendLimitRules._();

  /// Free space the receiver always keeps, in bytes.
  ///
  /// The larger of a per cent of its free space and a fixed minimum, so a
  /// nearly full phone is never filled to the last byte.
  static int reserveFor(int freeBytes) {
    final percent = freeBytes * AppConstants.syncFreeSpaceMarginPercent ~/ 100;
    return math.max(percent, AppConstants.syncFreeSpaceMinReserveBytes);
  }

  /// Whether one file of [fileBytes] fits in [freeBytes] right now.
  ///
  /// Counts the staging copy as well as the final one.
  static bool fitsOneFile({required int freeBytes, required int fileBytes}) {
    return freeBytes - reserveFor(freeBytes) - 2 * fileBytes >= 0;
  }

  /// Picks what one send carries from [candidates], in their order.
  ///
  /// [candidates] are the picked files that were not sent to this phone
  /// before (or, in a manual send, all of them). [alreadySentCount] and
  /// [resendCount] are only carried into the result for the screen.
  /// [freeBytes] is the receiver's free space, or null when it did not say.
  ///
  /// The order is kept: files are taken one after another until the next one
  /// does not fit, and the rest wait. Skipping a big file to squeeze smaller
  /// ones in would make "send the rest" jump around. One exception: the very
  /// first file may be larger than the cap, as long as it fits the free
  /// space, or a long video could never be sent at all.
  static SendPlan plan({
    required List<MediaItem> candidates,
    required int? freeBytes,
    int alreadySentCount = 0,
    int resendCount = 0,
    int capBytes = AppConstants.syncSendCapBytes,
    int maxFiles = AppConstants.syncMaxManifestEntries,
  }) {
    final room = freeBytes == null
        ? null
        : math.max(0, freeBytes - reserveFor(freeBytes));

    final toSend = <MediaItem>[];
    var used = 0;
    var limit = SendLimit.none;
    var stopAt = candidates.length;

    for (var i = 0; i < candidates.length; i++) {
      final size = math.max(0, candidates[i].size);

      if (toSend.length >= maxFiles) {
        limit = SendLimit.count;
        stopAt = i;
        break;
      }
      // Two copies of the file in flight: staging and final.
      if (room != null && used + 2 * size > room) {
        limit = SendLimit.space;
        stopAt = i;
        break;
      }
      if (used + size > capBytes && toSend.isNotEmpty) {
        limit = SendLimit.cap;
        stopAt = i;
        break;
      }

      toSend.add(candidates[i]);
      used += size;
    }

    var leftBytes = 0;
    for (var i = stopAt; i < candidates.length; i++) {
      leftBytes += math.max(0, candidates[i].size);
    }

    return SendPlan(
      toSend: List<MediaItem>.unmodifiable(toSend),
      sendBytes: used,
      leftCount: candidates.length - stopAt,
      leftBytes: leftBytes,
      alreadySentCount: alreadySentCount,
      resendCount: resendCount,
      limitedBy: limit,
    );
  }
}
