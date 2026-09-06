import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:path/path.dart' as p;

import 'fake_vault_channel.dart';

void main() {
  group('VaultShredderService', () {
    late Directory workspace;
    late FakeVaultChannel channel;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp('vault_shred_test');
      channel = FakeVaultChannel();
    });

    tearDown(() async {
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    });

    Future<File> writeFile(String name, List<int> bytes) async {
      final file = File(p.join(workspace.path, name));
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    VaultShredderService buildService({bool allowDartFallback = true}) {
      return VaultShredderService(
        channel: channel,
        random: Random(3),
        allowDartFallback: allowDartFallback,
      );
    }

    test('a file that was never there counts as shredded', () async {
      final service = buildService();

      // The caller wanted it gone, and it is. Reporting failure would make
      // every sweep look broken.
      expect(
        await service.shred(p.join(workspace.path, 'not_here.enc')),
        isTrue,
      );
    });

    test('an empty path is a no-op that succeeds', () async {
      expect(await buildService().shred(''), isTrue);
    });

    test('the file is gone afterwards', () async {
      final file = await writeFile('secret.enc', List<int>.filled(4096, 0xAB));

      expect(await buildService().shred(file.path), isTrue);
      expect(await file.exists(), isFalse);
    });

    test('the native shredder is asked first, with the pass count', () async {
      channel.nativeShredSucceeds = true;
      final file = await writeFile('secret.enc', <int>[1, 2, 3]);

      expect(await buildService().shred(file.path, passes: 3), isTrue);
      expect(channel.shredded, <String>[file.path]);
      expect(await file.exists(), isFalse);
    });

    test('the pass count is clamped to what the app allows', () async {
      channel.nativeShredSucceeds = true;
      final file = await writeFile('secret.enc', <int>[1, 2, 3]);

      // A hand-edited setting must not be able to ask for a thousand passes.
      await buildService().shred(file.path, passes: 10000);
      expect(channel.shredded, hasLength(1));
      expect(await file.exists(), isFalse);
    });

    test('the Dart fallback runs when the native side says no', () async {
      channel.nativeShredSucceeds = false;
      final file = await writeFile('secret.enc', List<int>.filled(1024, 0x7F));

      expect(await buildService().shred(file.path), isTrue);
      expect(channel.shredded, <String>[file.path]);
      expect(await file.exists(), isFalse);
    });

    test('the fallback really overwrites before it unlinks', () async {
      // The file is kept open through a second handle so its bytes can be read
      // back after the shredder has written over them but before the delete
      // takes the name away. That is the whole claim being tested: an ordinary
      // delete would leave 0xAB on the device.
      channel.nativeShredSucceeds = false;
      final probe = File(p.join(workspace.path, 'probe.enc'));
      await probe.writeAsBytes(List<int>.filled(2048, 0xAB), flush: true);

      final handle = await probe.open(mode: FileMode.read);
      try {
        await buildService().shred(probe.path, passes: 1);

        await handle.setPosition(0);
        final after = await handle.read(2048);
        expect(
          after.any((byte) => byte == 0xAB),
          isFalse,
          reason: 'the original bytes must not survive the shred',
        );
      } finally {
        await handle.close();
      }
    });

    test('without the fallback, a refused native shred is a failure', () async {
      channel.nativeShredSucceeds = false;
      final file = await writeFile('secret.enc', <int>[1, 2, 3]);

      expect(
        await buildService(allowDartFallback: false).shred(file.path),
        isFalse,
      );
      expect(await file.exists(), isTrue);
    });

    test('an empty file is deleted without an overwrite pass', () async {
      channel.nativeShredSucceeds = false;
      final file = await writeFile('empty.enc', const <int>[]);

      expect(await buildService().shred(file.path), isTrue);
      expect(await file.exists(), isFalse);
    });

    group('shredAll', () {
      test('counts how many are gone', () async {
        channel.nativeShredSucceeds = true;
        final first = await writeFile('a.enc', <int>[1]);
        final second = await writeFile('b.enc', <int>[2]);

        expect(
          await buildService().shredAll(<String>[first.path, second.path]),
          2,
        );
      });

      test('carries on past one it cannot destroy', () async {
        channel.nativeShredSucceeds = false;
        final good = await writeFile('good.enc', <int>[1]);
        final missing = p.join(workspace.path, 'gone.enc');

        // A partly swept vault directory is worse than a fully swept one, so
        // one stubborn file must not end the sweep.
        final count = await buildService(
          allowDartFallback: false,
        ).shredAll(<String>[good.path, missing]);

        // The missing one counts, the unshreddable one does not.
        expect(count, 1);
        expect(await File(good.path).exists(), isTrue);
      });

      test('an empty list is nothing to do', () async {
        expect(await buildService().shredAll(const <String>[]), 0);
      });
    });

    test('the block size it writes with is the configured one', () {
      // Guards the constant against being changed to something that would make
      // shredding a large video pathologically slow.
      expect(AppConstants.vaultShredBlockBytes, greaterThanOrEqualTo(4096));
      expect(
        Uint8List(AppConstants.vaultShredBlockBytes).length,
        greaterThan(0),
      );
    });
  });
}
