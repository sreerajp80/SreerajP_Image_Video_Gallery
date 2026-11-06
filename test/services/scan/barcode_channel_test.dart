import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/barcode_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AppConstants.barcodeChannelName);
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  group('decodeImageFile', () {
    test('maps every code and its format name', () async {
      answer(
        (_) => <Object?>[
          <String, String>{'value': 'https://example.org', 'format': 'QR_CODE'},
          <String, String>{'value': '4006381333931', 'format': 'EAN_13'},
        ],
      );

      final codes = await const BarcodeChannel().decodeImageFile('/p.jpg');

      expect(calls.single.method, 'decodeImageFile');
      expect(calls.single.arguments, <String, Object?>{'path': '/p.jpg'});
      expect(codes.map((c) => c.value), <String>[
        'https://example.org',
        '4006381333931',
      ]);
      expect(codes.map((c) => c.format), <String>['qrCode', 'ean13']);
    });

    test('drops empty and malformed entries', () async {
      answer(
        (_) => <Object?>[
          <String, String>{'value': '', 'format': 'QR_CODE'},
          'not a map',
          <String, Object?>{'value': 7},
          <String, String>{'value': 'ok', 'format': 'QR_CODE'},
        ],
      );

      final codes = await const BarcodeChannel().decodeImageFile('/p.jpg');
      expect(codes.map((c) => c.value), <String>['ok']);
    });

    test('nothing found is an empty list, not an error', () async {
      answer((_) => <Object?>[]);
      expect(await const BarcodeChannel().decodeImageFile('/p.jpg'), isEmpty);
    });

    test('a reader that could not run throws a typed error', () async {
      answer((_) => throw PlatformException(code: 'unreadable'));
      expect(
        const BarcodeChannel().decodeImageFile('/p.jpg'),
        throwsA(
          isA<BarcodeDecodeException>().having(
            (e) => e.code,
            'code',
            'unreadable',
          ),
        ),
      );
    });

    test('a missing native side throws a typed error', () async {
      expect(
        const BarcodeChannel().decodeImageFile('/p.jpg'),
        throwsA(isA<BarcodeDecodeException>()),
      );
    });
  });

  test('decodeLuminance sends the frame and returns the texts', () async {
    answer(
      (_) => <Object?>[
        <String, String>{'value': 'pairing', 'format': 'QR_CODE'},
      ],
    );

    final texts = await const BarcodeChannel().decodeLuminance(
      bytes: Uint8List(12),
      width: 3,
      height: 3,
      rowStride: 4,
    );

    expect(texts, <String>['pairing']);
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['width'], 3);
    expect(args['height'], 3);
    expect(args['rowStride'], 4);
  });

  test('ZXing format names become the app style', () {
    expect(BarcodeChannel.formatName('QR_CODE'), 'qrCode');
    expect(BarcodeChannel.formatName('EAN_13'), 'ean13');
    expect(BarcodeChannel.formatName('PDF_417'), 'pdf417');
    expect(BarcodeChannel.formatName('AZTEC'), 'aztec');
    expect(BarcodeChannel.formatName(''), '');
  });
}
