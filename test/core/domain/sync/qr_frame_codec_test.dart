import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/qr_frame_codec.dart';

Uint8List _bytes(int length) =>
    Uint8List.fromList(List<int>.generate(length, (i) => (i * 7) % 256));

void main() {
  group('the key code', () {
    final key = QrSyncKey(
      sessionId: '0a1b2c3d',
      key: _bytes(AppConstants.syncSessionKeyBytes),
    );

    test('round-trips', () {
      final back = QrFrameCodec.decodeKey(QrFrameCodec.encodeKey(key))!;
      expect(back.sessionId, key.sessionId);
      expect(back.key, key.key);
    });

    test('refuses codes that are not ours', () {
      expect(QrFrameCodec.decodeKey('https://example.com'), isNull);
      expect(QrFrameCodec.decodeKey('DRISHYA-QK1|bad|AAAA'), isNull);
    });

    test('refuses a key of the wrong length', () {
      final short = QrSyncKey(sessionId: '0a1b2c3d', key: _bytes(8));
      expect(QrFrameCodec.decodeKey(QrFrameCodec.encodeKey(short)), isNull);
    });
  });

  group('frames', () {
    test('split and collected in any order give back the same bytes', () {
      final data = _bytes(AppConstants.qrSyncFrameDataBytes * 3 + 17);
      final frames = QrFrameCodec.split(data, 'deadbeef');
      expect(frames, hasLength(4));

      final collector = QrFrameCollector(sessionId: 'deadbeef');
      for (final frame in frames.reversed) {
        expect(collector.add(frame), isTrue);
      }
      expect(collector.isComplete, isTrue);
      expect(collector.assemble(), data);
    });

    test('a repeated frame is not counted twice', () {
      final frames = QrFrameCodec.split(_bytes(900), 'deadbeef');
      final collector = QrFrameCollector(sessionId: 'deadbeef');
      expect(collector.add(frames.first), isTrue);
      expect(collector.add(frames.first), isFalse);
      expect(collector.received, 1);
      expect(collector.assemble(), isNull);
    });

    test('a frame from another session is ignored', () {
      final frames = QrFrameCodec.split(_bytes(10), 'aaaaaaaa');
      final collector = QrFrameCollector(sessionId: 'bbbbbbbb');
      expect(collector.add(frames.first), isFalse);
    });

    test('a misread frame fails its check and is dropped', () {
      final frame = QrFrameCodec.split(_bytes(10), 'deadbeef').first;
      final damaged = '${frame.substring(0, frame.length - 2)}xx';
      final collector = QrFrameCollector(sessionId: 'deadbeef');
      expect(collector.add(damaged), isFalse);
    });

    test('a sender claiming too many frames is refused', () {
      const raw =
          'DRISHYA-QD1|deadbeef|0|${AppConstants.qrSyncMaxFrames + 1}|00000000|AA';
      final collector = QrFrameCollector(sessionId: 'deadbeef');
      expect(collector.add(raw), isFalse);
    });

    test('frame count matches the size', () {
      expect(QrFrameCodec.frameCountFor(0), 0);
      expect(QrFrameCodec.frameCountFor(1), 1);
      expect(
        QrFrameCodec.frameCountFor(AppConstants.qrSyncFrameDataBytes + 1),
        2,
      );
    });
  });
}
