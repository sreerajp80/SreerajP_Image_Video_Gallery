import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_protocol.dart';

void main() {
  group('TransferProtocol.encode', () {
    test('writes a big-endian length, a type byte, then the body', () {
      final frame = TransferProtocol.encode(FrameType.fileChunk, <int>[
        1,
        2,
        3,
      ]);

      expect(frame.length, TransferProtocol.headerBytes + 3);
      expect(
        ByteData.sublistView(frame).getUint32(0, Endian.big),
        3,
        reason: 'the prefix counts the body only',
      );
      expect(frame[4], FrameType.fileChunk.wireValue);
      expect(frame.sublist(5), <int>[1, 2, 3]);
    });

    test('encodes an empty body', () {
      final frame = TransferProtocol.encode(FrameType.complete, const <int>[]);
      expect(frame.length, TransferProtocol.headerBytes);
      expect(ByteData.sublistView(frame).getUint32(0, Endian.big), 0);
    });

    test('refuses a body over the frame cap', () {
      final tooBig = Uint8List(AppConstants.syncMaxFrameBytes + 1);
      expect(
        () => TransferProtocol.encode(FrameType.fileChunk, tooBig),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('encodeJson round trips through the reader', () {
      final frame = TransferProtocol.encodeJson(FrameType.manifest, {
        'fileCount': 3,
        'name': 'a phone',
      });

      final frames = FrameReader().add(frame);
      expect(frames, hasLength(1));
      expect(frames.first.type, FrameType.manifest);
      expect(frames.first.json?['fileCount'], 3);
      expect(frames.first.json?['name'], 'a phone');
    });

    test('encodeError carries a code and nothing else', () {
      final frame = TransferProtocol.encodeError('handshake_rejected');
      final decoded = FrameReader().add(frame).single;

      expect(decoded.type, FrameType.error);
      expect(decoded.json, <String, dynamic>{'code': 'handshake_rejected'});
    });
  });

  group('FrameReader', () {
    test('reads one whole frame from one write', () {
      final reader = FrameReader();
      final frames = reader.add(
        TransferProtocol.encode(FrameType.hello, utf8.encode('hi')),
      );

      expect(frames, hasLength(1));
      expect(frames.single.type, FrameType.hello);
      expect(utf8.decode(frames.single.body), 'hi');
      expect(reader.pendingBytes, 0);
    });

    test('reads several frames arriving in one write', () {
      final reader = FrameReader();
      final wire = <int>[
        ...TransferProtocol.encode(FrameType.fileStart, const <int>[0]),
        ...TransferProtocol.encode(FrameType.fileChunk, const <int>[9, 9]),
        ...TransferProtocol.encode(FrameType.fileEnd, const <int>[]),
      ];

      final frames = reader.add(wire);
      expect(frames.map((f) => f.type), <FrameType>[
        FrameType.fileStart,
        FrameType.fileChunk,
        FrameType.fileEnd,
      ]);
    });

    test('reassembles one frame split across many writes', () {
      // This is the case TCP actually produces and the reason the reader
      // buffers at all: a socket may hand over any slice of the stream.
      final reader = FrameReader();
      final wire = TransferProtocol.encode(
        FrameType.fileChunk,
        List<int>.generate(300, (i) => i % 256),
      );

      final collected = <TransferFrame>[];
      for (var i = 0; i < wire.length; i++) {
        collected.addAll(reader.add(<int>[wire[i]]));
      }

      expect(collected, hasLength(1));
      expect(collected.single.type, FrameType.fileChunk);
      expect(collected.single.body, hasLength(300));
      expect(collected.single.body[299], 299 % 256);
    });

    test('holds a partial frame back until the rest arrives', () {
      final reader = FrameReader();
      final wire = TransferProtocol.encode(
        FrameType.manifest,
        utf8.encode('{"entries":[]}'),
      );

      // Everything but the final byte.
      expect(reader.add(wire.sublist(0, wire.length - 1)), isEmpty);
      expect(reader.pendingBytes, wire.length - 1);

      final frames = reader.add(wire.sublist(wire.length - 1));
      expect(frames, hasLength(1));
      expect(frames.single.json?['entries'], isEmpty);
      expect(reader.pendingBytes, 0);
    });

    test('returns nothing for a header that is not complete yet', () {
      final reader = FrameReader();
      expect(reader.add(<int>[0, 0]), isEmpty);
      expect(reader.add(const <int>[]), isEmpty);
      expect(reader.pendingBytes, 2);
    });

    test('keeps a trailing partial frame after complete ones', () {
      final reader = FrameReader();
      final whole = TransferProtocol.encode(FrameType.fileAck, const <int>[1]);
      final partial = TransferProtocol.encode(FrameType.fileChunk, const <int>[
        7,
        7,
        7,
      ]);

      final frames = reader.add(<int>[
        ...whole,
        ...partial.sublist(0, partial.length - 2),
      ]);

      expect(frames, hasLength(1));
      expect(frames.single.type, FrameType.fileAck);
      expect(reader.pendingBytes, partial.length - 2);

      final rest = reader.add(partial.sublist(partial.length - 2));
      expect(rest.single.body, <int>[7, 7, 7]);
    });

    test('refuses a frame the peer claims is over the cap', () {
      // The check has to happen on the announced length, before any body is
      // read, or a hostile peer gets to name an allocation size.
      final reader = FrameReader(maxFrameBytes: 64);
      final header = Uint8List(TransferProtocol.headerBytes);
      ByteData.sublistView(header).setUint32(0, 1 << 20, Endian.big);
      header[4] = FrameType.fileChunk.wireValue;

      expect(
        () => reader.add(header),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('refuses an unknown frame type', () {
      final reader = FrameReader();
      final wire = Uint8List(TransferProtocol.headerBytes);
      ByteData.sublistView(wire).setUint32(0, 0, Endian.big);
      wire[4] = 200;

      expect(() => reader.add(wire), throwsA(isA<TransferProtocolException>()));
    });

    test('reset drops a half-read frame', () {
      final reader = FrameReader();
      reader.add(<int>[0, 0, 0]);
      expect(reader.pendingBytes, 3);

      reader.reset();
      expect(reader.pendingBytes, 0);
    });

    test('a frame exactly at the cap is accepted', () {
      final reader = FrameReader(maxFrameBytes: 16);
      final frames = reader.add(
        TransferProtocol.encode(FrameType.fileChunk, Uint8List(16)),
      );
      expect(frames.single.body, hasLength(16));
    });
  });

  group('FrameType', () {
    test('every wire value is unique and maps back', () {
      final seen = <int>{};
      for (final type in FrameType.values) {
        expect(
          seen.add(type.wireValue),
          isTrue,
          reason: 'duplicate wire value',
        );
        expect(FrameType.fromWire(type.wireValue), type);
      }
    });

    test('an unused value maps to null', () {
      expect(FrameType.fromWire(0), isNull);
      expect(FrameType.fromWire(99), isNull);
    });
  });

  group('TransferFrame.json', () {
    test('returns null for a body that is not JSON', () {
      final frame = TransferFrame(
        FrameType.fileChunk,
        Uint8List.fromList(<int>[0xFF, 0xFE]),
      );
      expect(frame.json, isNull);
    });

    test('returns null for JSON that is not an object', () {
      final frame = TransferFrame(
        FrameType.manifest,
        Uint8List.fromList(utf8.encode('[1,2,3]')),
      );
      expect(frame.json, isNull);
    });
  });
}
