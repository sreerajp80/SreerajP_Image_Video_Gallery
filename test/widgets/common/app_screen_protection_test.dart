import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/device/secure_window_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/app_screen_protection.dart';

import '../../helpers/recording_settings_service.dart';

/// Counts requests the way the Android side does.
class _CountingSecureWindow implements SecureWindowService {
  int held = 0;

  @override
  Future<void> acquire() async => held++;

  @override
  Future<void> release() async => held--;
}

void main() {
  late _CountingSecureWindow window;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {required bool protect}) async {
    window = _CountingSecureWindow();
    final service = RecordingSettingsService();
    container = ProviderContainer(
      overrides: <Override>[
        secureWindowServiceProvider.overrideWithValue(window),
        appSettingsProvider.overrideWith(
          (ref) => AppSettingsNotifier(
            service: () async => service,
            initial: AppSettings(protectAllScreens: protect),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AppScreenProtection(child: SizedBox()),
      ),
    );
  }

  testWidgets('off by default: nothing is requested', (tester) async {
    await pump(tester, protect: false);
    expect(window.held, 0);
  });

  testWidgets('switching it on and off holds and gives back one request', (
    tester,
  ) async {
    await pump(tester, protect: false);

    await container
        .read(appSettingsProvider.notifier)
        .setProtectAllScreens(true);
    await tester.pump();
    expect(window.held, 1);

    await container
        .read(appSettingsProvider.notifier)
        .setProtectAllScreens(false);
    await tester.pump();
    expect(window.held, 0);
  });

  testWidgets('a vault request survives the switch going off', (tester) async {
    await pump(tester, protect: true);
    expect(window.held, 1);

    // The vault's own SecureScreen asks too.
    await window.acquire();
    expect(window.held, 2);

    await container
        .read(appSettingsProvider.notifier)
        .setProtectAllScreens(false);
    await tester.pump();
    expect(window.held, 1, reason: 'the vault is still protected');
  });

  testWidgets('leaving the tree gives back its request', (tester) async {
    await pump(tester, protect: true);
    expect(window.held, 1);

    await tester.pumpWidget(const SizedBox());
    expect(window.held, 0);
  });
}
