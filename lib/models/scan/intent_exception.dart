import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';

/// Thrown when handing something to another app did not work.
final class IntentException extends FeatureException {
  final String code;
  const IntentException(this.code, super.message, {super.cause});

  /// Whether no app on the device can open it.
  bool get hasNoApp => code == 'no_app';

  /// Whether the scheme was refused, rather than merely failing.
  ///
  /// This one is a bug, not a device limit: the resolver should never have
  /// offered an action the channel then refuses.
  bool get wasBlocked => code == 'blocked_scheme';

  @override
  String toString() => 'IntentException($code): $message';
}
