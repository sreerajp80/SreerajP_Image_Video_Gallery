import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/intent_channel.dart';

/// Records every call instead of reaching Android.
class _FakeIntentChannel implements IntentChannel {
  final List<String> calls = <String>[];
  bool acceptWifi = true;

  @override
  Future<void> copyToClipboard(
    String text, {
    String label = '',
    bool isSensitive = false,
  }) async {
    calls.add('copy:$text:$isSensitive');
  }

  @override
  Future<void> openUri(String uri) async => calls.add('open:$uri');

  @override
  Future<bool> suggestWifiNetwork(WifiCredentials credentials) async {
    calls.add('suggest:${credentials.ssid}');
    return acceptWifi;
  }

  @override
  Future<void> openWifiSettings() async => calls.add('settings');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeIntentChannel intents;
  late ProviderContainer container;

  setUp(() {
    intents = _FakeIntentChannel();
    container = ProviderContainer(
      overrides: <Override>[intentChannelProvider.overrideWithValue(intents)],
    );
  });

  tearDown(() => container.dispose());

  ScanActionRunner runner() => container.read(scanActionRunnerProvider);

  test('copy passes the sensitive flag through', () async {
    await runner().copy('secret', isSensitive: true);

    expect(intents.calls, <String>['copy:secret:true']);
  });

  test('open hands the link to the intent channel', () async {
    await runner().open('https://example.org');

    expect(intents.calls, <String>['open:https://example.org']);
  });

  test(
    'Wi-Fi is only suggested; the user still picks it in settings',
    () async {
      intents.acceptWifi = false;

      final accepted = await runner().connectWifi(
        const WifiCredentials(ssid: 'Home'),
      );

      expect(accepted, isFalse);
      expect(intents.calls, <String>['suggest:Home', 'settings']);
    },
  );

  test('the scan controller starts empty and resets to empty', () {
    container.listen(imageScanControllerProvider, (_, _) {});
    final notifier = container.read(imageScanControllerProvider.notifier);

    expect(container.read(imageScanControllerProvider).value, isNull);
    notifier.reset();
    expect(container.read(imageScanControllerProvider).value, isNull);
  });
}
