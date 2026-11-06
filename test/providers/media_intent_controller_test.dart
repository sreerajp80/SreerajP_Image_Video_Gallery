import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/intent/media_intent_service.dart';

/// Never touched: the fake service below answers every lookup itself.
class _UnusedRepository implements MediaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeIntentService extends MediaIntentService {
  MediaIntentData? initial;
  bool failResolve = false;
  final StreamController<MediaIntentData> later =
      StreamController<MediaIntentData>.broadcast();

  _FakeIntentService()
    : super(channel: const MethodChannel('test/media_intent_controller'));

  @override
  Future<MediaIntentData?> getInitialMediaIntent() async => initial;

  @override
  Stream<MediaIntentData> get incomingIntents => later.stream;

  @override
  void dispose() {
    later.close();
    super.dispose();
  }

  @override
  Future<MediaItem> resolveMediaItem(
    MediaIntentData data,
    MediaRepository repository,
  ) async {
    if (failResolve) throw const FileSystemExceptionStub();
    return MediaItem(
      id: 'ext_1',
      path: '/shared/photo.jpg',
      uri: data.uri,
      displayName: 'photo.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 10,
      dateAdded: DateTime(2026),
      dateModified: DateTime(2026),
    );
  }
}

class FileSystemExceptionStub implements Exception {
  const FileSystemExceptionStub();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const link = MediaIntentData(
    uri: 'content://media/external/images/media/1',
    mimeType: 'image/jpeg',
    displayName: 'photo.jpg',
    size: 10,
    isVideo: false,
  );

  late _FakeIntentService service;
  late ExternalMediaRegistry registry;
  late List<String> opened;
  late MediaIntentController controller;

  setUp(() {
    service = _FakeIntentService();
    registry = ExternalMediaRegistry();
    opened = <String>[];
    controller = MediaIntentController(
      service: service,
      repository: _UnusedRepository(),
      registry: registry,
      open: opened.add,
    );
  });

  tearDown(() {
    controller.dispose();
    service.dispose();
  });

  test('an allowed link opens the viewer', () async {
    expect(await controller.handle(link), MediaIntentOutcome.opened);
    expect(opened.single, endsWith('/ext_1'));
    expect(registry.state.keys, contains('ext_1'));
  });

  test('a refused link opens nothing and is reported as refused', () async {
    expect(
      await controller.handle(const MediaIntentData.refused()),
      MediaIntentOutcome.refused,
    );
    expect(opened, isEmpty);
  });

  test('a link that cannot be read is reported as failed', () async {
    service.failResolve = true;
    expect(await controller.handle(link), MediaIntentOutcome.failed);
    expect(opened, isEmpty);
  });

  test('start reports problems from the launch link and later links', () async {
    service.initial = const MediaIntentData.refused();
    final problems = <MediaIntentOutcome>[];
    await controller.start(onProblem: problems.add);
    expect(problems, <MediaIntentOutcome>[MediaIntentOutcome.refused]);

    service.later.add(link);
    await Future<void>.delayed(Duration.zero);
    expect(opened, hasLength(1));
    expect(problems, hasLength(1), reason: 'an opened link is not a problem');
  });

  test('a refusal from Kotlin carries nothing about the link', () {
    final data = MediaIntentData.fromMap(const <String, dynamic>{
      'refused': true,
      'uri': 'content://should-be-ignored',
    });
    expect(data.refused, isTrue);
    expect(data.uri, isEmpty);
    expect(data.isActionable, isTrue);
  });
}
