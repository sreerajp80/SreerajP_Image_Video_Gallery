import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/device_identity_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';

import '../media/fake_media_store_channel.dart';

/// Any call means the code under test went somewhere it must not.
class _Untouched
    implements MediaRepository, TagRepository, AlbumRepository, MediaDao {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

/// Keeps the install id in memory, so no plugin is needed.
class _MemoryIdStore implements InstallIdStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

void main() {
  late TransferSessionService session;

  setUp(() {
    final untouched = _Untouched();
    session = TransferSessionService(
      network: NetworkInterfaceService(lister: () async => []),
      crypto: TransferCryptoService(),
      received: ReceivedMediaService(
        mediaStore: FakeMediaStoreChannel(),
        mediaRepository: untouched,
        mediaDao: untouched,
        tagRepository: untouched,
        albumRepository: untouched,
      ),
      fileFor: (_) async => null,
      identity: DeviceIdentityService(store: _MemoryIdStore()),
    );
  });

  tearDown(() => session.dispose());

  /// A code that points off the local network. Joining it fails before any
  /// socket opens, which gives a session that has ended, with no network.
  const offNetwork = PairingPayload(
    protocolVersion: AppConstants.syncProtocolVersion,
    host: '8.8.8.8',
    port: 40000,
    sessionKey: 'x',
    deviceName: 'Gallery',
    hostRole: SyncRole.send,
  );

  test('reset clears an ended session back to idle', () async {
    await session.join(pairing: offNetwork, deviceName: 'Gallery');
    expect(session.state.phase, SyncPhase.failed);
    expect(session.state.failure, TransferFailure.remoteAddressRefused);

    await session.reset();

    expect(session.state.phase, SyncPhase.idle);
    expect(session.state.failure, isNull);
    expect(session.state.pairing, isNull);
    expect(session.state.batchCount, 0);
    expect(session.state.totals.receivedCount, 0);
  });

  test('reset tells listeners, so the screen redraws', () async {
    await session.join(pairing: offNetwork, deviceName: 'Gallery');
    final next = session.states.first;
    await session.reset();
    expect((await next).phase, SyncPhase.idle);
  });

  test('a new session after reset reports again', () async {
    await session.reset();
    await session.join(pairing: offNetwork, deviceName: 'Gallery');
    expect(session.state.phase, SyncPhase.failed);
  });
}
