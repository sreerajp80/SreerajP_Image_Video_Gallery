import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';

void main() {
  test('feature exceptions are AppExceptions', () {
    const Object conversion = ConversionException('x');
    expect(conversion, isA<FeatureException>());
    expect(conversion, isA<AppException>());
  });

  test('a raw error goes to cause, not into the message', () {
    const error = FormatException('/storage/emulated/0/DCIM/private.jpg');
    const exception = ConversionException(
      'The picture could not be read',
      cause: error,
    );
    expect(exception.message, isNot(contains('private.jpg')));
    expect(exception.cause, same(error));
  });

  test('ValidationException names the refused field', () {
    const exception = ValidationException('keyLength', 'must be at least 1');
    expect(exception.field, 'keyLength');
  });

  test('a switch over AppException covers every kind', () {
    String kind(AppException e) => switch (e) {
      StorageException() => 'storage',
      AtomicSaveException() => 'atomic',
      DatabaseMigrationException() => 'migration',
      ModelParseException() => 'parse',
      MediaScanException() => 'scan',
      PermissionDeniedException() => 'permission',
      ThumbnailException() => 'thumbnail',
      VaultException() => 'vault',
      VaultAuthException() => 'vault-auth',
      ValidationException() => 'validation',
      BatchItemException() => 'batch',
      FeatureException() => 'feature',
    };

    expect(kind(const BatchItemException('x')), 'batch');
    expect(
      kind(const TransferSessionException(TransferFailure.pairingTimeout, 'x')),
      'feature',
    );
  });
}
