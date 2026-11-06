import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';

/// Why a restore could not go ahead.
enum RestoreFailure {
  /// The user backed out of the file picker. Not really a failure.
  cancelled,

  /// The chosen file is not one of ours.
  notAnArchive,

  /// The password did not open it, or the file is damaged.
  wrongPasswordOrDamaged,

  /// The file is larger than any real archive would be.
  tooLarge,

  /// The archive was written by a newer build.
  tooNew,

  /// Something else went wrong.
  failed,
}

/// Thrown when a restore cannot go ahead.
final class RestoreException extends FeatureException {
  final RestoreFailure failure;
  const RestoreException(this.failure, super.message, {super.cause});

  @override
  String toString() => 'RestoreException(${failure.name}): $message';
}
