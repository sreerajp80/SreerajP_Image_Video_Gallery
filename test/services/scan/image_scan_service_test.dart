import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/image_scan_service.dart';

/// A decoder that answers with whatever the test set up.
class _FakeDecoder implements BarcodeImageDecoder {
  final List<RawBarcode> found;
  final Object? throws;
  final Duration delay;

  int calls = 0;

  _FakeDecoder({
    this.found = const <RawBarcode>[],
    this.throws,
    this.delay = Duration.zero,
  });

  @override
  Future<List<RawBarcode>> decodeFile(String path) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throws != null) throw throws!;
    return found;
  }
}

ImageScanService _serviceWith(_FakeDecoder decoder, {Duration? timeout}) {
  return ImageScanService(decoder: decoder, timeout: timeout);
}

void main() {
  test('a picture with no codes says so, and is not a failure', () async {
    final outcome = await _serviceWith(_FakeDecoder()).scanFile('/a/photo.jpg');

    expect(outcome.foundNothing, isTrue);
    expect(outcome.decoderFailed, isFalse);
    expect(outcome.hasCodes, isFalse);
  });

  test('one code comes back typed, not raw', () async {
    final decoder = _FakeDecoder(
      found: const <RawBarcode>[
        RawBarcode('https://example.com', format: 'qrCode'),
      ],
    );

    final outcome = await _serviceWith(decoder).scanFile('/a/photo.jpg');

    expect(outcome.codes, hasLength(1));
    expect(outcome.codes.single.kind, ScannedCodeKind.url);
    expect(outcome.codes.single.format, 'qrCode');
  });

  test('several codes all come back, in the order they were read', () async {
    final decoder = _FakeDecoder(
      found: const <RawBarcode>[
        RawBarcode('https://example.com', format: 'qrCode'),
        RawBarcode('tel:+919000000000', format: 'qrCode'),
        RawBarcode('9781234567897', format: 'ean13'),
      ],
    );

    final outcome = await _serviceWith(decoder).scanFile('/a/photo.jpg');

    expect(outcome.codes, hasLength(3));
    expect(outcome.codes.map((code) => code.kind), <ScannedCodeKind>[
      ScannedCodeKind.url,
      ScannedCodeKind.phone,
      ScannedCodeKind.text,
    ]);
  });

  test('the same code twice in one picture is listed once', () async {
    final decoder = _FakeDecoder(
      found: const <RawBarcode>[
        RawBarcode('https://example.com', format: 'qrCode'),
        RawBarcode('https://example.com', format: 'qrCode'),
      ],
    );

    final outcome = await _serviceWith(decoder).scanFile('/a/photo.jpg');
    expect(outcome.codes, hasLength(1));
  });

  test('the same text in two symbologies is two codes', () async {
    final decoder = _FakeDecoder(
      found: const <RawBarcode>[
        RawBarcode('12345678', format: 'qrCode'),
        RawBarcode('12345678', format: 'code128'),
      ],
    );

    expect(
      (await _serviceWith(decoder).scanFile('/a/photo.jpg')).codes,
      hasLength(2),
    );
  });

  test('an empty payload is dropped', () async {
    final decoder = _FakeDecoder(
      found: const <RawBarcode>[
        RawBarcode(''),
        RawBarcode('real', format: 'qrCode'),
      ],
    );

    final outcome = await _serviceWith(decoder).scanFile('/a/photo.jpg');
    expect(outcome.codes, hasLength(1));
    expect(outcome.codes.single.rawValue, 'real');
  });

  group('nothing takes the app down', () {
    test('a decoder that throws gives a failed outcome', () async {
      final decoder = _FakeDecoder(throws: Exception('no such file'));
      final outcome = await _serviceWith(decoder).scanFile('/gone.jpg');

      expect(outcome.decoderFailed, isTrue);
      expect(outcome.foundNothing, isFalse);
    });

    test('a platform error gives a failed outcome', () async {
      final decoder = _FakeDecoder(throws: StateError('decoder is gone'));
      expect(
        (await _serviceWith(decoder).scanFile('/a.jpg')).decoderFailed,
        isTrue,
      );
    });

    test('a decoder that hangs is given up on', () async {
      final decoder = _FakeDecoder(delay: const Duration(seconds: 5));
      final outcome = await _serviceWith(
        decoder,
        timeout: const Duration(milliseconds: 50),
      ).scanFile('/slow.jpg');

      expect(outcome.decoderFailed, isTrue);
    });

    test('an empty path never reaches the decoder', () async {
      final decoder = _FakeDecoder();
      final outcome = await _serviceWith(decoder).scanFile('   ');

      expect(outcome.decoderFailed, isTrue);
      expect(decoder.calls, 0);
    });
  });
}
