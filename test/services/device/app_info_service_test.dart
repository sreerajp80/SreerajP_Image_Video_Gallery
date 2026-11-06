import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/device/app_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/app_info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Future<Object?>? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const service = AppInfoService(channel: channel);

  test('reads the version name and build number', () async {
    answer((call) async {
      expect(call.method, 'getAppInfo');
      return <String, Object?>{'versionName': '2.5.2', 'buildNumber': '15'};
    });

    final info = await service.load();

    expect(info!.version, '2.5.2');
    expect(info.buildNumber, '15');
    expect(info.fullVersion, '2.5.2+15');
  });

  test('a platform error becomes null, not a crash', () async {
    answer((_) async => throw PlatformException(code: 'unavailable'));

    expect(await service.load(), isNull);
  });

  test('no handler at all becomes null', () async {
    expect(await service.load(), isNull);
  });

  test('a malformed answer becomes null', () async {
    answer((_) async => <String, Object?>{'versionName': 2});

    expect(await service.load(), isNull);
  });
}
