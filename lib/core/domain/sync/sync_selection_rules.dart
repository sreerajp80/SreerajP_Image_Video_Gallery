import 'package:in_sreerajp_imgvidgal/core/domain/sync/send_limit_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/send_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';

/// Turns the ticked folders and albums into one send.
///
/// Pure, so it can be tested without a screen or a database.
class SyncSelectionRules {
  const SyncSelectionRules._();

  /// The plan for the next send.
  ///
  /// Files are taken source by source, in the order the sources are listed,
  /// and a file in two ticked sources is counted once. Then
  /// [SendLimitRules] decides how many fit.
  ///
  /// [allowResend] is true for a manual send: the user picked these files on
  /// purpose, so files sent to this phone before go again and are only
  /// counted for a warning. It is false for Device Sync: files already sent
  /// are left out, so a retry after a Wi-Fi drop sends only what is missing.
  ///
  /// [sentThisSession] holds the ids sent since pairing. With [allowResend],
  /// those are not offered again, or "send the rest" would repeat them.
  static SendPlan plan({
    required List<SyncSource> sources,
    required Set<String> selectedKeys,
    required Map<String, SyncMark> marks,
    required int? freeBytes,
    bool allowResend = false,
    Set<String> sentThisSession = const <String>{},
  }) {
    final seen = <String>{};
    final picked = <MediaItem>[];
    for (final source in sources) {
      if (!selectedKeys.contains(source.key)) continue;
      for (final item in source.items) {
        if (seen.add(item.id)) picked.add(item);
      }
    }

    if (allowResend) {
      final candidates = <MediaItem>[];
      var resend = 0;
      for (final item in picked) {
        if (sentThisSession.contains(item.id)) continue;
        candidates.add(item);
        final mark = marks[item.id];
        if (mark != null && mark.stillMatches(item)) resend++;
      }
      return SendLimitRules.plan(
        candidates: candidates,
        freeBytes: freeBytes,
        resendCount: resend,
      );
    }

    final split = splitBySent(picked, marks);
    return SendLimitRules.plan(
      candidates: split.unsent,
      freeBytes: freeBytes,
      alreadySentCount: split.alreadySent,
    );
  }

  /// Whether the send button should say "Send the rest" rather than "Send".
  ///
  /// Only for a follow-up send whose files are all new to this pairing
  /// ([triedIds] holds every file already put in a send). A retry of a file
  /// that failed is just "Send".
  static bool isRest({
    required int batchCount,
    required List<MediaItem> toSend,
    required Set<String> triedIds,
  }) =>
      batchCount > 0 &&
      toSend.isNotEmpty &&
      toSend.every((item) => !triedIds.contains(item.id));

  /// Whether a send should end the pairing by itself once it is over.
  ///
  /// [finishWhenDone] is set for a quick send with nothing held back, where
  /// nothing is left to pick after it. A send with a failed file or a
  /// failure (cancelled, no space) stays open, so the user can retry.
  static bool shouldAutoFinish({
    required bool finishWhenDone,
    required TransferOutcome outcome,
  }) => finishWhenDone && outcome.failure == null && outcome.failedCount == 0;

  /// What a receiving phone must reload after a send, given the received
  /// counts before and after it.
  ///
  /// The transfer indexes received files itself, outside the normal scan, so
  /// nothing else tells the lists that the library grew. Only a count that
  /// went up counts: a new session starts again from zero.
  static ({bool library, bool vault}) refreshAfterReceive({
    required int receivedBefore,
    required int receivedNow,
    required int vaultBefore,
    required int vaultNow,
  }) => (library: receivedNow > receivedBefore, vault: vaultNow > vaultBefore);

  /// Splits [items] into files still to send and the number already sent.
  ///
  /// A mark that no longer matches its file (edited since) does not count:
  /// the file is offered again.
  static ({List<MediaItem> unsent, int alreadySent}) splitBySent(
    List<MediaItem> items,
    Map<String, SyncMark> marks,
  ) {
    final unsent = <MediaItem>[];
    var alreadySent = 0;
    for (final item in items) {
      final mark = marks[item.id];
      if (mark != null && mark.stillMatches(item)) {
        alreadySent++;
      } else {
        unsent.add(item);
      }
    }
    return (unsent: unsent, alreadySent: alreadySent);
  }

  /// How many of [items] were already sent, by the same rule.
  static int countSent(Iterable<MediaItem> items, Map<String, SyncMark> marks) {
    var sent = 0;
    for (final item in items) {
      final mark = marks[item.id];
      if (mark != null && mark.stillMatches(item)) sent++;
    }
    return sent;
  }
}
