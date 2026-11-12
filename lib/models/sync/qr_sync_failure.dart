import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';

/// Why a QR sync could not go ahead.
enum QrSyncFailure {
  /// There is no app data on this phone to send.
  nothingToSend,

  /// The data needs more codes than one QR sync may show.
  tooBig,

  /// The frames did not decrypt or did not read as app data.
  unreadable,
}

/// Thrown when a QR sync cannot go ahead.
final class QrSyncException extends FeatureException {
  final QrSyncFailure failure;

  /// How many codes the data would have needed, for [QrSyncFailure.tooBig].
  final int frameCount;

  const QrSyncException(
    this.failure,
    super.message, {
    this.frameCount = 0,
    super.cause,
  });
}
