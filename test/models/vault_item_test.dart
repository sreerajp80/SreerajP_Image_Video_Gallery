import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';

void main() {
  group('VaultItem Domain Model', () {
    final now = DateTime(2026, 8, 29, 9, 0, 0);
    final testVault = VaultItem(
      id: 'vault_001',
      originalPath: '/storage/emulated/0/DCIM/Camera/passport.jpg',
      originalFilename: 'passport.jpg',
      encryptedFilename: 'enc_abc123.bin',
      encryptedThumbnailFilename: 'thumb_enc_abc123.bin',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      sizeBytes: 2048576,
      iv: 'dGVzdGl2MTIzNDU2',
      authTag: 'dGVzdGF1dGh0YWcxMjM0',
      dateVaulted: now,
      dateTaken: now,
      width: 1920,
      height: 1080,
      durationMs: null,
      tags: const ['Personal', 'ID'],
      notes: 'Passport scan document',
    );

    test('supports value equality', () {
      final duplicate = VaultItem(
        id: 'vault_001',
        originalPath: '/storage/emulated/0/DCIM/Camera/passport.jpg',
        originalFilename: 'passport.jpg',
        encryptedFilename: 'enc_abc123.bin',
        encryptedThumbnailFilename: 'thumb_enc_abc123.bin',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        sizeBytes: 2048576,
        iv: 'dGVzdGl2MTIzNDU2',
        authTag: 'dGVzdGF1dGh0YWcxMjM0',
        dateVaulted: now,
        dateTaken: now,
        width: 1920,
        height: 1080,
        durationMs: null,
        tags: const ['Personal', 'ID'],
        notes: 'Passport scan document',
      );

      expect(testVault, equals(duplicate));
    });

    test('copyWith modifies attributes accurately', () {
      final modified = testVault.copyWith(notes: 'Updated scan note');
      expect(modified.notes, 'Updated scan note');
      expect(modified.id, testVault.id);
      expect(modified.iv, testVault.iv);
    });

    test('serialization roundtrip via toMap and fromMap', () {
      final map = testVault.toMap();
      final fromMap = VaultItem.fromMap(map);

      expect(fromMap.id, testVault.id);
      expect(fromMap.originalFilename, testVault.originalFilename);
      expect(fromMap.encryptedFilename, testVault.encryptedFilename);
      expect(fromMap.iv, testVault.iv);
      expect(fromMap.authTag, testVault.authTag);
      expect(fromMap.tags, equals(testVault.tags));
      expect(fromMap.notes, testVault.notes);
    });
  });
}
