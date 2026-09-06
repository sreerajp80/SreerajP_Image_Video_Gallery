import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_result.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_engine.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_service.dart';

/// A reader that answers with whatever the test set up.
class _FakeEngine implements OcrEngine {
  final String text;
  final Object? throws;
  final Duration delay;

  OcrLanguage? askedFor;
  int calls = 0;

  _FakeEngine({this.text = '', this.throws, this.delay = Duration.zero});

  @override
  Future<String> readText(String imagePath, OcrLanguage language) async {
    calls++;
    askedFor = language;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throws != null) throw throws!;
    return text;
  }
}

void main() {
  late Directory workspace;
  late String photo;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ocr_service_test');
    photo = '${workspace.path}${Platform.pathSeparator}photo.jpg';
    File(photo).writeAsBytesSync(List<int>.filled(1024, 0));
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  group('reading', () {
    test('the text comes back cleaned', () async {
      final engine = _FakeEngine(text: '  Hello   world  \n\n\n  again  ');
      final result = await OcrService(engine: engine).readImage(photo);

      expect(result.isFailure, isFalse);
      expect(result.text, 'Hello world\nagain');
      expect(result.lines, <String>['Hello world', 'again']);
      expect(result.hasText, isTrue);
    });

    test('a picture with no text is a success, not a failure', () async {
      final result = await OcrService(engine: _FakeEngine()).readImage(photo);

      expect(result.isFailure, isFalse);
      expect(result.foundNothing, isTrue);
      expect(result.hasText, isFalse);
    });

    test('the pass is timed', () async {
      final result = await OcrService(
        engine: _FakeEngine(text: 'x', delay: const Duration(milliseconds: 20)),
      ).readImage(photo);

      expect(result.duration, greaterThan(Duration.zero));
    });

    test('word and character counts are reported', () async {
      final result = await OcrService(
        engine: _FakeEngine(text: 'one two three'),
      ).readImage(photo);

      expect(result.wordCount, 3);
      expect(result.characterCount, 13);
    });
  });

  group('language', () {
    test('english is the default', () async {
      final engine = _FakeEngine(text: 'text');
      final result = await OcrService(engine: engine).readImage(photo);

      expect(engine.askedFor, OcrLanguage.english);
      expect(result.language, OcrLanguage.english);
    });

    test('malayalam is passed through to the reader', () async {
      final engine = _FakeEngine(text: 'കോവളം');
      final result = await OcrService(
        engine: engine,
      ).readImage(photo, language: OcrLanguage.malayalam);

      expect(engine.askedFor, OcrLanguage.malayalam);
      expect(result.text, 'കോവളം');
      expect(result.language, OcrLanguage.malayalam);
    });

    test('both languages ask for the combined code', () async {
      final engine = _FakeEngine(text: 'Beach: കോവളം');
      await OcrService(
        engine: engine,
      ).readImage(photo, language: OcrLanguage.both);

      expect(engine.askedFor?.code, 'eng+mal');
    });

    test('each language names the files it needs', () {
      expect(OcrLanguage.english.requiredFiles, <String>['eng.traineddata']);
      expect(OcrLanguage.malayalam.requiredFiles, <String>['mal.traineddata']);
      expect(OcrLanguage.both.requiredFiles, <String>[
        'eng.traineddata',
        'mal.traineddata',
      ]);
    });
  });

  group('nothing takes the app down', () {
    test('a missing file is refused before the reader is started', () async {
      final engine = _FakeEngine(text: 'never read');
      final result = await OcrService(
        engine: engine,
      ).readImage('${workspace.path}/gone.jpg');

      expect(result.failure, OcrFailure.unreadableImage);
      expect(engine.calls, 0);
    });

    test('an empty path never reaches the reader', () async {
      final engine = _FakeEngine();
      final result = await OcrService(engine: engine).readImage('   ');

      expect(result.failure, OcrFailure.unreadableImage);
      expect(engine.calls, 0);
    });

    test('a picture past the cap is refused before the reader runs', () async {
      final engine = _FakeEngine(text: 'never read');
      final result = await OcrService(
        engine: engine,
        maxImageBytes: 100,
      ).readImage(photo);

      expect(result.failure, OcrFailure.imageTooLarge);
      expect(engine.calls, 0);
    });

    test('a reader that throws gives an engine failure', () async {
      final result = await OcrService(
        engine: _FakeEngine(throws: Exception('native crash')),
      ).readImage(photo);

      expect(result.failure, OcrFailure.engineFailed);
      expect(result.text, isEmpty);
    });

    // Worth telling apart: this one means the app was built wrong, and the
    // user needs a different message from "it did not work".
    test('missing language data is named as such', () async {
      final result = await OcrService(
        engine: _FakeEngine(
          throws: Exception('Failed loading eng.traineddata'),
        ),
      ).readImage(photo);

      expect(result.failure, OcrFailure.missingLanguageData);
    });

    test('a reader that hangs is given up on', () async {
      final result = await OcrService(
        engine: _FakeEngine(text: 'x', delay: const Duration(seconds: 5)),
        timeout: const Duration(milliseconds: 50),
      ).readImage(photo);

      expect(result.failure, OcrFailure.timedOut);
    });

    test('a failed result carries the language that was asked for', () async {
      final result = await OcrService(
        engine: _FakeEngine(throws: StateError('gone')),
      ).readImage(photo, language: OcrLanguage.malayalam);

      expect(result.language, OcrLanguage.malayalam);
    });
  });

  // Text read out of someone's photo can be a payslip or a prescription. It
  // must not be able to reach a log line through a stray interpolation.
  test('the result never prints the text it holds', () {
    const result = OcrResult(
      text: 'Account 1234 5678, balance 40000',
      language: OcrLanguage.english,
    );

    expect(result.toString(), isNot(contains('Account')));
    expect(result.toString(), isNot(contains('1234')));
    expect(result.toString(), contains('32 chars'));
  });
}
