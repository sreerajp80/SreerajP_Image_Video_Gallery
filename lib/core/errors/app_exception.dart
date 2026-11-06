import 'package:flutter/foundation.dart';

/// Base class for all application-specific exceptions.
///
/// The hierarchy is `sealed` (engineering standard §11.3): every direct
/// subclass lives in this file, so a `switch` over an [AppException] must
/// name each kind. Errors that belong to one feature (conversion, backup,
/// transfer and so on) extend [FeatureException] in the feature's own file,
/// so this core file never imports a service.
///
/// Never put a file name, path, URI, note text or metadata value into
/// [message]: an exception can reach a log. Pass the underlying error as
/// [cause] instead.
@immutable
sealed class AppException implements Exception {
  /// User-friendly message explaining the error.
  final String message;

  /// Optional underlying cause or error details.
  final Object? cause;

  /// Optional stack trace for debugging.
  final StackTrace? stackTrace;

  const AppException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) {
      buffer.write(' (Cause: $cause)');
    }
    return buffer.toString();
  }
}

/// Exception thrown on database query, migration, or persistence errors.
final class StorageException extends AppException {
  const StorageException(super.message, {super.cause, super.stackTrace});
}

/// Exception thrown when an atomic file write, staging swap, or checksum fails.
final class AtomicSaveException extends AppException {
  final String? targetPath;

  const AtomicSaveException(
    super.message, {
    this.targetPath,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when local database migrations fail.
final class DatabaseMigrationException extends AppException {
  final int fromVersion;
  final int toVersion;

  const DatabaseMigrationException(
    super.message, {
    required this.fromVersion,
    required this.toVersion,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when domain model serialization or parsing fails.
final class ModelParseException extends AppException {
  final String modelName;

  const ModelParseException(
    super.message, {
    required this.modelName,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when scanning or indexing device media fails.
final class MediaScanException extends AppException {
  /// Optional platform error code reported by the native MediaStore channel.
  final String? code;

  const MediaScanException(
    super.message, {
    this.code,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when required media permissions are not granted.
final class PermissionDeniedException extends AppException {
  /// Whether the user selected "Don't ask again" for the permission.
  final bool isPermanent;

  const PermissionDeniedException(
    super.message, {
    this.isPermanent = false,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when a thumbnail cannot be generated or cached.
final class ThumbnailException extends AppException {
  const ThumbnailException(super.message, {super.cause, super.stackTrace});
}

/// Exception thrown when a vault key, cipher, payload, or shred operation
/// fails.
///
/// The message never carries a file name, a path, a PIN, or key material: a
/// vault error can end up in a log, and the point of the vault is that its
/// contents stay unnamed.
final class VaultException extends AppException {
  /// Short machine-readable reason, e.g. `keystore_unavailable`.
  final String? code;

  const VaultException(
    super.message, {
    this.code,
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when unlocking the vault fails for a reason the caller
/// has to handle rather than show.
final class VaultAuthException extends AppException {
  const VaultAuthException(super.message, {super.cause, super.stackTrace});
}

/// Exception thrown when a value handed to a service is not valid, such as
/// a byte buffer of the wrong length.
final class ValidationException extends AppException {
  /// The name of the value that was refused.
  final String field;

  const ValidationException(
    this.field,
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Exception thrown when one item of a batch action could not be handled.
///
/// The message never names the item: the batch already knows which item it
/// was working on.
final class BatchItemException extends AppException {
  const BatchItemException(super.message, {super.cause, super.stackTrace});
}

/// Base for exceptions that belong to one feature, such as conversion,
/// backup or transfer.
///
/// Feature exceptions live next to the service that throws them and extend
/// this class, so they are still [AppException]s.
abstract class FeatureException extends AppException {
  const FeatureException(super.message, {super.cause, super.stackTrace});
}
