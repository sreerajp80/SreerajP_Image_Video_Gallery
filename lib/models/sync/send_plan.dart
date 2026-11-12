import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// What stopped a send from carrying everything that was picked.
enum SendLimit {
  /// Nothing. Everything picked fits in this send.
  none,

  /// The size cap for one send. The rest goes in the next send.
  cap,

  /// The other phone's free space.
  space,

  /// The most files one send can carry.
  count,
}

/// What one Wi-Fi send will carry, and what is left for later.
@immutable
class SendPlan {
  /// The files this send carries, in order.
  final List<MediaItem> toSend;

  /// Their total size, in bytes, as the index knows it.
  final int sendBytes;

  /// Files picked but left for a later send.
  final int leftCount;

  /// Total size of [leftCount], in bytes.
  final int leftBytes;

  /// Files picked that were already sent to this phone, so are not offered.
  final int alreadySentCount;

  /// Files picked by hand that were sent to this phone before. They are
  /// sent again, because the user chose them on purpose; this count is only
  /// for the note on screen.
  final int resendCount;

  /// Why some files were left out, or [SendLimit.none].
  final SendLimit limitedBy;

  const SendPlan({
    this.toSend = const <MediaItem>[],
    this.sendBytes = 0,
    this.leftCount = 0,
    this.leftBytes = 0,
    this.alreadySentCount = 0,
    this.resendCount = 0,
    this.limitedBy = SendLimit.none,
  });

  /// A plan with nothing in it.
  static const SendPlan empty = SendPlan();

  bool get isEmpty => toSend.isEmpty;

  /// Whether some picked files must wait for a later send.
  bool get hasLeftOver => leftCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendPlan &&
          listEquals(toSend, other.toSend) &&
          sendBytes == other.sendBytes &&
          leftCount == other.leftCount &&
          leftBytes == other.leftBytes &&
          alreadySentCount == other.alreadySentCount &&
          resendCount == other.resendCount &&
          limitedBy == other.limitedBy;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(toSend),
    sendBytes,
    leftCount,
    leftBytes,
    alreadySentCount,
    resendCount,
    limitedBy,
  );
}
