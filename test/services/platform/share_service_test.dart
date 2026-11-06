import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/share_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory cache;
  late ShareService service;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('share_service_test');
    service = ShareService(cacheDirectory: () async => cache);
  });

  tearDown(() {
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  String shareFolder() => p.join(cache.path, ShareService.shareFolderName);

  test('writes the file into the share folder', () async {
    final file = await service.writeShareFile(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      filename: 'scrubbed_photo.jpg',
    );

    expect(file, isNotNull);
    expect(p.dirname(file!.path), shareFolder());
    expect(file.readAsBytesSync(), <int>[1, 2, 3]);
  });

  test(
    'keeps only the name part, so the file cannot leave the folder',
    () async {
      for (final name in <String>[
        '../../escape.jpg',
        r'..\..\escape.jpg',
        '/abs/escape.jpg',
      ]) {
        final file = await service.writeShareFile(
          bytes: Uint8List.fromList(<int>[9]),
          filename: name,
        );

        expect(file, isNotNull, reason: name);
        expect(p.dirname(file!.path), shareFolder(), reason: name);
        expect(p.basename(file.path), 'escape.jpg', reason: name);
      }
      expect(
        File(p.join(cache.parent.path, 'escape.jpg')).existsSync(),
        isFalse,
      );
    },
  );

  test('refuses a name with no file part', () async {
    for (final name in <String>['', '.', '..']) {
      final file = await service.writeShareFile(
        bytes: Uint8List.fromList(<int>[9]),
        filename: name,
      );
      expect(file, isNull, reason: name);
    }
  });
}
