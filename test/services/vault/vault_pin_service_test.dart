import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_service.dart';

void main() {
  group('VaultPinService', () {
    // A seeded random, so the salts are repeatable in a test. The real service
    // uses Random.secure.
    VaultPinService buildService([int seed = 7]) =>
        VaultPinService(random: Random(seed));

    group('generateSalt', () {
      test('returns the configured number of bytes', () {
        final salt = buildService().generateSalt();
        expect(base64Decode(salt).length, AppConstants.vaultPinSaltBytes);
      });

      test('does not return the same salt twice in a row', () {
        final service = buildService();
        expect(service.generateSalt(), isNot(service.generateSalt()));
      });
    });

    group('hashPin', () {
      test('is the same every time for the same PIN and salt', () {
        final service = buildService();
        final salt = service.generateSalt();

        expect(
          service.hashPin('194627', salt),
          service.hashPin('194627', salt),
        );
      });

      test('returns the configured hash length', () {
        final service = buildService();
        final salt = service.generateSalt();

        expect(
          base64Decode(service.hashPin('194627', salt)).length,
          AppConstants.vaultPinHashBytes,
        );
      });

      test('differs for two PINs under one salt', () {
        final service = buildService();
        final salt = service.generateSalt();

        expect(
          service.hashPin('194627', salt),
          isNot(service.hashPin('194628', salt)),
        );
      });

      test('differs for one PIN under two salts', () {
        final service = buildService();

        // This is what the salt is for: two people who pick the same PIN store
        // different bytes, so one cracked hash says nothing about the other.
        expect(
          service.hashPin('194627', service.generateSalt()),
          isNot(service.hashPin('194627', service.generateSalt())),
        );
      });

      test('changes when the iteration count changes', () {
        final service = buildService();
        final salt = service.generateSalt();

        expect(
          service.hashPin('194627', salt, iterations: 1000),
          isNot(service.hashPin('194627', salt, iterations: 2000)),
        );
      });
    });

    group('verifyPin', () {
      test('accepts the PIN that was stored', () {
        final service = buildService();
        final salt = service.generateSalt();
        final hash = service.hashPin('194627', salt);

        expect(service.verifyPin('194627', salt, hash), isTrue);
      });

      test('rejects a different PIN', () {
        final service = buildService();
        final salt = service.generateSalt();
        final hash = service.hashPin('194627', salt);

        expect(service.verifyPin('194628', salt, hash), isFalse);
      });

      test('rejects the right PIN under the wrong salt', () {
        final service = buildService();
        final hash = service.hashPin('194627', service.generateSalt());

        expect(
          service.verifyPin('194627', service.generateSalt(), hash),
          isFalse,
        );
      });

      test('verifies against the iteration count it is told to use', () {
        final service = buildService();
        final salt = service.generateSalt();
        final hash = service.hashPin('194627', salt, iterations: 5000);

        // The stored count is what makes raising the default later safe: an
        // old vault still opens.
        expect(
          service.verifyPin('194627', salt, hash, iterations: 5000),
          isTrue,
        );
        expect(
          service.verifyPin('194627', salt, hash, iterations: 6000),
          isFalse,
        );
      });

      test('refuses rather than throwing when the store is corrupt', () {
        final service = buildService();

        expect(
          service.verifyPin('194627', 'not base64!!', 'also not'),
          isFalse,
        );
        expect(service.verifyPin('194627', '', ''), isFalse);
        expect(service.verifyPin('', 'c2FsdA==', 'aGFzaA=='), isFalse);
      });
    });

    group('pbkdf2', () {
      test('matches the RFC 6070 vector for one iteration', () {
        // "password" / "salt" / c=1 / dkLen=32, SHA-256.
        final derived = VaultPinService.pbkdf2(
          password: utf8.encode('password'),
          salt: utf8.encode('salt'),
          iterations: 1,
          keyLength: 32,
        );

        expect(
          derived.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
        );
      });

      test('matches the RFC 6070 vector for two iterations', () {
        final derived = VaultPinService.pbkdf2(
          password: utf8.encode('password'),
          salt: utf8.encode('salt'),
          iterations: 2,
          keyLength: 32,
        );

        expect(
          derived.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
        );
      });

      test('produces a key longer than one hash block correctly', () {
        // Forces two blocks, so the block-counting loop is exercised.
        final derived = VaultPinService.pbkdf2(
          password: utf8.encode('password'),
          salt: utf8.encode('salt'),
          iterations: 2,
          keyLength: 40,
        );

        expect(derived.length, 40);
        // The first block must match the 32-byte answer exactly.
        expect(
          derived
              .take(32)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
        );
      });

      test('refuses a useless iteration count or key length', () {
        expect(
          () => VaultPinService.pbkdf2(
            password: const <int>[1],
            salt: const <int>[2],
            iterations: 0,
            keyLength: 32,
          ),
          throwsArgumentError,
        );
        expect(
          () => VaultPinService.pbkdf2(
            password: const <int>[1],
            salt: const <int>[2],
            iterations: 1,
            keyLength: 0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('constantTimeEquals', () {
      test('is true only for identical bytes', () {
        expect(
          VaultPinService.constantTimeEquals(
            const <int>[1, 2, 3],
            const <int>[1, 2, 3],
          ),
          isTrue,
        );
        expect(
          VaultPinService.constantTimeEquals(
            const <int>[1, 2, 3],
            const <int>[1, 2, 4],
          ),
          isFalse,
        );
      });

      test('is false for different lengths', () {
        expect(
          VaultPinService.constantTimeEquals(
            const <int>[1, 2],
            const <int>[1, 2, 3],
          ),
          isFalse,
        );
      });

      test('does not stop at the first difference', () {
        // Both differ only in the first byte and only in the last; a walk that
        // returned early would still answer correctly, so this pins the
        // behaviour rather than the timing, which a unit test cannot measure.
        expect(
          VaultPinService.constantTimeEquals(
            const <int>[9, 2, 3],
            const <int>[1, 2, 3],
          ),
          isFalse,
        );
        expect(
          VaultPinService.constantTimeEquals(
            const <int>[1, 2, 9],
            const <int>[1, 2, 3],
          ),
          isFalse,
        );
      });

      test('is true for two empty lists', () {
        expect(
          VaultPinService.constantTimeEquals(const <int>[], const <int>[]),
          isTrue,
        );
      });
    });
  });
}
