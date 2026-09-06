import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';

void main() {
  group('VaultNamingService', () {
    // Seeded, so a test can repeat itself. The real service uses Random.secure,
    // because a predictable name is a predictable file.
    VaultNamingService buildService([int seed = 11]) =>
        VaultNamingService(random: Random(seed));

    group('newPayloadName', () {
      test('is hex of the configured length plus the payload extension', () {
        final name = buildService().newPayloadName();

        expect(name, endsWith(AppConstants.vaultPayloadExtension));
        final stem = name.substring(
          0,
          name.length - AppConstants.vaultPayloadExtension.length,
        );
        expect(stem.length, AppConstants.vaultPayloadNameBytes * 2);
        expect(stem, matches(RegExp(r'^[0-9a-f]+$')));
      });

      test('carries nothing about the file it holds', () {
        // Nothing but hex: no name, no date, no type. A directory listing of
        // the vault is what an attacker gets for free, so it says nothing.
        final name = buildService().newPayloadName();
        expect(name, isNot(contains('_')));
        expect(name, matches(RegExp(r'^[0-9a-f]+\.enc$')));
      });

      test('does not repeat itself over many draws', () {
        final service = buildService();
        final names = <String>{
          for (var i = 0; i < 500; i++) service.newPayloadName(),
        };

        expect(names.length, 500);
      });
    });

    group('newThumbnailName', () {
      test('uses the preview extension', () {
        final name = buildService().newThumbnailName();

        expect(name, endsWith(AppConstants.vaultThumbnailExtension));
        expect(name, isNot(endsWith(AppConstants.vaultPayloadExtension)));
      });

      test('does not collide with payload names', () {
        final service = buildService();
        final payloads = <String>{
          for (var i = 0; i < 200; i++) service.newPayloadName(),
        };
        final thumbnails = <String>{
          for (var i = 0; i < 200; i++) service.newThumbnailName(),
        };

        expect(payloads.intersection(thumbnails), isEmpty);
      });
    });

    group('workingNameFor', () {
      test('keeps the payload stem so a sweep can find it', () {
        final service = buildService();
        final payload = service.newPayloadName();
        final working = service.workingNameFor(payload);

        // Derived, not random: a crash during playback leaves this file
        // behind, and the sweep on the next unlock has to be able to spot it.
        final stem = payload.substring(
          0,
          payload.length - AppConstants.vaultPayloadExtension.length,
        );
        expect(working, '$stem${AppConstants.vaultWorkingExtension}');
      });

      test('handles a name that has no payload extension', () {
        expect(
          buildService().workingNameFor('abc123'),
          'abc123${AppConstants.vaultWorkingExtension}',
        );
      });

      test('is stable, so the same payload always maps to the same file', () {
        final service = buildService();
        expect(
          service.workingNameFor('deadbeef.enc'),
          service.workingNameFor('deadbeef.enc'),
        );
      });
    });

    group('isWorkingFile', () {
      test('spots a decrypted working file', () {
        expect(
          VaultNamingService.isWorkingFile(
            'abc${AppConstants.vaultWorkingExtension}',
          ),
          isTrue,
        );
      });

      test('does not mistake a payload or preview for one', () {
        expect(VaultNamingService.isWorkingFile('abc.enc'), isFalse);
        expect(VaultNamingService.isWorkingFile('abc.thm'), isFalse);
        expect(VaultNamingService.isWorkingFile('.nomedia'), isFalse);
      });
    });

    group('isEncryptedFile', () {
      test('spots payloads and previews', () {
        expect(VaultNamingService.isEncryptedFile('abc.enc'), isTrue);
        expect(VaultNamingService.isEncryptedFile('abc.thm'), isTrue);
      });

      test('leaves working files and the marker alone', () {
        // The orphan sweep uses this. Counting the .nomedia marker as an
        // orphan payload would delete the very thing keeping other scanners
        // out of the directory.
        expect(
          VaultNamingService.isEncryptedFile(
            'abc${AppConstants.vaultWorkingExtension}',
          ),
          isFalse,
        );
        expect(
          VaultNamingService.isEncryptedFile(AppConstants.vaultNoMediaFileName),
          isFalse,
        );
      });
    });
  });
}
