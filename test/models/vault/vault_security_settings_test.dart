import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';

void main() {
  group('VaultSecuritySettings', () {
    test('defaults are the safe ones', () {
      const settings = VaultSecuritySettings.defaults;

      expect(
        settings.autoLockSeconds,
        AppConstants.vaultAutoLockTimeoutSeconds,
      );
      expect(settings.biometricEnabled, isTrue);
      expect(settings.shredPasses, AppConstants.vaultDefaultShredPasses);
      // Destroying originals is never the default. It has to be chosen.
      expect(settings.shredOnImportByDefault, isFalse);
    });

    test('survives a JSON round trip', () {
      const settings = VaultSecuritySettings(
        autoLockSeconds: 300,
        biometricEnabled: false,
        shredPasses: 4,
        shredOnImportByDefault: true,
      );

      expect(VaultSecuritySettings.fromJson(settings.toJson()), settings);
    });

    test('falls back field by field when the stored map is empty', () {
      expect(
        VaultSecuritySettings.fromJson(const <String, dynamic>{}),
        VaultSecuritySettings.defaults,
      );
    });

    group('reading a hand-edited or corrupted store', () {
      test('rejects a timeout the app does not offer', () {
        final settings = VaultSecuritySettings.fromJson(const <String, dynamic>{
          'auto_lock_seconds': 86400,
        });

        // A vault that only locks after a day is not one of the choices, and
        // accepting it would leave the vault effectively always open.
        expect(
          settings.autoLockSeconds,
          AppConstants.vaultAutoLockTimeoutSeconds,
        );
      });

      test('rejects a timeout of the wrong type', () {
        final settings = VaultSecuritySettings.fromJson(const <String, dynamic>{
          'auto_lock_seconds': 'never',
        });

        expect(
          settings.autoLockSeconds,
          AppConstants.vaultAutoLockTimeoutSeconds,
        );
      });

      test('clamps an absurd shred pass count instead of running it', () {
        expect(
          VaultSecuritySettings.fromJson(const <String, dynamic>{
            'shred_passes': 10000,
          }).shredPasses,
          AppConstants.vaultMaxShredPasses,
        );
        expect(
          VaultSecuritySettings.fromJson(const <String, dynamic>{
            'shred_passes': 0,
          }).shredPasses,
          AppConstants.vaultMinShredPasses,
        );
      });

      test('accepts every timeout the app does offer', () {
        for (final seconds in AppConstants.vaultAutoLockChoicesSeconds) {
          expect(
            VaultSecuritySettings.fromJson(<String, dynamic>{
              'auto_lock_seconds': seconds,
            }).autoLockSeconds,
            seconds,
          );
        }
      });
    });

    test('copyWith changes only what it is given', () {
      const settings = VaultSecuritySettings.defaults;
      final updated = settings.copyWith(shredPasses: 5);

      expect(updated.shredPasses, 5);
      expect(updated.autoLockSeconds, settings.autoLockSeconds);
      expect(updated.biometricEnabled, settings.biometricEnabled);
      expect(updated.shredOnImportByDefault, settings.shredOnImportByDefault);
    });

    test('equality covers every field', () {
      const base = VaultSecuritySettings.defaults;

      expect(base, const VaultSecuritySettings());
      expect(base, isNot(base.copyWith(biometricEnabled: false)));
      expect(
        base.hashCode,
        isNot(base.copyWith(shredOnImportByDefault: true).hashCode),
      );
    });
  });
}
