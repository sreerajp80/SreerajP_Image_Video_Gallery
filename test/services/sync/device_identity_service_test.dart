import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/peer_info.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/device_identity_service.dart';

class _MemoryStore implements InstallIdStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

void main() {
  group('the install id', () {
    test('is made once and then kept', () async {
      final store = _MemoryStore();
      final first = await DeviceIdentityService(
        store: store,
        random: Random(1),
      ).installId();
      final again = await DeviceIdentityService(
        store: store,
        random: Random(2),
      ).installId();

      expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(again, first);
      expect(store.writes, 1);
    });

    test('a damaged stored value is replaced', () async {
      final store = _MemoryStore()..value = 'not-an-id';
      final id = await DeviceIdentityService(store: store).installId();
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });

  group('what a peer says about itself', () {
    test('round-trips', () {
      const info = PeerInfo(installId: 'abc-123', freeBytes: 42);
      expect(PeerInfo.fromJson(info.toJson()), info);
    });

    test('an id that could not be a key is refused', () {
      expect(PeerInfo.fromJson({'installId': "x'; DROP TABLE"}), isNull);
      expect(PeerInfo.fromJson({'installId': 'a' * 65}), isNull);
      expect(PeerInfo.fromJson({'installId': ''}), isNull);
      expect(PeerInfo.fromJson(null), isNull);
    });

    test('a negative or odd free space reads as unknown', () {
      expect(
        PeerInfo.fromJson({'installId': 'a', 'freeBytes': -5})!.freeBytes,
        isNull,
      );
      expect(
        PeerInfo.fromJson({'installId': 'a', 'freeBytes': 'lots'})!.freeBytes,
        isNull,
      );
    });
  });
}
