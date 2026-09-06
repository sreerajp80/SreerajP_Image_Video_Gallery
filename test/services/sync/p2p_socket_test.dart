import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_client_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_server_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_exchange_service.dart';
import 'package:path/path.dart' as p;

/// Stands in for the Android cipher so a real client and server can talk.
///
/// It is not AES, and it is not pretending to be: the actual encryption is
/// the platform's and is not this project's to unit test. What it does keep
/// is the property the protocol depends on — a frame sealed under one key
/// cannot be opened with another — so the handshake, the framing and every
/// refusal path are exercised for real over a real socket.
void _installFakeCipher() {
  const tagLength = 16;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel(AppConstants.backupChannelName),
        (call) async {
          switch (call.method) {
            case 'randomBytes':
              final length = call.arguments['length'] as int;
              return Uint8List.fromList(
                List<int>.generate(length, (i) => (i * 31 + 7) % 256),
              );

            case 'encryptWithKey':
              final key = call.arguments['key'] as Uint8List;
              final bytes = call.arguments['bytes'] as Uint8List;
              final iv = call.arguments['iv'] as Uint8List;

              final out = Uint8List(bytes.length + tagLength);
              for (var i = 0; i < bytes.length; i++) {
                out[i] = bytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
              }
              // A "tag" derived from the key, so a wrong key is detected.
              for (var i = 0; i < tagLength; i++) {
                out[bytes.length + i] = key[i % key.length];
              }
              return <Object?, Object?>{'bytes': out};

            case 'decryptWithKey':
              final key = call.arguments['key'] as Uint8List;
              final bytes = call.arguments['bytes'] as Uint8List;
              final iv = call.arguments['iv'] as Uint8List;

              if (bytes.length < tagLength) {
                throw PlatformException(code: 'wrong_password');
              }
              final bodyLength = bytes.length - tagLength;
              for (var i = 0; i < tagLength; i++) {
                if (bytes[bodyLength + i] != key[i % key.length]) {
                  throw PlatformException(code: 'wrong_password');
                }
              }

              final out = Uint8List(bodyLength);
              for (var i = 0; i < bodyLength; i++) {
                out[i] = bytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
              }
              return <Object?, Object?>{'bytes': out};

            default:
              return null;
          }
        },
      );
}

Uint8List _key(int seed) => Uint8List.fromList(
  List<int>.generate(AppConstants.syncSessionKeyBytes, (i) => (i + seed) % 256),
);

/// Writes received files into a temporary directory.
class _TempSink implements IncomingFileSink {
  final Directory root;
  final Set<String> have;
  final List<String> committed = <String>[];

  _TempSink(this.root, {Set<String>? have}) : have = have ?? <String>{};

  @override
  Future<bool> alreadyHave(String sha256) async => have.contains(sha256);

  @override
  Future<File> openStaging(TransferEntry entry) async {
    final file = File(
      p.join(
        root.path,
        'staging_${TransferExchangeService.safeFileName(entry.displayName)}',
      ),
    );
    await file.parent.create(recursive: true);
    return file;
  }

  @override
  Future<String> commit(TransferEntry entry, File staged) async {
    final target = File(
      p.join(
        root.path,
        TransferExchangeService.safeFileName(entry.displayName),
      ),
    );
    await staged.rename(target.path);
    committed.add(target.path);
    return target.path;
  }
}

