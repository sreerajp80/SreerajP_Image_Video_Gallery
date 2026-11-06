import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';

/// How far a backup has got.
enum BackupStage {
  /// Reading the database.
  collecting,

  /// Turning it into JSON and compressing it.
  packing,

  /// Waiting for the user to choose where it goes.
  choosingDestination,

  /// Encrypting into the chosen file.
  encrypting,

  /// Finished.
  done,
}

/// Thrown when a backup cannot be made.
final class BackupException extends FeatureException {
  /// True when the archive holds nothing worth saving.
  final bool isEmpty;

  const BackupException(super.message, {this.isEmpty = false, super.cause});
}
