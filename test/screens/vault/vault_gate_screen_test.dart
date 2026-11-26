import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_gate_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';

import '../../services/vault/fake_vault_channel.dart';

class _FakeBiometrics implements VaultBiometricService {
  final bool deviceSecure;

  _FakeBiometrics({required this.deviceSecure});

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> isDeviceSecure() async => deviceSecure;

  @override
  Future<VaultBiometricResult> authenticate({
    required String reason,
    required bool biometricOnly,
  }) async => VaultBiometricResult.cancelled;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required bool deviceSecure,
    VaultCredentialStore? store,
  }) async {
    final auth = VaultAuthService(
      store: store ?? InMemoryVaultCredentialStore(),
      biometricService: _FakeBiometrics(deviceSecure: deviceSecure),
      keyService: VaultKeyService(channel: FakeVaultChannel()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vaultAuthServiceProvider.overrideWithValue(auth)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  VaultLockMode? selected(WidgetTester tester) => tester
      .widget<RadioGroup<VaultLockMode>>(find.byType(RadioGroup<VaultLockMode>))
      .groupValue;

  testWidgets('a new vault defaults to phone lock when the phone has one', (
    tester,
  ) async {
    await pump(tester, const VaultGateScreen(), deviceSecure: true);

    expect(find.text('Choose a lock'), findsOneWidget);
    expect(selected(tester), VaultLockMode.phoneLock);
    // No PIN pad and no "forgotten PIN" warning for phone lock.
    expect(find.text('Choose a PIN'), findsNothing);
    expect(find.text('Create vault'), findsOneWidget);
  });

  testWidgets('without a screen lock the vault PIN is chosen and phone lock '
      'says why it cannot be used', (tester) async {
    await pump(tester, const VaultGateScreen(), deviceSecure: false);

    expect(selected(tester), VaultLockMode.vaultPin);
    expect(find.text('Choose a PIN'), findsOneWidget);
    expect(
      find.text(
        'This phone has no screen lock. Turn one on in Android settings '
        'to use this.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing the vault PIN shows the PIN pad and the warning', (
    tester,
  ) async {
    await pump(tester, const VaultGateScreen(), deviceSecure: true);

    await tester.tap(find.text('Vault PIN'));
    await tester.pumpAndSettle();

    expect(selected(tester), VaultLockMode.vaultPin);
    expect(find.text('Choose a PIN'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('a phone-lock vault offers the phone lock, not a PIN pad', (
    tester,
  ) async {
    final store = InMemoryVaultCredentialStore();
    await store.writeLockMode(VaultLockMode.phoneLock);

    await pump(
      tester,
      const VaultGateScreen(),
      deviceSecure: true,
      store: store,
    );

    expect(
      find.text('This vault opens with your phone\'s lock.'),
      findsOneWidget,
    );
    expect(find.text('Use phone lock'), findsOneWidget);
    expect(find.text('Enter your PIN'), findsNothing);
  });

  testWidgets('vault settings show the gate, not the settings, while shut', (
    tester,
  ) async {
    final store = InMemoryVaultCredentialStore();
    await store.writeLockMode(VaultLockMode.phoneLock);

    await pump(
      tester,
      const VaultSettingsScreen(),
      deviceSecure: true,
      store: store,
    );

    expect(find.text('Use phone lock'), findsOneWidget);
    expect(find.text('Auto-lock'), findsNothing);
    expect(find.text('Fingerprint unlock'), findsNothing);
  });
}
