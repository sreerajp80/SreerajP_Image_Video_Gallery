import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/ocr_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_engine.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_service.dart';

/// Returns fixed text and records what it was asked to read.
class _FakeEngine implements OcrEngine {
  final List<OcrLanguage> languages = <OcrLanguage>[];
  final List<String> paths = <String>[];

  @override
  Future<String> readText(String imagePath, OcrLanguage language) async {
    paths.add(imagePath);
    languages.add(language);
    return 'Hello world';
  }
}

void main() {
  late _FakeEngine engine;
  late ProviderContainer container;
  late Directory directory;

  setUp(() async {
    engine = _FakeEngine();
    directory = await Directory.systemTemp.createTemp('ocr_providers_test');
    container = ProviderContainer(
      overrides: <Override>[ocrEngineProvider.overrideWithValue(engine)],
    );
    // Keeps the auto-dispose controller alive for the whole test.
    container.listen(ocrControllerProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('the service is built over the engine and the cleaner', () {
    expect(container.read(ocrServiceProvider), isA<OcrService>());
  });

  test('English is the starting language', () {
    expect(container.read(ocrLanguageProvider), OcrLanguage.english);
  });

  test('starts with no result', () {
    expect(container.read(ocrControllerProvider).value, isNull);
  });

  test('reads with the language the user picked', () async {
    final image = File('${directory.path}/page.png');
    await image.writeAsBytes(<int>[1, 2, 3]);
    container.read(ocrLanguageProvider.notifier).state = OcrLanguage.malayalam;

    await container.read(ocrControllerProvider.notifier).read(image.path);

    expect(engine.languages, <OcrLanguage>[OcrLanguage.malayalam]);
    final result = container.read(ocrControllerProvider).value;
    expect(result, isNotNull);
    expect(result!.failure, isNull);
    expect(result.text, contains('Hello'));
  });

  test('a missing file comes back as a failed result, not an error', () async {
    await container
        .read(ocrControllerProvider.notifier)
        .read('${directory.path}/missing.png');

    final state = container.read(ocrControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.value!.failure, OcrFailure.unreadableImage);
    expect(engine.paths, isEmpty);
  });

  test('reset clears the result', () async {
    await container.read(ocrControllerProvider.notifier).read('');
    container.read(ocrControllerProvider.notifier).reset();

    expect(container.read(ocrControllerProvider).value, isNull);
  });
}
