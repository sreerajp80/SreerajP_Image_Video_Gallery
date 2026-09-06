import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AtomicSaver Utility', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('atomic_saver_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'writeBytes atomically writes payload and creates parent dirs',
      () async {
        final targetPath = p.join(tempDir.path, 'nested', 'dir', 'sample.txt');
        final bytes = Uint8List.fromList('Hello Gallery'.codeUnits);

        final file = await AtomicSaver.writeBytes(targetPath, bytes);

        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), 'Hello Gallery');
        expect(await file.length(), bytes.length);
      },
    );

    test('writeString atomically writes UTF-8 text', () async {
      final targetPath = p.join(tempDir.path, 'string_test.txt');
      final file = await AtomicSaver.writeString(
        targetPath,
        'Safe Staging Content',
      );

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'Safe Staging Content');
    });

    test('writeString round-trips text that is not ASCII', () async {
      // The app ships in Malayalam, so anything above one byte per character
      // has to survive the trip. Encoding with String.codeUnits would cut
      // every one of these down to a single byte and destroy the file
      // silently, with the damage only visible on the next read.
      const text = 'മലയാളം കുറിപ്പ് — مرحبا — 📷';

      final file = await AtomicSaver.writeString(
        p.join(tempDir.path, 'malayalam.txt'),
        text,
      );

      expect(await file.readAsString(), text);
      // Written as UTF-8, so the file is longer than the character count.
      expect(await file.length(), greaterThan(text.length));
    });

    test(
      'overwrites existing file safely without leaving leftover tmp files',
      () async {
        final targetPath = p.join(tempDir.path, 'overwrite_target.bin');
        await AtomicSaver.writeString(targetPath, 'Initial Data');

        final updatedFile = await AtomicSaver.writeString(
          targetPath,
          'Overwritten Data',
        );
        expect(await updatedFile.readAsString(), 'Overwritten Data');

        final dirFiles = tempDir.listSync();
        expect(dirFiles.length, 1);
        expect(p.basename(dirFiles.first.path), 'overwrite_target.bin');
      },
    );

    test('copyAtomic safely duplicates file via atomic swap', () async {
      final sourcePath = p.join(tempDir.path, 'source.dat');
      final destinationPath = p.join(tempDir.path, 'copied', 'destination.dat');

      await AtomicSaver.writeString(sourcePath, 'Data to be copied');
      final copied = await AtomicSaver.copyAtomic(sourcePath, destinationPath);

      expect(await copied.exists(), isTrue);
      expect(await copied.readAsString(), 'Data to be copied');
      expect(await File(sourcePath).exists(), isTrue);
    });

    test('safeDelete removes file without throwing if file absent', () async {
      final path = p.join(tempDir.path, 'non_existent_file.tmp');
      final result = await AtomicSaver.safeDelete(path);
      expect(result, isFalse);

      final realPath = p.join(tempDir.path, 'real_file.tmp');
      await AtomicSaver.writeString(realPath, 'Temp');
      final deleted = await AtomicSaver.safeDelete(realPath);
      expect(deleted, isTrue);
      expect(await File(realPath).exists(), isFalse);
    });
  });
}