/// Builds a manifest entry for a file that really exists.
Future<TransferEntry> _entryFor(File file, {String? name}) async {
  final bytes = await file.readAsBytes();
  return TransferEntry(
    sourceId: p.basename(file.path),
    displayName: name ?? p.basename(file.path),
    mimeType: 'image/jpeg',
    mediaTypeName: 'image',
    sizeBytes: bytes.length,
    sha256: TransferCryptoService.hexDigest(bytes),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    _installFakeCipher();
    temp = await Directory.systemTemp.createTemp('p2p_socket_test');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(AppConstants.backupChannelName),
          null,
        );
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// Starts a server on loopback and connects a client to it.
  Future<({P2pConnection server, P2pConnection client, P2pServerService svc})>
  pair({Uint8List? serverKey, Uint8List? clientKey}) async {
    final service = P2pServerService();
    final port = await service.start(address: '127.0.0.1');

    final serverFuture = service.waitForPeer(
      sessionKey: serverKey ?? _key(1),
      deviceName: 'Server Phone',
    );

    final client = P2pClientService();
    final clientFuture = client.connect(
      payload: PairingPayload(
        protocolVersion: AppConstants.syncProtocolVersion,
        host: '127.0.0.1',
        port: port,
        sessionKey: 'unused-here',
        deviceName: 'Client Phone',
        hostRole: SyncRole.send,
      ),
      sessionKey: clientKey ?? _key(1),
      deviceName: 'Client Phone',
    );

    // Both are awaited together. Awaiting one and then the other would leave
    // the second unobserved for a moment, and a handshake that fails on that
    // side would surface as an unhandled error rather than as this call
    // throwing — which is exactly what the wrong-key test needs to see.
    final both = await Future.wait<P2pConnection>(<Future<P2pConnection>>[
      serverFuture,
      clientFuture,
    ]);

    return (server: both[0], client: both[1], svc: service);
  }

  group('the listener binds only where it is allowed to', () {
    test('binds to loopback and reports a real port', () async {
      final service = P2pServerService();
      final port = await service.start(address: '127.0.0.1');

      expect(service.isListening, isTrue);
      expect(service.boundAddress, '127.0.0.1');
      expect(port, greaterThan(1024));
      expect(service.boundPort, port);

      await service.stop();
      expect(service.isListening, isFalse);
    });

    test('refuses 0.0.0.0, which would listen on every interface', () async {
      // This is the check that keeps the relaxed permission narrow.
      final service = P2pServerService();

      await expectLater(
        service.start(address: '0.0.0.0'),
        throwsA(
          isA<TransferSessionException>().having(
            (e) => e.failure,
            'failure',
            TransferFailure.remoteAddressRefused,
          ),
        ),
      );
      expect(service.isListening, isFalse);
    });

    test('refuses a public address', () async {
      final service = P2pServerService();

      await expectLater(
        service.start(address: '8.8.8.8'),
        throwsA(
          isA<TransferSessionException>().having(
            (e) => e.failure,
            'failure',
            TransferFailure.remoteAddressRefused,
          ),
        ),
      );
    });

    test('stop closes the port, and is safe to call twice', () async {
      final service = P2pServerService();
      final port = await service.start(address: '127.0.0.1');

      await service.stop();
      await service.stop();

      // The port is free again, which is what "the listener lives only as
      // long as the screen" has to mean in practice.
      final reopened = await ServerSocket.bind('127.0.0.1', port);
      await reopened.close();
    });
  });

  group('the client refuses to connect off the local network', () {
    test('will not open a socket to a public address', () async {
      // Refused before any socket is opened: a QR code is untrusted input.
      final client = P2pClientService();

      await expectLater(
        client.connect(
          payload: const PairingPayload(
            protocolVersion: AppConstants.syncProtocolVersion,
            host: '8.8.8.8',
            port: 45123,
            sessionKey: 'x',
            deviceName: 'Somewhere Else',
            hostRole: SyncRole.send,
          ),
          sessionKey: _key(1),
          deviceName: 'Me',
        ),
        throwsA(
          isA<TransferSessionException>().having(
            (e) => e.failure,
            'failure',
            TransferFailure.remoteAddressRefused,
          ),
        ),
      );
    });

    test('will not connect to a well-known port', () async {
      final client = P2pClientService();

      await expectLater(
        client.connect(
          payload: const PairingPayload(
            protocolVersion: AppConstants.syncProtocolVersion,
            host: '192.168.1.5',
            port: 443,
            sessionKey: 'x',
            deviceName: 'Nope',
            hostRole: SyncRole.send,
          ),
          sessionKey: _key(1),
          deviceName: 'Me',
        ),
        throwsA(isA<TransferSessionException>()),
      );
    });
  });

  group('handshake', () {
    test('two devices holding the same key pair successfully', () async {
      final paired = await pair();

      expect(paired.server.peerName, 'Client Phone');
      expect(paired.client.peerName, 'Server Phone');

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('a peer with the wrong key is refused', () async {
      // Somebody on the same Wi-Fi who never scanned the code. They can open
      // a socket, and that is as far as they get.
      await expectLater(
        pair(serverKey: _key(1), clientKey: _key(99)),
        throwsA(
          isA<TransferSessionException>().having(
            (e) => e.failure,
            'failure',
            TransferFailure.handshakeRejected,
          ),
        ),
      );
    });

    test('the listener closes once a peer is paired', () async {
      final paired = await pair();
      expect(
        paired.svc.isListening,
        isFalse,
        reason: 'the port should be gone for the whole of the transfer',
      );

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });
  });

  group('a real file crosses a real socket', () {
    test('one photo is sent, checked and committed', () async {
      final paired = await pair();
      final source = File(p.join(temp.path, 'IMG_1.jpg'));
      await source.writeAsBytes(
        List<int>.generate(200 * 1024, (i) => (i * 7) % 256),
      );

      final sink = _TempSink(Directory(p.join(temp.path, 'inbox')));
      final entry = await _entryFor(source);

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[entry]),
            fileFor: (_) async => source,
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: sink,
      ).receive(accept: (m) async => <int>{0});

      final sent = await sendFuture;
      final received = await receiveFuture;

      expect(sent.sentCount, 1);
      expect(sent.failedCount, 0);
      expect(received.receivedCount, 1);
      expect(sink.committed, hasLength(1));

      final landed = File(sink.committed.single);
      expect(await landed.readAsBytes(), await source.readAsBytes());

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('several files cross in order', () async {
      final paired = await pair();
      final sources = <File>[];
      final entries = <TransferEntry>[];

      for (var i = 0; i < 3; i++) {
        final file = File(p.join(temp.path, 'IMG_$i.jpg'));
        await file.writeAsBytes(List<int>.filled(1000 * (i + 1), i + 1));
        sources.add(file);
        entries.add(await _entryFor(file));
      }

      final sink = _TempSink(Directory(p.join(temp.path, 'inbox')));

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: entries),
            fileFor: (entry) async => sources.firstWhere(
              (f) => p.basename(f.path) == entry.displayName,
            ),
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: sink,
      ).receive(accept: (m) async => <int>{0, 1, 2});

      expect((await sendFuture).sentCount, 3);
      expect((await receiveFuture).receivedCount, 3);
      expect(sink.committed, hasLength(3));

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('the receiver may take only some of what is offered', () async {
      final paired = await pair();
      final entries = <TransferEntry>[];
      final sources = <File>[];

      for (var i = 0; i < 3; i++) {
        final file = File(p.join(temp.path, 'P_$i.jpg'));
        await file.writeAsBytes(List<int>.filled(500, i));
        sources.add(file);
        entries.add(await _entryFor(file));
      }

      final sink = _TempSink(Directory(p.join(temp.path, 'inbox')));

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: entries),
            fileFor: (entry) async => sources.firstWhere(
              (f) => p.basename(f.path) == entry.displayName,
            ),
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: sink,
      ).receive(accept: (m) async => <int>{1});

      expect((await sendFuture).sentCount, 1);
      final received = await receiveFuture;
      expect(received.receivedCount, 1);
      expect(sink.committed.single, endsWith('P_1.jpg'));

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('a file the receiver already has is never sent', () async {
      final paired = await pair();
      final source = File(p.join(temp.path, 'dup.jpg'));
      await source.writeAsBytes(List<int>.filled(400, 9));
      final entry = await _entryFor(source);

      final sink = _TempSink(
        Directory(p.join(temp.path, 'inbox')),
        have: <String>{entry.sha256},
      );

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[entry]),
            fileFor: (_) async => source,
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: sink,
      ).receive(accept: (m) async => <int>{0});

      expect((await sendFuture).sentCount, 0);
      final received = await receiveFuture;
      expect(received.receivedCount, 0);
      expect(received.skippedCount, 1);
      expect(sink.committed, isEmpty);

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('progress moves and ends at the full byte count', () async {
      final paired = await pair();
      final source = File(p.join(temp.path, 'big.jpg'));
      await source.writeAsBytes(List<int>.filled(300 * 1024, 3));
      final entry = await _entryFor(source);

      final seen = <int>[];

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[entry]),
            fileFor: (_) async => source,
          );

      final receiveFuture =
          TransferExchangeService(
            connection: paired.client,
            sink: _TempSink(Directory(p.join(temp.path, 'inbox'))),
          ).receive(
            accept: (m) async => <int>{0},
            onProgress: (progress) => seen.add(progress.bytesDone),
          );

      await sendFuture;
      await receiveFuture;

      expect(seen.length, greaterThan(2), reason: 'it arrived in chunks');
      expect(seen.last, entry.sizeBytes);
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });
  });

  group('the receiver refuses what it should not accept', () {
    test(
      'a file whose bytes do not match its promised digest is dropped',
      () async {
        // Nothing gets into the gallery on the sender's word alone.
        final paired = await pair();
        final source = File(p.join(temp.path, 'lying.jpg'));
        await source.writeAsBytes(List<int>.filled(600, 4));

        final real = await _entryFor(source);
        final lying = TransferEntry(
          sourceId: real.sourceId,
          displayName: real.displayName,
          mimeType: real.mimeType,
          mediaTypeName: real.mediaTypeName,
          sizeBytes: real.sizeBytes,
          sha256: 'f' * 64,
        );

        final sink = _TempSink(Directory(p.join(temp.path, 'inbox')));

        final sendFuture =
            TransferExchangeService(
              connection: paired.server,
              sink: _TempSink(temp),
            ).send(
              manifest: TransferManifest(entries: <TransferEntry>[lying]),
              fileFor: (_) async => source,
            );

        final receiveFuture = TransferExchangeService(
          connection: paired.client,
          sink: sink,
        ).receive(accept: (m) async => <int>{0});

        expect((await sendFuture).failedCount, 1);
        final received = await receiveFuture;
        expect(received.receivedCount, 0);
        expect(received.failedCount, 1);
        expect(sink.committed, isEmpty, reason: 'nothing reached the gallery');

        await paired.client.close();
        await paired.server.close();
        await paired.svc.stop();
      },
    );

    test('a file shorter than promised is dropped', () async {
      final paired = await pair();
      final source = File(p.join(temp.path, 'short.jpg'));
      await source.writeAsBytes(List<int>.filled(100, 1));

      final real = await _entryFor(source);
      final overstated = TransferEntry(
        sourceId: real.sourceId,
        displayName: real.displayName,
        mimeType: real.mimeType,
        mediaTypeName: real.mediaTypeName,
        sizeBytes: 999999,
        sha256: real.sha256,
      );

      final sink = _TempSink(Directory(p.join(temp.path, 'inbox')));

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[overstated]),
            fileFor: (_) async => source,
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: sink,
      ).receive(accept: (m) async => <int>{0});

      await sendFuture;
      expect((await receiveFuture).failedCount, 1);
      expect(sink.committed, isEmpty);

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('a file bigger than the cap is never agreed to', () async {
      final paired = await pair();
      final huge = TransferEntry(
        sourceId: 'x',
        displayName: 'huge.mp4',
        mimeType: 'video/mp4',
        mediaTypeName: 'video',
        sizeBytes: AppConstants.syncMaxFileBytes + 1,
        sha256: 'a' * 64,
      );

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[huge]),
            fileFor: (_) async => null,
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: _TempSink(Directory(p.join(temp.path, 'inbox'))),
      ).receive(accept: (m) async => <int>{0});

      expect((await sendFuture).sentCount, 0);
      expect((await receiveFuture).skippedCount, 1);

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });

    test('a file the sender no longer has is reported, not fatal', () async {
      final paired = await pair();
      final gone = File(p.join(temp.path, 'gone.jpg'));
      await gone.writeAsBytes(List<int>.filled(200, 2));
      final entry = await _entryFor(gone);
      await gone.delete();

      final sendFuture =
          TransferExchangeService(
            connection: paired.server,
            sink: _TempSink(temp),
          ).send(
            manifest: TransferManifest(entries: <TransferEntry>[entry]),
            fileFor: (_) async => gone,
          );

      final receiveFuture = TransferExchangeService(
        connection: paired.client,
        sink: _TempSink(Directory(p.join(temp.path, 'inbox'))),
      ).receive(accept: (m) async => <int>{0});

      expect((await sendFuture).failedCount, 1);
      expect((await receiveFuture).failedCount, 1);

      await paired.client.close();
      await paired.server.close();
      await paired.svc.stop();
    });
  });

  group('file names from a peer are never trusted', () {
    test('a traversal attempt becomes a plain name', () {
      expect(
        TransferExchangeService.safeFileName('../../etc/passwd'),
        'passwd',
      );
      expect(
        TransferExchangeService.safeFileName(r'..\..\windows\system32\a.dll'),
        'a.dll',
      );
      expect(TransferExchangeService.safeFileName('/etc/shadow'), 'shadow');
    });

    test('leading dots are stripped, so nothing lands hidden', () {
      expect(TransferExchangeService.safeFileName('.nomedia'), 'nomedia');
      expect(TransferExchangeService.safeFileName('...a.jpg'), 'a.jpg');
    });

    test('control characters are removed', () {
      expect(
        TransferExchangeService.safeFileName('bad name.jpg'),
        'badname.jpg',
      );
    });

    test('an empty or all-stripped name still gets one', () {
      expect(TransferExchangeService.safeFileName(''), 'received_file');
      expect(TransferExchangeService.safeFileName('///'), 'received_file');
      expect(TransferExchangeService.safeFileName('...'), 'received_file');
    });

    test('an absurdly long name is trimmed', () {
      final name = TransferExchangeService.safeFileName('${'a' * 500}.jpg');
      expect(name.length, lessThanOrEqualTo(120));
    });

    test('an ordinary name is left alone', () {
      expect(
        TransferExchangeService.safeFileName('IMG_20260830_120000.jpg'),
        'IMG_20260830_120000.jpg',
      );
      expect(TransferExchangeService.safeFileName('ഫോട്ടോ.jpg'), 'ഫോട്ടോ.jpg');
    });
  });

  group('the handshake proof', () {
    test('verifies under the right key and fails under a wrong one', () {
      final challenge = Uint8List.fromList(utf8.encode('a challenge'));
      final proof = TransferCryptoService.proofFor(
        key: _key(1),
        challenge: challenge,
      );

      expect(
        TransferCryptoService.verifyProof(
          key: _key(1),
          challenge: challenge,
          proof: proof,
        ),
        isTrue,
      );
      expect(
        TransferCryptoService.verifyProof(
          key: _key(2),
          challenge: challenge,
          proof: proof,
        ),
        isFalse,
      );
    });

    test('is tied to the challenge', () {
      final proof = TransferCryptoService.proofFor(
        key: _key(1),
        challenge: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(
        TransferCryptoService.verifyProof(
          key: _key(1),
          challenge: Uint8List.fromList(<int>[4, 5, 6]),
          proof: proof,
        ),
        isFalse,
      );
    });

    test('is tied to the protocol version', () {
      final challenge = Uint8List.fromList(<int>[7, 7, 7]);
      final proof = TransferCryptoService.proofFor(
        key: _key(1),
        challenge: challenge,
        protocolVersion: 1,
      );

      expect(
        TransferCryptoService.verifyProof(
          key: _key(1),
          challenge: challenge,
          proof: proof,
          protocolVersion: 2,
        ),
        isFalse,
      );
    });

    test('a proof of the wrong length is refused, not compared', () {
      expect(
        TransferCryptoService.verifyProof(
          key: _key(1),
          challenge: Uint8List.fromList(<int>[1]),
          proof: Uint8List(0),
        ),
        isFalse,
      );
    });
  });
}
