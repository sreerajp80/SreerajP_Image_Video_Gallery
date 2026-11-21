import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/wallpaper_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/wallpaper');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Future<Object?>? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final service = WallpaperService(channel: channel);

  Future<bool> setOne() => service.setAsWallpaper(
    uri: 'content://media/external/images/media/42',
    mimeType: 'image/jpeg',
    chooserTitle: 'Set as',
  );

  test('sends the method and its arguments', () async {
    MethodCall? seen;
    answer((call) async {
      seen = call;
      return true;
    });

    expect(await setOne(), isTrue);
    expect(seen!.method, 'setAsWallpaper');
    expect(seen!.arguments, <String, Object?>{
      'uri': 'content://media/external/images/media/42',
      'mimeType': 'image/jpeg',
      'chooserTitle': 'Set as',
    });
  });

  test('a platform error returns false instead of throwing', () async {
    answer((call) async => throw PlatformException(code: 'no_app'));

    expect(await setOne(), isFalse);
  });

  test('a missing plugin returns false instead of throwing', () async {
    // No handler at all, as on a platform without the Kotlin side.
    expect(await setOne(), isFalse);
  });

  test('a null answer counts as not opened', () async {
    answer((call) async => null);

    expect(await setOne(), isFalse);
  });
}
